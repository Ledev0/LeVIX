local theme_cache = vim.fn.stdpath("config") .. "/.levix_theme_cache"

return {
	{ "catppuccin/nvim", name = "catppuccin", lazy = true },
	{ "folke/tokyonight.nvim", lazy = true },
	{ "ellisonleao/gruvbox.nvim", lazy = true },
	{ "rose-pine/neovim", name = "rose-pine", lazy = true },
	{ "rebelot/kanagawa.nvim", lazy = true },

	{
		"folke/which-key.nvim",
		init = function()
			local function save_theme(theme)
				local file = io.open(theme_cache, "w")
				if file then
					file:write(theme)
					file:close()
				end
			end

			vim.keymap.set("n", "<leader>T", function()
				local success, builtin = pcall(require, "telescope.builtin")

				if success then
					builtin.colorscheme({
						enable_preview = true,
						previewer = false,
						layout_strategy = "center",
						layout_config = {
							width = 0.25,
							height = 0.3,
							prompt_position = top,
							preview_cutoff = 1,
						},
						attach_mappings = function(_, map)
							map("i", "<CR>", function(prompt_bufnr)
								local actions = require("telescope.actions")
								local action_state = require("telescope.actions.state")
								local selection = action_state.get_selected_entry()
								actions.close(prompt_bufnr)
								if selection then
									pcall(vim.cmd, "colorscheme " .. selection.value)
									save_theme(selection.value)
								end
							end)
							return true
						end,
					})
				else
					local themes = { "catppuccin", "tokyonight", "gruvbox", "rose-pine", "kanagawa" }
					vim.ui.select(themes, { prompt = "🎨 Select LeVIX Theme:" }, function(choice)
						if choice then
							pcall(vim.cmd, "colorscheme " .. choice)
							save_theme(choice)
						end
					end)
				end
			end, { desc = "Switch Theme" })
		end,
	},
}
