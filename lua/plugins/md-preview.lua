return {
	"selimacerbas/markdown-preview.nvim",
	dependencies = { "selimacerbas/live-server.nvim" },
	ft = "markdown",
	keys = {
		{ "<leader>as", "<cmd>MarkdownPreview<CR>", desc = "Markdown Start preview" },
		{ "<leader>ap", "<cmd>MarkdownPreviewStop<CR>", desc = "Markdown Stop preview" },
		{ "<leader>ar", "<cmd>MarkdownPreviewRefresh<CR>", desc = "Markdown Refresh preview" },
	},
	config = function()
		local browser
		if vim.fn.has("wsl") == 1 or vim.fn.has("win32") == 1 then
			browser = { "cmd.exe", "/c", "start", "" }
		end
		require("markdown_preview").setup({
			instance_mode = "takeover",
			port = 0,
			open_browser = true,
			browser = browser,
			default_theme = "dark",
			debounce_ms = 300,
		})
	end,
}
