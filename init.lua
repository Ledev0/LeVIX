-- Leader Key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Impprting Keymaps
require("core.keymaps")
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

-- Keymaps
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })

-- Navigation between splits
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom split" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top split" })

-- Impprting Lazy The Pacakge Manager
require("config.lazy")

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

vim.fn.sign_define("DiagnosticSignError", { text = "✗", texthl = "DiagnosticSignError" })
vim.fn.sign_define("DiagnosticSignWarn", { text = "⚠", texthl = "DiagnosticSignWarn" })
vim.fn.sign_define("DiagnosticSignInfo", { text = "ℹ", texthl = "DiagnosticSignInfo" })
vim.fn.sign_define("DiagnosticSignHint", { text = "💡", texthl = "DiagnosticSignHint" })

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
