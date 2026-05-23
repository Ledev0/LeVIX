-- ~/.config/nvim/lua/core/keymaps.lua
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

keymap('n', '<Esc>', '<cmd>nohlsearch<CR>', opts)

-- Fast Saving / Quiting
keymap('n', '<leader>w', '<cmd>write<CR>', { desc = 'Save file' })
keymap('n', '<leader>q', '<cmd>quit<CR>', { desc = 'Quit' })

-- Splits Moving
keymap('n', '<C-h>', '<C-w>h', { desc = 'Move to left split' })
keymap('n', '<C-l>', '<C-w>l', { desc = 'Move to right split' })
keymap('n', '<C-j>', '<C-w>j', { desc = 'Move to bottom split' })
keymap('n', '<C-k>', '<C-w>k', { desc = 'Move to top split' })

-- Splits Enlarge / Reduce
keymap("n", "<C-Up>", ":resize -2<CR>", opts)
keymap("n", "<C-Down>", ":resize +2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Line shading
keymap("v", "J", ":m '>+1<CR>gv=gv", opts)
keymap("v", "K", ":m '<-2<CR>gv=gv", opts)

-- Copy/Paste 
keymap("v", "p", '"_dP', opts)

-- Buffers
keymap("n", "<S-l>", ":bnext<CR>", { desc = "Next Buffer" })
keymap("n", "<S-h>", ":bprevious<CR>", { desc = "Previous Buffer" })
keymap("n", "<leader>x", ":bdelete<CR>", { desc = "Close current buffer" })

-- Toggleterm bindings
keymap("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<CR>", { desc = "Terminal Horizontal" })
keymap("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical size=60<CR>", { desc = "Terminal Vertical" })
keymap("n", "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", { desc = "Terminal Float" })

-- Telescope Expanded (Adding the Dashboard 'Recent Files' shortcut)
keymap('n', '<leader>fo', '<cmd>Telescope oldfiles<CR>', { desc = 'Recent Files' })

-- Gitsigns Mappings (Navigating changes inside a file)
keymap('n', ']g', "<cmd>lua require('gitsigns').next_hunk()<CR>", { desc = 'Next Git Change' })
keymap('n', '[g', "<cmd>lua require('gitsigns').prev_hunk()<CR>", { desc = 'Prev Git Change' })
keymap('n', '<leader>gl', "<cmd>lua require('gitsigns').blame_line()<CR>", { desc = 'Blame Line' })
keymap('n', '<leader>gp', "<cmd>lua require('gitsigns').preview_hunk()<CR>", { desc = 'Preview Change Hunk' })
keymap('n', '<leader>gr', "<cmd>lua require('gitsigns').reset_hunk()<CR>", { desc = 'Reset Line Change' })
-- Lazygit integrated through ToggleTerm
keymap('n', '<leader>gg', '<cmd>lua _LAZYGIT_TOGGLE()<CR>', { desc = 'Toggle Lazygit' })

