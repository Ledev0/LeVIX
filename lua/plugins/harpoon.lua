return {
	"ThePrimeagen/harpoon",
	keys = {
		{
			"<leader>ha",
			function() require("harpoon"):list():add() end,
			desc = "Add File to Harpoon",
		},
		{
			"<leader>hh",
			function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end,
			desc = "Show Harpoon Menu",
		},
		{ "<C-1>", function() require("harpoon"):list():select(1) end, desc = "Go to File 1" },
		{ "<C-2>", function() require("harpoon"):list():select(2) end, desc = "Go to File 2" },
		{ "<C-3>", function() require("harpoon"):list():select(3) end, desc = "Go to File 3" },
		{ "<C-4>", function() require("harpoon"):list():select(4) end, desc = "Go to File 4" },
	},
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		require("harpoon"):setup()
	end,
}
