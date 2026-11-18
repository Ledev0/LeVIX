-- LeVIX C++ — project detection
-- Pure-ish helpers: given a path, classify as cmake or single-file project.
-- All paths are kept as plain strings and passed to commands as argv
-- elements, so spaces are safe.

local M = {}

-- Buildable translation units only: headers cannot be compiled into a program.
local SOURCE_EXTS = { c = true, cpp = true, cxx = true, cc = true }

--- Extension of `path`, lowercased (`.CPP` must classify like `.cpp`).
---@param path string
---@return string
function M.extension(path)
	return vim.fn.fnamemodify(path, ":e"):lower()
end

--- Current buffer path, or nil when the buffer is unnamed/unreadable.
---@return string|nil
function M.current_source()
	local name = vim.api.nvim_buf_get_name(0)
	if name == "" then
		return nil
	end
	if vim.fn.filereadable(name) == 0 then
		return nil
	end
	return vim.fs.normalize(name)
end

--- Find the CMake project root by walking upward from `start_dir`.
---@param start_dir string
---@return string|nil root directory containing CMakeLists.txt
function M.find_cmake_root(start_dir)
	if not start_dir or start_dir == "" then
		return nil
	end
	local root = vim.fs.normalize(start_dir)
	while root and root ~= "" do
		if vim.fn.filereadable(root .. "/CMakeLists.txt") == 1 then
			return root
		end
		local parent = vim.fs.dirname(root)
		if parent == root then
			return nil
		end
		root = parent
	end
	return nil
end

--- Build dir used for CMake projects (project-root/build).
---@param root string
---@return string
function M.cmake_build_dir(root)
	return root .. "/build"
end

--- Detect the project for the current buffer.
--- Returns nil when the buffer is not a buildable C/C++ source file.
---@param opts? table { path?: string } override source path (tests)
---@return table|nil { kind = "cmake"|"single", root, source, build_dir, ext }
function M.detect(opts)
	opts = opts or {}
	local source = opts.path or M.current_source()
	if not source then
		return nil
	end

	local ext = M.extension(source)
	if not SOURCE_EXTS[ext] then
		return nil
	end

	local dir = vim.fs.dirname(source)
	local cmake_root = M.find_cmake_root(dir)
	if cmake_root then
		return {
			kind = "cmake",
			root = cmake_root,
			source = source,
			build_dir = M.cmake_build_dir(cmake_root),
			ext = ext,
		}
	end

	return {
		kind = "single",
		root = dir,
		source = source,
		build_dir = nil,
		ext = ext,
	}
end

return M
