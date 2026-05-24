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

-- WSL Clipboard Fix
if vim.fn.has("wsl") == 1 then
	vim.g.clipboard = {
		name = "WSL-Windows-Clipboard",
		copy = {
			["+"] = "clip.exe",
			["*"] = "clip.exe",
		},
		paste = {
			["+"] = 'powershell.exe -NoProfile -Command "Get-Clipboard"',
			["*"] = 'powershell.exe -NoProfile -Command "Get-Clipboard"',
		},
		cache_enabled = 0,
	}
end
