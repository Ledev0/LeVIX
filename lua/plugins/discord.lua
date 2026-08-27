return {
	"vyfor/cord.nvim",
	cond = function()
		return vim.fn.executable("cargo") == 1
	end,
	event = "VeryLazy",
	opts = {
		user_stub = false,
		buttons = {
			{
				label = "View Repository",
				url = function(opts)
					return opts.repo_url
				end,
			},
		},
		display = {
			theme = "minecraft",
			flavor = "dark",
			show_time = true,
			view = "full",
		},
	},
}
