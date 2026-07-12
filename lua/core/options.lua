local opt = vim.opt

-- Leader Key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Nerd Font
vim.g.have_nerd_font = true

-- Line numbers
vim.o.number = true
vim.o.relativenumber = true

-- Mouse support
vim.o.mouse = "a"

-- Don't show mode (Becasue We will Add statusline later)
vim.o.showmode = false

-- Clipboard sync with OS
vim.o.clipboard = "unnamedplus"

-- Indentation
vim.o.breakindent = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smartindent = true

-- UI
vim.o.cursorline = true
vim.o.scrolloff = 8
vim.o.signcolumn = "yes"
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.termguicolors = true

-- Performance
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.undofile = true

-- Close telescope with Esc
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostics
vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = true,
	},
})

vim.fn.sign_define("DiagnosticSignError", { text = "", texthl = "DiagnosticSignError" })
vim.fn.sign_define("DiagnosticSignWarn", { text = "", texthl = "DiagnosticSignWarn" })
vim.fn.sign_define("DiagnosticSignInfo", { text = "", texthl = "DiagnosticSignInfo" })
vim.fn.sign_define("DiagnosticSignHint", { text = "", texthl = "DiagnosticSignHint" })

-- Spelling
vim.opt.spelllang = { "en_us" }
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "text", "gitcommit" },
	callback = function()
		vim.opt_local.spell = true
	end,
})
-- background Themes
vim.cmd([[highlight Normal guibg=none ctermbg=none]])
vim.cmd([[highlight NonText guibg=none ctermbg=none]])

-- Theme Cache
local theme_cache = vim.fn.stdpath("config") .. "/.levix_theme_cache"
local f = io.open(theme_cache, "r")
if f then
	local saved_theme = f:read("*all"):gsub("%s+", "")
	f:close()
	if saved_theme ~= "" then
		vim.schedule(function()
			pcall(vim.cmd, "colorscheme " .. saved_theme)
		end)
	end
end

-- Disable Folding
vim.opt.foldenable = false
