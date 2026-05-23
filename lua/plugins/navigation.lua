return {
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {
			labels = "asdfghjklqwertyuiopzxcvbnm",
			search = { mode = "exact" },
		},
		config = function(_, opts)
			require("flash").setup(opts)
		end,
	},
}
