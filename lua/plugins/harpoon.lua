return {
	"ThePrimeagen/harpoon",
	keys = {
		{ "<leader>ha", desc = "Add File to Harpoon" },
		{ "<leader>hh", desc = "Show Harpoon Menu" },
		{ "<C-1>", desc = "Go to File 1" },
		{ "<C-2>", desc = "Go to File 2" },
		{ "<C-3>", desc = "Go to File 3" },
		{ "<C-4>", desc = "Go to File 4" },
	},
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local harpoon = require("harpoon")
		harpoon:setup()

		vim.keymap.set("n", "<leader>ha", function()
			harpoon:list():add()
		end, { desc = "  Add File to Harpoon" })
		vim.keymap.set("n", "<leader>hh", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end, { desc = " Show Harpoon Menu" })

		vim.keymap.set("n", "<C-1>", function()
			harpoon:list():select(1)
		end, { desc = "Go to File 1" })
		vim.keymap.set("n", "<C-2>", function()
			harpoon:list():select(2)
		end, { desc = "Go to File 2" })
		vim.keymap.set("n", "<C-3>", function()
			harpoon:list():select(3)
		end, { desc = "Go to File 3" })
		vim.keymap.set("n", "<C-4>", function()
			harpoon:list():select(4)
		end, { desc = "Go to File 4" })
	end,
}
