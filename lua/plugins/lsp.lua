return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup({
				ui = {
					border = "rounded",
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})
		end,
	},

	{
		"williamboman/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = { "pyright", "clangd" },
				automatic_installation = true,
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			vim.lsp.config("pyright", {})
			vim.lsp.config("clangd", {})
			vim.lsp.enable({ "pyright", "clangd" })

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local map = function(key, action, desc)
						vim.keymap.set("n", key, action, { buffer = args.buf, desc = desc })
					end

					map("gd", vim.lsp.buf.definition, "Go to Definition")
					map("gr", vim.lsp.buf.references, "Go to References")
					map("K", vim.lsp.buf.hover, "Hover Documentation")
					map("<leader>cr", vim.lsp.buf.rename, "Rename")
					map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
					map("[d", vim.diagnostic.goto_prev, "Previous Diagnostic")
					map("]d", vim.diagnostic.goto_next, "Next Diagnostic")
				end,
			})
		end,
	},
}
