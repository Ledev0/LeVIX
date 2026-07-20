-- lua/plugins/live-server.lua
return {
	"selimacerbas/live-server.nvim",
	dependencies = {
		"folke/which-key.nvim",
		"nvim-telescope/telescope.nvim",
	},
	init = function()
		local ok, wk = pcall(require, "which-key")
		if ok then
			wk.add({ { "<leader>l", group = " LiveServer" } })
		end
	end,
	opts = {
		default_port = 8000,
		live_reload = { enabled = true, inject_script = true, debounce = 120, css_inject = true },
		directory_listing = { enabled = true, show_hidden = false },
	},
	keys = {
		{ "<leader>ls", "<cmd>LiveServerStart<cr>", desc = "Start (pick path & port)" },
		{ "<leader>lo", "<cmd>LiveServerOpen<cr>", desc = "Open existing port in browser" },
		{ "<leader>lr", "<cmd>LiveServerReload<cr>", desc = "Force reload (pick port)" },
		{ "<leader>lt", "<cmd>LiveServerToggleLive<cr>", desc = "Toggle live-reload (pick port)" },
		{ "<leader>li", "<cmd>LiveServerStatus<cr>", desc = "Show server status" },
		{ "<leader>lS", "<cmd>LiveServerStop<cr>", desc = "Stop one (pick port)" },
		{ "<leader>lA", "<cmd>LiveServerStopAll<cr>", desc = "Stop all" },
	},
	config = function(_, opts)
		require("live_server").setup(opts)
	end,
}
