return {
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		event = "VeryLazy",
		config = function()
			require("lualine").setup({
				options = {
					theme = "auto",
					icons_enabled = true,
					component_separators = { left = "|", right = "|" },
					section_separators = { left = " ", right = " " },
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch", "diff", "diagnostics" },
					lualine_c = { "filename" },
					lualine_x = { "encoding", "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
			})
		end,
	},

	{
		"akinsho/bufferline.nvim",
		version = "*",
		dependencies = "nvim-tree/nvim-web-devicons",
		event = "VeryLazy",
		config = function()
			require("bufferline").setup({
				options = {
					diagnostics = "nvim_lsp",
					show_buffer_close_icons = false,
					show_close_icon = false,
				},
			})
		end,
	},

	{
		"stevearc/dressing.nvim",
		init = function()
			---@diagnostic disable-next-line: duplicate-set-field
			vim.ui.select = function(...)
				require("lazy").load({ plugins = { "dressing.nvim" } })
				return vim.ui.select(...)
			end
			---@diagnostic disable-next-line: duplicate-set-field
			vim.ui.input = function(...)
				require("lazy").load({ plugins = { "dressing.nvim" } })
				return vim.ui.input(...)
			end
		end,
	},

	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		config = function()
			require("snacks").setup({
				image = { enabled = false },
				dashboard = {
					enabled = true,
					preset = {
						header = [[
  __              __  __  ______  __   __     
/\ \            /\ \/\ \/\__  _\/\ \ /\ \    
\ \ \         __\ \ \ \ \/_/\ \/\ `\`\/'/'   
\ \ \  __  /'__`\ \ \ \ \ \ \ \ `\/ > <     
\ \ \L\ \/\  __/\ \ \_/ \ \_\ \__ \/'/\`\  
\ \____/\ \____\\ `\___/ /\_____\/\_\\ \_\
\ /___/  \/____/ `\/__/  \/_____/\/_/ \/_/
                                             
                                       

                        ]],
						keys = {
							{ icon = "󰈞", key = "f", desc = "Find File", action = ":Telescope find_files" },
							{ icon = "", key = "r", desc = "Recent Files", action = ":Telescope oldfiles" },
							{ icon = "󰍩", key = "g", desc = "Find Text", action = ":Telescope live_grep" },
							{ icon = "", key = "c", desc = "Config", action = ":Oil ~/.config/nvim" },
							{ icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
							{ icon = "󱌣", key = "m", desc = "Mason", action = ":Mason" },
							{ icon = "󰈆", key = "q", desc = "Quit", action = ":qa" },
						},
					},
					sections = {
						{ section = "header" },
						{ section = "keys", gap = 1, padding = 1 },
						{ section = "startup" },
					},
				},
			})
		end,
	},
	{
		"echasnovski/mini.icons",
		version = false,
		config = function()
			require("mini.icons").setup()
		end,
	},
}
