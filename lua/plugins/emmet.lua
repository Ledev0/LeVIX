return {
	{
		"mattn/emmet-vim",
		event = { "InsertEnter" },
		config = function()
			vim.g.user_emmet_leader_key = "<C-y>"
			vim.g.user_emmet_settings = {
				html = {
					attributes_quote = '"',
				},
			}
			vim.g.user_emmet_install_global = 0
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact" },
				callback = function()
					vim.keymap.set("i", "<buffer>", "<plug>(emmet-expand-abbr)", { remap = true })
				end,
			})
		end,
	},
}
