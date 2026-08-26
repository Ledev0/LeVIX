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
		require("harpoon"):setup()
	end,
}
