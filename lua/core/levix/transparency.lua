-- LeVIX Transparency
-- Makes the editor background transparent so the host terminal (e.g. foot) shows
-- through. Colorschemes reset highlight groups when loaded, so transparency is
-- re-applied on every ColorScheme/UIEnter event.
--
-- Toggle at runtime with :LeVIXTransparency or require(...).toggle().
-- Disable permanently with vim.g.levix_transparency = false.

local M = {}

-- Groups whose background is forced to NONE (transparent).
-- Pmenu/PmenuSel are intentionally kept opaque for readability.
local groups = {
	"Normal",
	"NormalNC",
	"NormalFloat",
	"NonText",
	"SignColumn",
	"LineNr",
	"CursorLineNr",
	"CursorLine",
	"MsgArea",
	"EndOfBuffer",
	"FoldColumn",
	"StatusLine",
	"StatusLineNC",
	"WinBar",
	"WinBarNC",
	"TabLine",
	"TabLineFill",
	"TabLineSel",
	"FloatBorder",
}

function M.apply()
	if vim.g.levix_transparency == false then
		return
	end
	for _, group in ipairs(groups) do
		-- bg = "NONE" clears both guibg and ctermbg.
		pcall(vim.api.nvim_set_hl, 0, group, { bg = "NONE" })
	end
end

function M.enable()
	vim.g.levix_transparency = true
	M.apply()
end

function M.disable()
	vim.g.levix_transparency = false
	-- Re-apply the active colorscheme to restore its opaque backgrounds.
	vim.schedule(function()
		pcall(vim.cmd, "colorscheme " .. (vim.g.colors_name or "default"))
	end)
end

function M.toggle()
	if vim.g.levix_transparency == false then
		M.enable()
	else
		M.disable()
	end
end

function M.setup()
	M.apply()

	local group = vim.api.nvim_create_augroup("LeVIXTransparency", { clear = true })

	-- Colorschemes reset highlights on load; re-apply after they finish.
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = function()
			vim.schedule(M.apply)
		end,
	})

	-- Some plugins draw their background once the UI is up (dashboard, etc.).
	vim.api.nvim_create_autocmd("UIEnter", {
		group = group,
		callback = M.apply,
	})
end

return M