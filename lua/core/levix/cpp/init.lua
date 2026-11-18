-- LeVIX C++ — module entry point
-- Registers :LeVIXCpp* commands and buffer-local keymaps for C/C++ buffers.
-- Keymaps: <leader>bc configure, bb build, br run, bd debug, bx clean.

local M = {}

local function notify(msg, level, title)
	vim.notify("LeVIX: " .. msg, level or vim.log.levels.INFO, { title = title or "LeVIX C++" })
end

--- Detect the project for the current buffer, notifying the user on failure.
---@return table|nil
local function project_or_warn()
	if vim.api.nvim_buf_get_name(0) == "" then
		notify("save the buffer first — C++ commands need a file on disk", vim.log.levels.WARN)
		return nil
	end
	local project = require("core.levix.cpp.project").detect()
	if not project then
		notify("not a buildable C/C++ source file (.c/.cpp/.cxx/.cc)", vim.log.levels.WARN)
	end
	return project
end

--- Path relative to the build dir, for picker labels.
---@param path string
---@param build_dir string
---@return string
local function relative_label(path, build_dir)
	local prefix = vim.fs.normalize(build_dir) .. "/"
	if path:sub(1, #prefix) == prefix then
		return path:sub(#prefix + 1)
	end
	return vim.fn.fnamemodify(path, ":t")
end

--- Ask the user to pick an executable when a CMake build produced several.
--- Refuses artifacts that this build did not actually produce (stale guard).
---@param project table
---@param on_pick fun(exe: table)
local function resolve_exe(project, on_pick)
	local build = require("core.levix.cpp.build")
	local exes = build.find_executables(project.build_dir)

	if #exes == 0 then
		notify("build succeeded but no executable found in " .. project.build_dir, vim.log.levels.ERROR)
		return
	end

	local function pick(exe)
		if build.is_stale(exe.path, build.last) then
			-- Common for up-to-date sibling targets in incremental multi-target
			-- builds, so warn instead of blocking the run.
			notify(
				"'" .. exe.name .. "' was not relinked by this build (up-to-date or leftover artifact)",
				vim.log.levels.WARN
			)
		end
		on_pick(exe)
	end

	if #exes == 1 then
		pick(exes[1])
		return
	end

	vim.ui.select(exes, {
		prompt = "LeVIX: multiple executables — pick one",
		format_item = function(exe)
			return relative_label(exe.path, project.build_dir)
		end,
	}, function(choice)
		if choice then
			pick(choice)
		end
	end)
end

--- Run an executable in the shared LeVIX run float.
---@param exe table { name, path }
---@param cwd string
local function run_exe(exe, cwd)
	require("core.levix.runner").exec_cmd(vim.fn.shellescape(exe.path), cwd)
end

--- Build the current project and hand the executable to `on_exe`.
---@param project table
---@param on_exe fun(exe: table)
local function build_then(project, on_exe)
	local build = require("core.levix.cpp.build")

	if project.kind == "cmake" then
		build.cmake_build(project.root, function(ok)
			if not ok then
				return
			end
			resolve_exe(project, on_exe)
		end, { silent_success = true })
	else
		build.build_single(project.source, function(binary)
			if binary then
				on_exe({ name = vim.fn.fnamemodify(binary, ":t"), path = binary })
			end
		end, { silent_success = true })
	end
end

-- ── commands ────────────────────────────────────────────────────────────────

function M.configure()
	local project = project_or_warn()
	if not project then
		return
	end
	if project.kind ~= "cmake" then
		notify("no CMakeLists.txt found — configure applies to CMake projects only", vim.log.levels.WARN)
		return
	end
	require("core.levix.cpp.build").cmake_configure(project.root)
end

function M.build()
	local project = project_or_warn()
	if not project then
		return
	end
	local build = require("core.levix.cpp.build")
	if project.kind == "cmake" then
		build.cmake_build(project.root)
	else
		build.build_single(project.source)
	end
end

function M.run()
	local project = project_or_warn()
	if not project then
		return
	end
	build_then(project, function(exe)
		run_exe(exe, project.root)
	end)
end

function M.debug()
	local project = project_or_warn()
	if not project then
		return
	end
	build_then(project, function(exe)
		require("core.levix.cpp.debug").launch(exe.path, project.root)
	end)
end

function M.clean()
	local project = project_or_warn()
	if not project then
		return
	end
	local build = require("core.levix.cpp.build")
	if project.kind == "cmake" then
		build.cmake_clean(project.root)
	else
		build.clean_single(project.source)
	end
end

-- ── setup ───────────────────────────────────────────────────────────────────

function M.setup()
	vim.api.nvim_create_user_command("LeVIXCppConfigure", M.configure, { desc = "C++: Configure CMake project" })
	vim.api.nvim_create_user_command("LeVIXCppBuild", M.build, { desc = "C++: Build current project" })
	vim.api.nvim_create_user_command("LeVIXCppRun", M.run, { desc = "C++: Build and run" })
	vim.api.nvim_create_user_command("LeVIXCppDebug", M.debug, { desc = "C++: Build and debug the produced binary" })
	vim.api.nvim_create_user_command("LeVIXCppClean", M.clean, { desc = "C++: Clean build artifacts" })

	local group = vim.api.nvim_create_augroup("LeVIXCpp", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = { "c", "cpp" },
		callback = function(args)
			local function map(lhs, rhs, desc)
				vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
			end
			map("<leader>bc", "<cmd>LeVIXCppConfigure<CR>", "C++: Configure")
			map("<leader>bb", "<cmd>LeVIXCppBuild<CR>", "C++: Build")
			map("<leader>br", "<cmd>LeVIXCppRun<CR>", "C++: Build & Run")
			map("<leader>bd", "<cmd>LeVIXCppDebug<CR>", "C++: Build & Debug")
			map("<leader>bx", "<cmd>LeVIXCppClean<CR>", "C++: Clean")
		end,
	})
end

return M
