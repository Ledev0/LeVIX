-- LeVIX C++ module tests (headless, dependency-free)
-- Run: nvim --headless -u tests/minimal_init.lua -l tests/cpp/test_cpp.lua
-- Uses temporary directories only; never touches real user projects.

local project = require("core.levix.cpp.project")
local build = require("core.levix.cpp.build")
local clangd = require("core.levix.cpp.clangd")
local cpp = require("core.levix.cpp")

-- silence notifies unless explicitly debugging
local real_notify = vim.notify
vim.notify = function() end

local T = { passed = 0, failed = 0, skipped = 0, failures = {} }
local temp_dirs = {}

local function test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		T.passed = T.passed + 1
		print("ok   " .. name)
	else
		T.failed = T.failed + 1
		T.failures[#T.failures + 1] = name .. ": " .. tostring(err)
		print("FAIL " .. name .. "\n     " .. tostring(err))
	end
end

local function skip(name, reason)
	T.skipped = T.skipped + 1
	print("skip " .. name .. " (" .. reason .. ")")
end

local function eq(actual, expected, msg)
	if actual ~= expected then
		error(
			string.format("%sexpected %s, got %s", msg and (msg .. ": ") or "", vim.inspect(expected), vim.inspect(actual)),
			2
		)
	end
end

local function truthy(value, msg)
	if not value then
		error(msg or "expected truthy value", 2)
	end
end

local function tmpdir(name)
	local dir = vim.fn.tempname() .. "-" .. name
	vim.fn.mkdir(dir, "p")
	dir = vim.fs.normalize(dir)
	temp_dirs[#temp_dirs + 1] = dir
	return dir
end

local function writefile(path, lines)
	vim.fn.mkdir(vim.fs.dirname(path), "p")
	vim.fn.writefile(lines, path)
end

local function make_executable(path)
	vim.fn.mkdir(vim.fs.dirname(path), "p")
	vim.fn.writefile({ "" }, path)
	vim.fn.setfperm(path, "rwxr-xr-x")
end

--- Close output floats only; the main window must survive.
local function cleanup_windows()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
		if ok and cfg.relative ~= "" then
			pcall(vim.api.nvim_win_close, win, true)
		end
	end
end

--- Wait for an async build to settle, never silently passing a timeout.
local function wait_for(predicate, timeout, label)
	local ok = vim.wait(timeout, predicate, 50)
	truthy(ok, (label or "async operation") .. " timed out")
end

-- ── detection ──────────────────────────────────────────────────────────────

test("detects single-file project", function()
	local dir = tmpdir("single")
	local src = dir .. "/main.cpp"
	writefile(src, { "int main() { return 0; }" })
	local p = project.detect({ path = src })
	truthy(p, "detection returned nil")
	eq(p.kind, "single")
	eq(p.root, dir)
	eq(p.source, src)
end)

test("detects CMake project root from nested source", function()
	local dir = tmpdir("cmake")
	writefile(dir .. "/CMakeLists.txt", { "project(demo CXX)", "add_executable(app src/main.cpp)" })
	local src = dir .. "/src/main.cpp"
	writefile(src, { "int main() { return 0; }" })
	local p = project.detect({ path = src })
	truthy(p, "detection returned nil")
	eq(p.kind, "cmake")
	eq(p.root, dir)
	eq(p.build_dir, dir .. "/build")
end)

test("detects CMake project when source sits next to CMakeLists.txt", function()
	local dir = tmpdir("cmake-flat")
	writefile(dir .. "/CMakeLists.txt", { "project(demo CXX)", "add_executable(app main.cpp)" })
	local src = dir .. "/main.cpp"
	writefile(src, { "int main() { return 0; }" })
	local p = project.detect({ path = src })
	eq(p.kind, "cmake")
	eq(p.root, dir)
end)

test("prefers nearest CMakeLists when nested projects exist", function()
	local outer = tmpdir("cmake-outer")
	writefile(outer .. "/CMakeLists.txt", { "project(outer CXX)" })
	local inner = outer .. "/inner"
	vim.fn.mkdir(inner, "p")
	writefile(inner .. "/CMakeLists.txt", { "project(inner CXX)" })
	local src = inner .. "/app.cpp"
	writefile(src, { "int main() { return 0; }" })
	eq(project.detect({ path = src }).root, inner)
end)

test("rejects non-C++ buffers", function()
	local dir = tmpdir("other")
	local src = dir .. "/notes.txt"
	writefile(src, { "hi" })
	eq(project.detect({ path = src }), nil)
end)

test("rejects headers as buildable sources", function()
	local dir = tmpdir("headers")
	for _, name in ipairs({ "a.h", "b.hpp" }) do
		local src = dir .. "/" .. name
		writefile(src, { "#pragma once" })
		eq(project.detect({ path = src }), nil, name .. " must not be buildable")
	end
end)

test("extension matching is case-insensitive", function()
	local dir = tmpdir("case")
	local src = dir .. "/MAIN.CPP"
	writefile(src, { "int main() { return 0; }" })
	eq(project.detect({ path = src }).kind, "single")
end)

-- ── paths with spaces ──────────────────────────────────────────────────────

test("handles paths containing spaces", function()
	local dir = tmpdir("spaces")
	local spaced = dir .. "/my proj"
	vim.fn.mkdir(spaced, "p")
	local src = spaced .. "/my file.cpp"
	writefile(src, { "int main() { return 0; }" })

	local p = project.detect({ path = src })
	eq(p.kind, "single")
	eq(p.root, spaced)

	local output = spaced .. "/out dir/bin name"
	local cmd = build.single_file_cmd({ compiler = "/usr/bin/g++", source = src, output = output })
	eq(cmd[6], src, "source must be one argv element")
	eq(cmd[7], "-o")
	eq(cmd[8], output, "output must be one argv element")
end)

-- ── command construction ───────────────────────────────────────────────────

test("single-file C++ compiler flags", function()
	local cmd = build.single_file_cmd({ compiler = "g++", source = "/x/a.cpp", output = "/cache/a" })
	eq(cmd[1], "g++")
	for _, flag in ipairs({ "-g", "-Wall", "-Wextra", "-std=c++20" }) do
		truthy(vim.tbl_contains(cmd, flag), "missing flag " .. flag)
	end
	eq(cmd[#cmd - 1], "-o")
	eq(cmd[#cmd], "/cache/a")
end)

test("C sources use C driver and C standard", function()
	local cmd = build.single_file_cmd({ compiler = "gcc", source = "/x/a.c", output = "/cache/a", ext = "c" })
	truthy(vim.tbl_contains(cmd, "-std=c17"), "missing -std=c17")
	eq(vim.tbl_contains(cmd, "-std=c++20"), false, "C source must not get -std=c++20")
end)

test("cache dir lives outside the source tree", function()
	local dir = tmpdir("cache")
	local src = dir .. "/main.cpp"
	writefile(src, { "int main() { return 0; }" })
	local cache = build.cache_dir(src)
	local std_cache = vim.fs.normalize(vim.fn.stdpath("cache"))
	eq(vim.fs.normalize(cache):sub(1, #std_cache), std_cache)
	truthy(cache:sub(1, #dir) ~= dir, "cache must not be inside the project dir")
	vim.fn.delete(cache, "rf")
end)

-- ── missing compiler / spawn failures ──────────────────────────────────────

test("missing compiler resolves to nil", function()
	eq(build.find_compiler({ "definitely-not-a-real-compiler-xyz" }), nil)
	eq(build.find_compiler_for("c") ~= nil, vim.fn.executable("gcc") == 1 or vim.fn.executable("clang") == 1)
end)

test("run_cmd reports a missing executable instead of raising", function()
	local code = "unset"
	build.run_cmd({ "/definitely/not/a/real/binary-xyz" }, {}, function(c)
		code = c
	end)
	wait_for(function()
		return code ~= "unset"
	end, 5000, "missing executable callback")
	eq(code, -1)
end)

test("run_cmd reports an invalid cwd instead of raising", function()
	local code = "unset"
	build.run_cmd({ "true" }, { cwd = "/definitely/not/a/dir-xyz" }, function(c)
		code = c
	end)
	wait_for(function()
		return code ~= "unset"
	end, 5000, "invalid cwd callback")
	eq(code, -1)
end)

-- ── failed build + stale binary prevention ─────────────────────────────────

test("failed build cannot run a stale binary", function()
	if not build.find_compiler() then
		skip("failed build cannot run a stale binary", "no C++ compiler installed")
		return
	end
	local dir = tmpdir("bad")
	local src = dir .. "/broken.cpp"
	writefile(src, { "int main( { this is not valid c++" })

	-- simulate a previous successful build
	build.last = { ok = true, binary = dir .. "/old_binary", linked = true, started = 0 }

	local done = false
	build.build_single(src, function()
		done = true
	end)
	wait_for(function()
		return done
	end, 30000, "failed build")
	cleanup_windows()

	eq(build.last.ok, false)
	eq(build.last.binary, nil, "must not expose a binary after a failed build")
end)

test("failed build never reaches the run path", function()
	if not build.find_compiler() then
		skip("failed build never reaches the run path", "no C++ compiler installed")
		return
	end
	local dir = tmpdir("nostale")
	local src = dir .. "/broken.cpp"
	writefile(src, { "int main( { this is not valid c++" })

	local runner = require("core.levix.runner")
	local real_exec = runner.exec_cmd
	local executed = false
	runner.exec_cmd = function()
		executed = true
	end

	cleanup_windows()
	vim.cmd("edit " .. vim.fn.fnameescape(src))
	local before = build.last
	cpp.run()
	local settled = vim.wait(30000, function()
		return not build.building and build.last ~= nil and build.last ~= before
	end, 50)
	runner.exec_cmd = real_exec
	cleanup_windows()

	truthy(settled, "run path did not settle")
	eq(executed, false, "runner must not execute after a failed build")
	eq(build.last.ok, false)
end)

test("run executes the binary produced by this build", function()
	if not build.find_compiler() then
		skip("run executes the binary produced by this build", "no C++ compiler installed")
		return
	end
	local dir = tmpdir("run-ok")
	local src = dir .. "/ok.cpp"
	writefile(src, { "int main() { return 0; }" })

	local runner = require("core.levix.runner")
	local real_exec = runner.exec_cmd
	local got
	runner.exec_cmd = function(cmd)
		got = cmd
	end

	cleanup_windows()
	vim.cmd("edit " .. vim.fn.fnameescape(src))
	cpp.run()
	local settled = vim.wait(60000, function()
		return got ~= nil or (not build.building and build.last ~= nil and not build.last.ok)
	end, 50)
	runner.exec_cmd = real_exec
	cleanup_windows()

	truthy(settled, "build+run did not settle")
	truthy(got, "runner.exec_cmd was not called")
	eq(got, vim.fn.shellescape(build.last.binary))
end)

test("staleness check flags an artifact older than a linking build", function()
	local dir = tmpdir("stale")
	local bin = dir .. "/app"
	make_executable(bin)
	local stat = vim.uv.fs_stat(bin)
	local mtime = stat.mtime.sec + (stat.mtime.nsec or 0) / 1e9
	local newer = mtime + 60
	eq(build.is_stale(bin, { ok = true, linked = true, started = newer }), true)
	eq(build.is_stale(bin, { ok = true, linked = false, started = newer }), false, "no-op rebuild is not stale")
	eq(build.is_stale(bin, { ok = false, linked = true, started = newer }), false)
	eq(build.is_stale(nil, { ok = true, linked = true, started = newer }), false)
end)

test("link steps are detected in build output", function()
	truthy(build.output_linked({ "[2/2] Linking CXX executable app" }))
	eq(build.output_linked({ "[1/1] Building CXX object main.cpp.o" }), false)
end)

-- ── diagnostics / quickfix ─────────────────────────────────────────────────

test("diagnostics parse into quickfix items", function()
	local items = build.parse_diagnostics({
		"/p/src/a.cpp:3:5: error: boom",
		"/p/src/a.cpp:7: warning: meh",
		"/p/src/a.cpp:3:5: note: hint",
		"not a diagnostic",
	})
	eq(#items, 3)
	eq(items[1].filename, "/p/src/a.cpp")
	eq(items[1].lnum, 3)
	eq(items[1].col, 5)
	eq(items[1].type, "E")
	eq(items[2].type, "W")
	eq(items[3].type, "N")
end)

test("diagnostics resolve relative filenames against the build cwd", function()
	local dir = tmpdir("diag")
	writefile(dir .. "/main.cpp", { "int main(){}" })
	local items = build.parse_diagnostics({ "main.cpp:1:1: error: nope" }, dir)
	eq(items[1].filename, dir .. "/main.cpp")
end)

test("set_quickfix clears previous errors on success", function()
	build.set_quickfix({ { filename = "a.cpp", lnum = 1, col = 1, text = "x", type = "E" } })
	eq(#vim.fn.getqflist(), 1)
	build.set_quickfix({})
	eq(#vim.fn.getqflist(), 0)
end)

-- ── ambiguous CMake executables / discovery ────────────────────────────────

test("multiple executables are reported, never guessed", function()
	local dir = tmpdir("cmake-build")
	make_executable(dir .. "/tool_a")
	make_executable(dir .. "/tool_b")
	writefile(dir .. "/CMakeCache.txt", { "# cache" })

	eq(#build.find_executables(dir), 2, "both executables must be reported for selection")
end)

test("single executable resolves cleanly", function()
	local dir = tmpdir("cmake-one")
	make_executable(dir .. "/app")
	eq(#build.find_executables(dir), 1)
end)

test("executable discovery ignores libraries and fetched deps", function()
	local dir = tmpdir("exe-filter")
	make_executable(dir .. "/app")
	make_executable(dir .. "/libfoo.so.1")
	make_executable(dir .. "/_deps/googletest-build/test")
	writefile(dir .. "/libbar.a", { "" })
	writefile(dir .. "/main.o", { "" })
	local exes = build.find_executables(dir)
	eq(#exes, 1, "only the real target should be reported")
	eq(exes[1].name, "app")
end)

-- ── safe clean ─────────────────────────────────────────────────────────────

test("clean only targets <root>/build", function()
	local root = tmpdir("clean")
	writefile(root .. "/CMakeLists.txt", { "project(x CXX)" })
	truthy(build.validate_clean_dir(root, root .. "/build"))
	eq(build.validate_clean_dir(root, root .. "/buildx"), false)
	eq(build.validate_clean_dir(root, root), false)
	eq(build.validate_clean_dir(root, "/"), false)
	eq(build.validate_clean_dir(nil, root .. "/build"), false)

	truthy(build.validate_clean_root(root))
	local ok_root = build.validate_clean_root("/")
	eq(ok_root, false)
	eq(build.validate_clean_root(vim.fn.expand("~")), false)
	eq(build.validate_clean_root(root:gsub("/[^/]+$", "")), false, "parent without CMakeLists must be refused")
end)

test("cmake clean removes only <root>/build", function()
	local root = tmpdir("clean-root")
	writefile(root .. "/CMakeLists.txt", { "project(x CXX)" })
	writefile(root .. "/build/junk.txt", { "x" })
	writefile(root .. "/keep.txt", { "keep" })

	local done, ok = false, "unset"
	build.cmake_clean(root, function(result)
		ok = result
		done = true
	end, { force = true })
	wait_for(function()
		return done
	end, 5000, "cmake clean")

	eq(ok, true)
	eq(vim.fn.isdirectory(root .. "/build"), 0, "build dir must be removed")
	eq(vim.fn.filereadable(root .. "/keep.txt"), 1, "sibling files must survive")
end)

test("cmake clean refuses roots without CMakeLists.txt", function()
	local root = tmpdir("clean-bogus")
	writefile(root .. "/build/junk.txt", { "x" })

	local done, ok = false, "unset"
	build.cmake_clean(root, function(result)
		ok = result
		done = true
	end, { force = true })
	wait_for(function()
		return done
	end, 5000, "refused clean")

	eq(ok, false)
	eq(vim.fn.isdirectory(root .. "/build"), 1, "build dir must be preserved")
end)

test("clean_single removes only the cache dir", function()
	local dir = tmpdir("clean-single")
	local src = dir .. "/main.cpp"
	writefile(src, { "int main(){}" })
	local cache = build.cache_dir(src)
	writefile(cache .. "/binary", { "x" })

	local done, ok = false, "unset"
	build.clean_single(src, function(result)
		ok = result
		done = true
	end)
	wait_for(function()
		return done
	end, 5000, "clean_single")

	eq(ok, true)
	eq(vim.fn.isdirectory(cache), 0)
	eq(vim.fn.filereadable(src), 1, "source must survive")
end)

-- ── clangd ─────────────────────────────────────────────────────────────────

test("clangd cmd carries background-index and query-driver", function()
	if clangd.resolve_executable() == nil then
		skip("clangd cmd carries background-index and query-driver", "clangd not installed")
		return
	end
	local cmd = clangd.build_cmd(nil)
	truthy(cmd, "build_cmd returned nil with clangd present")
	truthy(vim.tbl_contains(cmd, "--background-index"))
	local has_driver = false
	for _, arg in ipairs(cmd) do
		if arg:match("^%-%-query%-driver=") then
			has_driver = true
		end
	end
	truthy(has_driver, "missing --query-driver")
end)

test("clangd uses the compile DB in the project build dir", function()
	local root = tmpdir("clangd-db")
	writefile(root .. "/build/compile_commands.json", { "[]" })
	eq(clangd.compile_commands_dir(root), vim.fs.normalize(root .. "/build"))
	eq(clangd.compile_commands_dir(nil), nil)
	eq(clangd.compile_commands_dir(root .. "/nope"), nil)
end)

-- ── CMake integration ──────────────────────────────────────────────────────

test("cmake configure + build + executable discovery", function()
	if vim.fn.executable("cmake") == 0 then
		skip("cmake configure + build + executable discovery", "cmake not installed")
		return
	end
	if not build.find_compiler() then
		skip("cmake configure + build + executable discovery", "no C++ compiler installed")
		return
	end
	local dir = tmpdir("cmake-it")
	writefile(dir .. "/CMakeLists.txt", {
		"cmake_minimum_required(VERSION 3.16)",
		"project(levix_test CXX)",
		"add_executable(hello main.cpp)",
	})
	writefile(dir .. "/main.cpp", { "int main() { return 0; }" })

	local done, ok = false, "unset"
	build.cmake_build(dir, function(result)
		ok = result
		done = true
	end)
	wait_for(function()
		return done
	end, 120000, "cmake build")
	cleanup_windows()

	eq(ok, true, "cmake build should succeed")
	eq(build.last.ok, true)
	eq(build.building, false, "build guard must be released")

	local exes = build.find_executables(dir .. "/build")
	eq(#exes, 1, "exactly one executable expected")
	eq(exes[1].name, "hello")
	truthy(vim.fn.filereadable(dir .. "/build/compile_commands.json") == 1, "compile_commands.json missing")
	eq(build.is_stale(exes[1].path, build.last), false, "freshly built binary must not be stale")
end)

-- ── summary ────────────────────────────────────────────────────────────────

cleanup_windows()
for _, dir in ipairs(temp_dirs) do
	vim.fn.delete(dir, "rf")
end

print("")
print(string.format("LeVIX C++ tests: %d passed, %d failed, %d skipped", T.passed, T.failed, T.skipped))
for _, f in ipairs(T.failures) do
	print("  - " .. f)
end
vim.notify = real_notify
os.exit(T.failed == 0 and 0 or 1)
