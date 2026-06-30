return {
	"Bekaboo/dropbar.nvim",
	dependencies = {
		"nvim-telescope/telescope-fzf-native.nvim",
	},
	event = "BufReadPost",
	config = function()
		require("dropbar").setup()
	end,
}
