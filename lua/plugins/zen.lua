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
				pcall(function()
					require("oil").close()
				end)
				pcall(vim.cmd, "AerialClose")
			end,
			on_close = function() end,
		},
	},
}
