return {
	"selimacerbas/markdown-preview.nvim",
	ft = "markdown",
	cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewRefresh" },
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
