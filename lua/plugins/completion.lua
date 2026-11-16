return {
	{
		"saghen/blink.lib",
		version = "*",
	},

	{
		"L3MON4D3/LuaSnip",
		dependencies = { "rafamadriz/friendly-snippets" },
		event = "InsertEnter",
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},

	{
		"saghen/blink.cmp",
		version = "*",
		-- No `build = "cargo build --release"`: release pins ship with prebuilt
		-- fuzzy binaries (downloaded at runtime by blink.cmp). Building from
		-- source is only needed when tracking the main branch.
		dependencies = {
			"saghen/blink.lib",
			"L3MON4D3/LuaSnip",
			"ribru17/blink-cmp-spell",
		},
		event = "InsertEnter",
		config = function()
			require("blink.cmp").setup({
				keymap = {
					preset = "default",
					["<CR>"] = { "accept", "fallback" },
					["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
					["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
					["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				},
				appearance = { nerd_font_variant = "mono" },
				completion = {
					documentation = {
						auto_show = true,
						auto_show_delay_ms = 200,
					},
				},
				sources = {
					default = { "lsp", "path", "snippets", "buffer" },
					-- Spell suggestions cost per keystroke; only enable them where
					-- spellcheck is on (core/options.lua spell FileType autocmd).
					per_filetype = {
						markdown = { inherit_defaults = true, "spell" },
						text = { inherit_defaults = true, "spell" },
						gitcommit = { inherit_defaults = true, "spell" },
					},
					providers = {
						spell = {
							name = "Spell",
							module = "blink-cmp-spell",
							opts = {
								keep_all_entries = false,
							},
						},
					},
				},
				snippets = { preset = "luasnip" },
				signature = { enabled = true },
			})
		end,
	},
}
