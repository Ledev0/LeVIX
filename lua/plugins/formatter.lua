return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	config = function()
		require("conform").setup({
			formatters_by_ft = {
				java = { "google-java-format" },
				python = { "ruff_format" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				lua = { "stylua" },
			},
			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
		})

		vim.keymap.set("n", "<leader>cf", function()
			require("conform").format({ async = true })
		end, { desc = "Format File" })
	end,
}
