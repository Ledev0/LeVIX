return {
	"folke/zen-mode.nvim",
	cmd = "ZenMode",
	opts = {
		window = {
			backdrop = 1,
			width = 0.99,
			height = 1,
			options = {
				signcolumn = "no",
				number = false,
				relativenumber = false,
				cursorline = false,
			},
			plugins = {
				gitsigns = { enabled = false },
				tmux = { enabled = true },
			},
			on_open = function(win)
				if vim.fn.exists(":NvimTreeClose") == 1 then
					pcall(vim.cmd, "NvimTreeClose")
				elseif vim.fn.exists(":NeoTreeClose") == 1 then
					pcall(vim.cmd, "NeoTreeClose")
				end
				pcall(vim.cmd, "TagbarClose")
			end,
			on_close = function() end,
		},
	},
}
