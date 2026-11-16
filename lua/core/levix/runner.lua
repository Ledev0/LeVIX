-- LeVIX Code Runner (F5)
-- Runs the current file in a dedicated toggleterm terminal (count 9, reused).
-- Supports: java (single-file launcher, JDK 11+), c, cpp, python, bash.

local M = {}

local interpreters = {
	python = "python3",
	bash = "bash",
}

-- One-shot compile + run for C/C++; binary goes to a temp path, cached by the OS.
local function compiled_cmd(compiler, file)
	local bin = vim.fn.tempname()
	return string.format("%s -Wall %s -o %s && %s", compiler, file, vim.fn.shellescape(bin), vim.fn.shellescape(bin))
end

function M.run()
	local ft = vim.bo.filetype
	local path = vim.api.nvim_buf_get_name(0)

	if path == "" then
		vim.notify("LeVIX: buffer has no file to run", vim.log.levels.WARN, { title = "LeVIX Runner" })
		return
	end
	local file = vim.fn.shellescape(path)

	local cmd
	if interpreters[ft] then
		cmd = interpreters[ft] .. " " .. file
	elseif ft == "java" then
		-- Single-file source launcher (JDK 11+)
		cmd = "java " .. file
	elseif ft == "c" then
		cmd = compiled_cmd("gcc", file)
	elseif ft == "cpp" then
		cmd = compiled_cmd("g++", file)
	else
		vim.notify(
			string.format("LeVIX: no runner configured for filetype '%s'", ft),
			vim.log.levels.WARN,
			{ title = "LeVIX Runner" }
		)
		return
	end

	-- Dedicated terminal count 9: output persists between runs.
	require("toggleterm").exec(cmd, 9, 15, vim.fn.getcwd(), "horizontal")
end

-- F6: debug the current file (delegates to nvim-dap; adapter per filetype).
function M.debug()
	require("dap").continue()
end

return M
