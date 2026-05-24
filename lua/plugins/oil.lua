return {
	"stevearc/oil.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("oil").setup({
			default_file_explorer = true,
			columns = {
				"icon",
			},
			view_options = {
				show_hidden = true,
			},
		})

		vim.keymap.set("n", "<leader>o", "<CMD>Oil<CR>", { desc = "Open Oil File Explorer" })
	end,
}
