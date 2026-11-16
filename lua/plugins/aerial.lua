return {
	"stevearc/aerial.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	event = "BufReadPost",
	config = function()
		require("aerial").setup({
			layout = {
				width = 35,
				default_direction = "right",
			},
			show_guides = true,
		})
	end,
}
