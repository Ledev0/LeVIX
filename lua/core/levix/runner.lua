-- LeVIX Code Runner (F5 / <leader>dr)
-- Runs the current file in a dedicated floating toggleterm (count 9, reused).
-- When the program exits the float shows "Press ENTER to close" and stays
-- open until Enter is hit. Supports: java (single-file, JDK 11+), c, cpp,
-- python, bash.

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

-- NOTE: no shell `read` here — toggleterm cmd-terminals get stdin EOF, so read
-- returns instantly and the float closes. The prompt is printed as the shell's
-- last act; the ENTER-to-close part is handled nvim-side in on_exit below.
local function with_exit_prompt(cmd)
	return string.format('%s; printf "\\n[LeVIX] Press ENTER to close... "', cmd)
end

local function make_term(full, cwd)
	local Terminal = require("toggleterm.terminal").Terminal
	return Terminal:new({
		cmd = full,
		count = 9,
		direction = "float",
		dir = cwd,
		float_opts = { border = "rounded" },
		-- Explicit: toggleterm's global default is true, which closed the float
		-- the moment the shell exited. We keep the window and close on ENTER.
		close_on_exit = false,
		on_open = function()
			vim.cmd("startinsert!")
		end,
		on_exit = function(term)
			pcall(vim.keymap.set, "t", "<CR>", function()
				term:close()
			end, { buffer = term.bufnr, silent = true })
		end,
	})
end

--- Run a shell command in the shared LeVIX float (ENTER to close).
--- Used by F5 and by the C++ build module (run-after-build).
---@param cmd string shell command (callers must shellescape untrusted parts)
---@param cwd? string working directory
function M.exec_cmd(cmd, cwd)
	local full = with_exit_prompt(cmd)
	-- shutdown() (close + delete_buf + delete(id)) is required: close() alone
	-- leaves the terminal registered under count 9, so Terminal:new() would
	-- return the dead object and the next run would show stale output.
	if run_term then
		run_term:shutdown()
	end
	run_term = make_term(full, cwd)
	run_term:toggle()
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

	M.exec_cmd(cmd)
end

-- F6 / <leader>dc: debug the current file (nvim-dap; adapter per filetype).
function M.debug()
	require("dap").continue()
end

return M
