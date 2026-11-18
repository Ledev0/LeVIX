-- LeVIX C++ — build engine
-- Async job execution (argv tables only, never shell strings), single-file
-- builds via an external cache dir, CMake configure/build/clean, quickfix
-- population, executable discovery and stale-artifact protection.
--
-- M.last tracks the most recent build:
--   { ok, binary?, started?, linked?, project }
-- Run/debug are gated by the build callback result; the freshness metadata is
-- used by build.is_stale() so a binary this build did not produce is refused.

local M = {}

M.last = nil
M.building = false

local COMPILER_CANDIDATES = {
	cpp = { "g++", "clang++", "c++" },
	c = { "gcc", "clang", "cc" },
}

local STD_FLAGS = { cpp = "-std=c++20", c = "-std=c17" }

local SKIP_DIRS = {
	CMakeFiles = true,
	_deps = true,
	Testing = true,
	[".git"] = true,
}

local function uv()
	return vim.uv or vim.loop
end

local function notify(msg, level, title)
	vim.notify("LeVIX: " .. msg, level or vim.log.levels.INFO, { title = title or "LeVIX C++" })
end

--- Wall-clock seconds with sub-second precision (build freshness comparisons).
---@return number
local function walltime()
	local u = uv()
	if u.gettimeofday then
		local sec, usec = u.gettimeofday()
		return sec + usec / 1e6
	end
	return os.time()
end

--- Resolve the first available compiler from candidates (PATH lookup).
---@param candidates? string[]
---@return string|nil absolute executable path
function M.find_compiler(candidates)
	for _, exe in ipairs(candidates or COMPILER_CANDIDATES.cpp) do
		local path = vim.fn.exepath(exe)
		if path ~= "" then
			return path
		end
	end
	return nil
end

--- Compiler for a source extension: C sources get a C driver, not g++.
---@param ext string|nil
---@return string|nil
function M.find_compiler_for(ext)
	local lang = (ext or ""):lower() == "c" and "c" or "cpp"
	return M.find_compiler(COMPILER_CANDIDATES[lang])
end

--- External cache dir for single-file builds (never next to the source).
---@param source string
---@return string
function M.cache_dir(source)
	local hash = vim.fn.sha256(source):sub(1, 16)
	local base = vim.fn.stdpath("cache") .. "/levix/cpp/" .. hash
	vim.fn.mkdir(base, "p")
	return base
end

--- Argv for compiling one source file with debug symbols.
---@param opts table { compiler: string, source: string, output: string, ext?: string }
---@return string[]
function M.single_file_cmd(opts)
	local lang = (opts.ext or "cpp"):lower() == "c" and "c" or "cpp"
	return {
		opts.compiler,
		"-g",
		"-Wall",
		"-Wextra",
		STD_FLAGS[lang],
		opts.source,
		"-o",
		opts.output,
	}
end

--- Severity bucket for a compiler diagnostic label.
---@param sev string
---@return string
local function severity_type(sev)
	if sev:match("^error") or sev == "fatal error" then
		return "E"
	end
	if sev == "note" then
		return "N"
	end
	if sev == "info" then
		return "I"
	end
	return "W"
end

--- Resolve a diagnostic filename. Relative paths are tried against `cwd`
--- (the compiler's working directory) before falling back to the raw value.
---@param file string
---@param cwd? string
---@return string
function M.resolve_filename(file, cwd)
	if vim.fn.filereadable(file) == 1 then
		return vim.fs.normalize(file)
	end
	if cwd and cwd ~= "" and file:sub(1, 1) ~= "/" then
		local candidate = vim.fs.normalize(cwd .. "/" .. file)
		if vim.fn.filereadable(candidate) == 1 then
			return candidate
		end
	end
	return file
end

--- Parse compiler diagnostics into quickfix items.
--- Handles "file:line:col: severity: msg" and "file:line: severity: msg".
---@param lines string[]
---@param cwd? string directory the compiler ran in (relative path resolution)
---@return table[] quickfix items
function M.parse_diagnostics(lines, cwd)
	local items = {}
	local seen = {}
	for _, line in ipairs(lines or {}) do
		local file, lnum, col, sev, msg = line:match("^(.-):(%d+):(%d+): (%a+[%w ]-): (.*)$")
		if not file then
			file, lnum, sev, msg = line:match("^(.-):(%d+): (%a+[%w ]-): (.*)$")
		end
		if file and msg and sev then
			file = M.resolve_filename(file, cwd)
			local key = table.concat({ file, lnum, col or "", sev, msg }, "|")
			if not seen[key] then
				seen[key] = true
				items[#items + 1] = {
					filename = file,
					lnum = tonumber(lnum),
					col = tonumber(col) or 1,
					text = msg,
					type = severity_type(sev),
				}
			end
		end
	end
	return items
end

--- Replace the quickfix list. Always runs, so a fixed build clears old errors.
---@param items table[]|nil
---@return integer count
function M.set_quickfix(items)
	vim.fn.setqflist({}, " ", { title = "LeVIX C++ Build", items = items or {} })
	return #(items or {})
end

--- Run a command asynchronously, capturing stdout/stderr separately.
---@param cmd string[] argv — never a shell string
---@param opts? table { cwd?: string }
---@param on_done fun(code: integer, stdout: string[], stderr: string[])
---@return integer job id (-1 on failure)
function M.run_cmd(cmd, opts, on_done)
	opts = opts or {}
	local stdout, stderr = {}, {}

	local function append(tbl)
		return function(_, data)
			for _, l in ipairs(data or {}) do
				if l ~= "" then
					tbl[#tbl + 1] = l
				end
			end
		end
	end

	-- nvim 0.12 raises E475 for a missing executable or an invalid cwd
	-- instead of returning <= 0, so the spawn must be pcall-guarded.
	local ok, job = pcall(vim.fn.jobstart, cmd, {
		cwd = opts.cwd,
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = append(stdout),
		on_stderr = append(stderr),
		on_exit = function(_, code)
			vim.schedule(function()
				on_done(code, stdout, stderr)
			end)
		end,
	})
	if not ok or type(job) ~= "number" or job <= 0 then
		vim.schedule(function()
			on_done(-1, stdout, stderr)
		end)
		return -1
	end
	return job
end

--- Show captured output in a floating scratch window (existing float UI style).
---@param title string
---@param lines string[]
---@return integer win
function M.show_output(title, lines)
	if not lines or #lines == 0 then
		lines = { "(no output)" }
	end
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	local width = math.min(120, math.max(60, vim.o.columns - 20))
	local height = math.min(30, math.max(8, #lines))
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		style = "minimal",
		border = "rounded",
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		width = width,
		height = height,
		title = " " .. title .. " ",
	})
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf })
	vim.keymap.set("n", "<Esc>", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf })
	return win
end

--- True when the build output shows a link step (real artifact relink).
---@param lines string[]|nil
---@return boolean
function M.output_linked(lines)
	for _, line in ipairs(lines or {}) do
		if line:find("Linking", 1, true) then
			return true
		end
	end
	return false
end

--- Safety gate for clean operations: only <root>/build is deletable.
---@param root string
---@param dir string
---@return boolean
function M.validate_clean_dir(root, dir)
	if not root or not dir or root == "" or dir == "" then
		return false
	end
	return vim.fs.normalize(dir) == vim.fs.normalize(root .. "/build")
end

--- Reject roots that must never be cleaned (/, $HOME, non-CMake dirs).
---@param root string|nil
---@return boolean ok, string|nil reason
function M.validate_clean_root(root)
	if type(root) ~= "string" or root == "" then
		return false, "empty project root"
	end
	local norm = vim.fs.normalize(root)
	if norm == "/" then
		return false, "project root is /"
	end
	if norm == vim.fs.normalize(vim.fn.expand("~")) then
		return false, "project root is $HOME"
	end
	if vim.fn.filereadable(norm .. "/CMakeLists.txt") == 0 then
		return false, "no CMakeLists.txt in " .. norm
	end
	return true, nil
end

--- Guard against overlapping builds writing the same artifacts.
---@return boolean started
local function begin_build()
	if M.building then
		notify("a build is already running — wait for it to finish", vim.log.levels.WARN)
		return false
	end
	M.building = true
	return true
end

-- ── single-file builds ──────────────────────────────────────────────────────

--- Build one source file. on_done(binary|nil).
---@param source string
---@param on_done? fun(binary: string|nil)
---@param opts? table { silent_success?: boolean } suppress the output float on success
function M.build_single(source, on_done, opts)
	on_done = on_done or function() end
	opts = opts or {}

	if not begin_build() then
		on_done(nil)
		return
	end
	local function finish(binary)
		M.building = false
		on_done(binary)
	end

	local ext = vim.fn.fnamemodify(source, ":e"):lower()
	local compiler = M.find_compiler_for(ext)
	if not compiler then
		M.last = { ok = false }
		notify("no compiler found for ." .. ext .. " (g++/clang++/gcc on PATH)", vim.log.levels.ERROR)
		finish(nil)
		return
	end

	local dir = M.cache_dir(source)
	local output = dir .. "/" .. vim.fn.fnamemodify(source, ":t:r")
	local cwd = vim.fn.fnamemodify(source, ":h")
	local cmd = M.single_file_cmd({ compiler = compiler, source = source, output = output, ext = ext })
	local started = walltime()

	M.run_cmd(cmd, { cwd = cwd }, function(code, out, err)
		local lines = {}
		vim.list_extend(lines, out)
		vim.list_extend(lines, err)
		local items = M.parse_diagnostics(lines, cwd)
		M.set_quickfix(items)

		if code == 0 and vim.fn.filereadable(output) == 1 then
			if not opts.silent_success then
				M.show_output("LeVIX C++ Build", lines)
			end
			M.last = { ok = true, binary = output, started = started, project = { kind = "single", source = source } }
			notify("build ok → " .. output)
			finish(output)
		else
			M.show_output("LeVIX C++ Build", lines)
			M.last = { ok = false }
			notify(
				string.format(
					"build failed (exit %d)%s",
					code,
					#items > 0 and (" — " .. #items .. " diagnostic(s) in quickfix") or ""
				),
				vim.log.levels.ERROR
			)
			finish(nil)
		end
	end)
end

-- ── CMake ───────────────────────────────────────────────────────────────────

--- Configure a CMake project (compile_commands.json, Ninja on fresh caches).
--- Never overrides an existing generator or build type.
---@param root string
---@param on_done? fun(ok: boolean)
---@param opts? table { silent_success?: boolean }
function M.cmake_configure(root, on_done, opts)
	on_done = on_done or function() end
	opts = opts or {}
	local build_dir = root .. "/build"
	local fresh = vim.fn.filereadable(build_dir .. "/CMakeCache.txt") == 0

	local cmd = { "cmake", "-S", root, "-B", build_dir, "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" }
	if fresh and vim.fn.executable("ninja") == 1 then
		vim.list_extend(cmd, { "-G", "Ninja" })
	end
	-- Only pick a build type for fresh caches: never override user config.
	if fresh then
		vim.list_extend(cmd, { "-DCMAKE_BUILD_TYPE=Debug" })
	end

	M.run_cmd(cmd, { cwd = root }, function(code, out, err)
		local lines = {}
		vim.list_extend(lines, out)
		vim.list_extend(lines, err)

		if code == 0 then
			if not opts.silent_success then
				M.show_output("LeVIX C++ Configure", lines)
			end
			notify("cmake configure ok (" .. build_dir .. ")")
			on_done(true)
		else
			M.show_output("LeVIX C++ Configure", lines)
			notify("cmake configure failed (exit " .. code .. ")", vim.log.levels.ERROR)
			on_done(false)
		end
	end)
end

--- Build a CMake project, configuring first when the cache or compile DB is missing.
---@param root string
---@param on_done? fun(ok: boolean)
---@param opts? table { silent_success?: boolean }
function M.cmake_build(root, on_done, opts)
	on_done = on_done or function() end
	opts = opts or {}
	local build_dir = root .. "/build"

	if not begin_build() then
		on_done(false)
		return
	end
	local function finish(ok)
		M.building = false
		on_done(ok)
	end

	local started = walltime()

	local function do_build()
		M.run_cmd({ "cmake", "--build", build_dir, "--parallel" }, { cwd = root }, function(code, out, err)
			local lines = {}
			vim.list_extend(lines, out)
			vim.list_extend(lines, err)
			local items = M.parse_diagnostics(lines, root)
			M.set_quickfix(items)

			if code == 0 then
				if not opts.silent_success then
					M.show_output("LeVIX C++ Build", lines)
				end
				M.last = {
					ok = true,
					started = started,
					linked = M.output_linked(lines),
					project = { kind = "cmake", root = root },
				}
				notify("cmake build ok")
				finish(true)
			else
				M.show_output("LeVIX C++ Build", lines)
				M.last = { ok = false }
				notify(
					string.format(
						"cmake build failed (exit %d)%s",
						code,
						#items > 0 and (" — " .. #items .. " diagnostic(s) in quickfix") or ""
					),
					vim.log.levels.ERROR
				)
				finish(false)
			end
		end)
	end

	local cache = vim.fn.filereadable(build_dir .. "/CMakeCache.txt") == 1
	local compile_db = vim.fn.filereadable(build_dir .. "/compile_commands.json") == 1
	if not cache or not compile_db then
		M.cmake_configure(root, function(ok)
			if ok then
				do_build()
			else
				M.last = { ok = false }
				finish(false)
			end
		end, { silent_success = opts.silent_success })
	else
		do_build()
	end
end

--- Versioned/shared libraries and object files are not runnable targets.
---@param name string
---@return boolean
local function is_library(name)
	return name:match("%.so[%.%d]*$") ~= nil
		or name:match("%.dylib$") ~= nil
		or name:match("%.dll$") ~= nil
		or name:match("%.a$") ~= nil
		or name:match("%.o$") ~= nil
		or name:match("%.cmake$") ~= nil
end

--- Walk the build dir for executable files (depth-limited, skips CMakeFiles,
--- fetched deps and test scaffolding; newest first).
---@param build_dir string
---@return table[] { name, path, mtime }
function M.find_executables(build_dir)
	local acc = {}
	local u = uv()

	local function walk(dir, depth)
		if depth > 3 then
			return
		end
		local fd = u.fs_scandir(dir)
		if not fd then
			return
		end
		while true do
			local name, kind = u.fs_scandir_next(fd)
			if not name then
				break
			end
			local path = dir .. "/" .. name
			if kind == "directory" then
				if not SKIP_DIRS[name] then
					walk(path, depth + 1)
				end
			elseif kind == "file" or kind == "link" then
				if not is_library(name) and vim.fn.executable(path) == 1 then
					local stat = u.fs_stat(path)
					local mtime = stat and stat.mtime and (stat.mtime.sec + (stat.mtime.nsec or 0) / 1e9) or 0
					acc[#acc + 1] = { name = name, path = path, mtime = mtime }
				end
			end
		end
	end

	walk(vim.fs.normalize(build_dir), 1)
	table.sort(acc, function(a, b)
		if a.mtime ~= b.mtime then
			return a.mtime > b.mtime
		end
		return a.path < b.path
	end)
	return acc
end

--- True when `binary` predates the build that supposedly produced it.
--- A no-op rebuild leaves a valid, older artifact, so the check only applies
--- when the build output contained a link step.
---@param binary string|nil
---@param last? table build result (defaults to M.last)
---@return boolean
function M.is_stale(binary, last)
	last = last or M.last
	if not binary or not last or not last.ok or not last.linked or not last.started then
		return false
	end
	local stat = uv().fs_stat(binary)
	if not stat or not stat.mtime then
		return false
	end
	local mtime = stat.mtime.sec + (stat.mtime.nsec or 0) / 1e9
	return mtime < last.started
end

--- Clean a CMake project's build dir (validated + confirmed, never arbitrary).
---@param root string
---@param on_done? fun(ok: boolean)
---@param opts? table { force?: boolean } skip the confirmation prompt (tests/scripts)
function M.cmake_clean(root, on_done, opts)
	on_done = on_done or function() end
	opts = opts or {}
	local build_dir = root .. "/build"

	local safe, reason = M.validate_clean_root(root)
	if not safe then
		notify("refusing to clean: " .. reason, vim.log.levels.ERROR)
		on_done(false)
		return
	end
	if not M.validate_clean_dir(root, build_dir) then
		notify("refusing to clean: " .. build_dir .. " is not <root>/build", vim.log.levels.ERROR)
		on_done(false)
		return
	end
	if vim.fn.isdirectory(build_dir) == 0 then
		notify("nothing to clean (" .. build_dir .. " does not exist)")
		on_done(true)
		return
	end

	if not opts.force then
		if #vim.api.nvim_list_uis() == 0 then
			notify("no UI available to confirm — clean skipped (" .. build_dir .. ")", vim.log.levels.WARN)
			on_done(false)
			return
		end
		local choice = vim.fn.confirm("Delete CMake build directory?\n" .. build_dir, "&Yes\n&No", 2)
		if choice ~= 1 then
			on_done(false)
			return
		end
	end

	local rc = vim.fn.delete(build_dir, "rf")
	if rc ~= 0 then
		notify("failed to clean " .. build_dir .. " (delete returned " .. rc .. ")", vim.log.levels.ERROR)
		on_done(false)
		return
	end
	notify("cleaned " .. build_dir)
	on_done(true)
end

--- Clean the single-file build cache for one source file.
---@param source string
---@param on_done? fun(ok: boolean)
function M.clean_single(source, on_done)
	on_done = on_done or function() end
	local dir = M.cache_dir(source)
	local expected_prefix = vim.fs.normalize(vim.fn.stdpath("cache") .. "/levix/cpp/")
	if vim.fs.normalize(dir):sub(1, #expected_prefix) ~= expected_prefix then
		notify("refusing to clean outside the LeVIX cache", vim.log.levels.ERROR)
		on_done(false)
		return
	end
	local rc = vim.fn.delete(dir, "rf")
	if rc ~= 0 then
		notify("failed to clean " .. dir .. " (delete returned " .. rc .. ")", vim.log.levels.ERROR)
		on_done(false)
		return
	end
	notify("cleaned " .. dir)
	on_done(true)
end

return M
