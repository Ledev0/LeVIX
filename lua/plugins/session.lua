return {
	"rmagatti/auto-session",
	config = function()
		require("auto-session").setup({
			auto_restore_enabled = true,
			auto_session_suppress_dirs = { "~/", "~/Downloads", "/" },
		})

		vim.keymap.set("n", "<leader>ss", "<cmd>SessionSave<CR>", { desc = " Save Current Session" })
		vim.keymap.set("n", "<leader>sr", "<cmd>SessionRestore<CR>", { desc = "󰦛 Restore Last Session" })
	end,
}
