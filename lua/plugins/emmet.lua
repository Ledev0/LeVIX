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

			local emmet_filetypes = {
				"html",
				"css",
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
			}

			vim.api.nvim_create_autocmd("FileType", {
				pattern = emmet_filetypes,
				callback = function()
					pcall(vim.cmd, "EmmetInstall")
				end,
			})

			if vim.tbl_contains(emmet_filetypes, vim.bo.filetype) then
				pcall(vim.cmd, "EmmetInstall")
			end
		end,
	},
}
