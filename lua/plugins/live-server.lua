return {
	"selimacerbas/live-server.nvim",
	dependencies = {
		"nvim-telescope/telescope.nvim",
	},
	keys = {
		{ "<leader>ls", "<cmd>LiveServerStart<cr>", desc = "Start Live Server" },
		{ "<leader>lo", "<cmd>LiveServerOpen<cr>", desc = "Open in Browser" },
		{ "<leader>lr", "<cmd>LiveServerReload<cr>", desc = "Force Reload" },
		{ "<leader>lt", "<cmd>LiveServerToggleLive<cr>", desc = "Toggle Live Reload" },
		{ "<leader>li", "<cmd>LiveServerStatus<cr>", desc = "Show Server Status" },
		{ "<leader>lS", "<cmd>LiveServerStop<cr>", desc = "Stop Server" },
		{ "<leader>lA", "<cmd>LiveServerStopAll<cr>", desc = "Stop All Servers" },
	},
	opts = {
		default_port = 8000,
		live_reload = { enabled = true, inject_script = true, debounce = 120, css_inject = true },
		directory_listing = { enabled = true, show_hidden = false },
	},
	config = function(_, opts)
		require("live_server").setup(opts)
	end,
}
