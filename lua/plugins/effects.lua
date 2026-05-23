return {
	{
		"tzachar/highlight-undo.nvim",
		config = function()
			require("highlight-undo").setup({
				hlgroup = "HighlightUndo",
				duration = 300,
				keymaps = {
					{ "n", "u", "undo", {} },
					{ "n", "<C-r>", "redo", {} },
				},
			})
		end,
	},

	{
		"anuvyklack/windows.nvim",
		dependencies = {
			"anuvyklack/middleclass",
			"anuvyklack/animation.nvim",
			config = function()
				vim.o.winwidth = 10
				vim.o.winminwidth = 10
				vim.o.equalalways = false
				require("windows").setup({
					animation = {
						enable = true,
						duration = 250,
					},
				})
			end,
		},
	},
}
