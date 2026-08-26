return {
	"nvim-telescope/telescope.nvim",
	cmd = "Telescope",
	keys = {
		"<leader>ff",
		"<leader>fs",
		"<leader>fb",
		"<leader>fh",
		"<leader>fo",
		"<leader>T",
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
	},
	config = function()
		require("telescope").setup({
			defaults = {
				file_ignore_patterns = { "node_modules", ".git" },
			},
		})
		require("telescope").load_extension("fzf")
		require("telescope").setup({
			defaults = {
				file_ignore_patterns = { "node_modules", ".git" },
			},
			pickers = {
				find_files = {
					hidden = true,
				},
			},
		})
	end,
}
