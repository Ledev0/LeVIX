return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("gitsigns").setup({
				signs = {
					add = { text = "┃" },
					change = { text = "┃" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
					untracked = { text = "┆" },
				},
				signcolumn = true,
				watch_gitdir = { follow_files = true },
				auto_attach = true,
				current_line_blame = true,
				current_line_blame_opts = {
					delay = 500,
					virt_text_pos = "eol",
				},
			})
			local gs = require("gitsigns")
			vim.keymap.set("n", "]g", gs.next_hunk, { desc = "Next Git Change" })
			vim.keymap.set("n", "[g", gs.prev_hunk, { desc = "Prev Git Change" })
			vim.keymap.set("n", "<leader>gl", gs.blame_line, { desc = "Blame Line" })
			vim.keymap.set("n", "<leader>gp", gs.preview_hunk, { desc = "Preview Change Hunk" })
			vim.keymap.set("n", "<leader>gr", gs.reset_hunk, { desc = "Reset Line Change" })
		end,
	},
}
