-- LeVIX C++ — clangd configuration
-- Prefers a system clangd over Mason's copy, wires compile_commands.json and
-- --query-driver from compilers that actually exist on this machine (including
-- the compilers recorded by CMake in the project's build cache).

local M = {}

-- System locations checked before PATH (Mason's bin dir usually sits first).
local SYSTEM_CANDIDATES = { "/usr/bin/clangd", "/usr/local/bin/clangd" }

local DRIVER_CANDIDATES = { "g++", "clang++", "c++", "gcc", "clang", "cc" }

--- Resolve clangd: system first, then whatever PATH provides (possibly Mason).
---@return string|nil
function M.resolve_executable()
	for _, path in ipairs(SYSTEM_CANDIDATES) do
		if vim.fn.executable(path) == 1 then
			return path
		end
	end
	local path = vim.fn.exepath("clangd")
	if path ~= "" then
		return path
	end
	return nil
end

--- Compilers recorded by CMake in `<root>/build/CMakeCache.txt`, if any.
---@param root string|nil
---@return string[]
function M.cache_compilers(root)
	local found = {}
	if not root or root == "" then
		return found
	end
	local cache = vim.fs.normalize(root .. "/build/CMakeCache.txt")
	if vim.fn.filereadable(cache) == 0 then
		return found
	end
	for _, line in ipairs(vim.fn.readfile(cache)) do
		local value = line:match("^CMAKE_CXX_COMPILER:FILEPATH=(.+)$") or line:match("^CMAKE_C_COMPILER:FILEPATH=(.+)$")
		if value and vim.fn.executable(value) == 1 then
			found[#found + 1] = value
		end
	end
	return found
end

--- Collect existing compiler paths for --query-driver (deduplicated).
---@param candidates? string[]
---@param root? string project root, used to read CMAKE_CXX_COMPILER
---@return string[]
function M.query_drivers(candidates, root)
	local seen, found = {}, {}

	local function add(path)
		if path and path ~= "" and not seen[path] and vim.fn.executable(path) == 1 then
			seen[path] = true
			found[#found + 1] = path
		end
	end

	for _, path in ipairs(M.cache_compilers(root)) do
		add(path)
	end
	for _, exe in ipairs(candidates or DRIVER_CANDIDATES) do
		add(vim.fn.exepath(exe))
	end
	return found
end

--- Directory holding compile_commands.json, if any (prefers project build dir).
---@param root string|nil
---@return string|nil
function M.compile_commands_dir(root)
	if not root or root == "" then
		return nil
	end
	local build = vim.fs.normalize(root .. "/build")
	if vim.fn.filereadable(build .. "/compile_commands.json") == 1 then
		return build
	end
	if vim.fn.filereadable(vim.fs.normalize(root .. "/compile_commands.json")) == 1 then
		return vim.fs.normalize(root)
	end
	return nil
end

--- Full clangd argv for a project root.
---@param root string|nil
---@return string[]|nil
function M.build_cmd(root)
	local exe = M.resolve_executable()
	if not exe then
		return nil
	end

	local cmd = { exe, "--background-index" }

	local ccd = M.compile_commands_dir(root)
	if ccd then
		cmd[#cmd + 1] = "--compile-commands-dir=" .. ccd
	end

	local drivers = M.query_drivers(nil, root)
	if #drivers > 0 then
		cmd[#cmd + 1] = "--query-driver=" .. table.concat(drivers, ",")
	end

	return cmd
end

return M
