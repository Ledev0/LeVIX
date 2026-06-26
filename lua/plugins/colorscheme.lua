return {
	"ellisonleao/gruvbox.nvim",
	priority = 1000,
	config = function()
		require("gruvbox").setup({
			contrast = "hard",
			bold = true,
			italic = {
				strings = true,
				comments = true,
				operators = false,
				folds = true,
			},
			transparent_mode = false,
		})
		vim.cmd.colorscheme("gruvbox")
	end,
}
