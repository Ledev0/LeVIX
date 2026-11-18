-- LeVIX C++ — debug integration
-- Launches the existing codelldb DAP adapter against the binary produced by
-- the build operation. No manual executable path prompt.

local M = {}

local function notify(msg, level, title)
	vim.notify("LeVIX: " .. msg, level or vim.log.levels.INFO, { title = title or "LeVIX C++" })
end

--- Debug a specific binary with codelldb (adapter configured in debugger.lua).
---@param binary string path to the freshly built executable
---@param cwd string working directory for the debug session
---@return boolean started
function M.launch(binary, cwd)
	if not binary or vim.fn.executable(binary) ~= 1 then
		notify("no built binary to debug", vim.log.levels.ERROR)
		return false
	end

	local ok, dap = pcall(require, "dap")
	if not ok then
		notify("nvim-dap not available — open a C++ buffer and retry", vim.log.levels.ERROR)
		return false
	end

	if not dap.adapters.codelldb then
		notify("codelldb adapter not configured (is Mason's codelldb installed?)", vim.log.levels.ERROR)
		return false
	end

	dap.run({
		name = "LeVIX C++ (built binary)",
		type = "codelldb",
		request = "launch",
		program = binary,
		cwd = cwd,
		-- Pause at the entry point so the DAP UI stays open
		stopOnEntry = true,
	})
	return true
end

return M
