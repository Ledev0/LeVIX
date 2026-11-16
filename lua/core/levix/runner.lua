-- LeVIX Code Runner (F5 / <leader>dr)
-- Runs the current file in a dedicated floating toggleterm (count 9, reused).
-- When the program exits it shows "Press ENTER to close" and closes on Enter.
-- Supports: java (single-file launcher, JDK 11+), c, cpp, python, bash.

local M = {}

local interpreters = {
	python = "python3",
	bash = "bash",
}

local run_term

-- One-shot compile + run for C/C++; binary goes to a temp path, cached by the OS.
local function compiled_cmd(compiler, file)
	local bin = vim.fn.tempname()
	return string.format("%s -Wall %s -o %s && %s", compiler, file, vim.fn.shellescape(bin), vim.fn.shellescape(bin))
end

-- After the program exits: wait for ENTER, then the shell exits and
-- close_on_exit shuts the float.
local function with_enter_prompt(cmd)
	return string.format('%s; printf "\\n[LeVIX] Press ENTER to close... "; read _', cmd)
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

	local Terminal = require("toggleterm.terminal").Terminal
	local full = with_enter_prompt(cmd)

	if run_term then
		-- Rerun while previous session still open: kill it, start fresh.
		if run_term:is_open() then
			run_term:shutdown()
		end
		run_term.cmd = full
		run_term:toggle()
	else
		run_term = Terminal:new({
			cmd = full,
			count = 9,
			direction = "float",
			float_opts = { border = "rounded" },
			close_on_exit = true,
			on_open = function()
				vim.cmd("startinsert!")
			end,
		})
		run_term:toggle()
	end
end

-- F6 / <leader>dc: debug the current file (nvim-dap; adapter per filetype).
function M.debug()
	require("dap").continue()
end

return M
