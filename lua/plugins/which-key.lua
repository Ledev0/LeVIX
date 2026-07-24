return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	config = function()
		require("which-key").setup({
			delay = 500,
			win = {
				border = "rounded",
			},
			layout = {
				spacing = 5,
			},
			icons = {
				rules = false,
			},
		})

		require("which-key").add({
			{ "<leader>f", group = "󰍉 Find/Search" },
			{ "<leader>g", group = "󰊢 Git Engine" },
			{ "<leader>c", group = "󰅪 Code/LSP" },
			{ "<leader>t", group = "󰆍 Terminal Management" },
			{ "<leader>d", group = " Debug" },
			{ "<leader>r", group = " Run" },
			{ "<leader>a", group = " Markdown Preview" },

			{ "<leader>m", group = " Todo Tags" },
			{ "<leader>mt", "<cmd>TodoTelescope<CR>", desc = "Search Project Todos" },
			{ "<leader>ml", "<cmd>TodoLocList<CR>", desc = "List Local Todos" },

			{ "<leader>h", group = " Harpoon Jump" },
			{ "<leader>ha", desc = "Add File to Harpoon" },
			{ "<leader>hh", desc = "Show Harpoon Menu" },

			{ "<leader>s", group = " Sessions Management" },
			{ "<leader>ss", desc = "Save Current Session" },
			{ "<leader>sr", desc = "Restore Last Session" },
		})
	end,
}
