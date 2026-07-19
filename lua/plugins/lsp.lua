return {
	{
		"williamboman/mason.nvim",
		cmd = { "Mason", "MasonInstall", "MasonUpdate" },
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
				ensure_installed = { "pyright", "clangd", "ruff", "html", "cssls", "ts_ls", "lua_ls" },
				automatic_installation = true,
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			vim.lsp.config("pyright", {
				settings = {
					python = {
						analysis = {
							typeCheckingMode = "basic",
						},
					},
				},
			})
			vim.lsp.config("ruff", {})
			vim.lsp.config("clangd", {})
			vim.lsp.config("html", {})
			vim.lsp.config("cssls", {})
			vim.lsp.config("ts_ls", {})
			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						diagnostics = { globals = { "vim" } },
						workspace = {
							checkThirdParty = false,
							library = vim.api.nvim_get_runtime_file("", true),
						},
						telemetry = { enable = false },
					},
				},
			})
			vim.lsp.enable({ "pyright", "ruff", "clangd", "html", "cssls", "ts_ls", "lua_ls" })

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
					map("[d", function()
						vim.diagnostic.jump({ count = -1, float = true })
					end, "Previous Diagnostic")
					map("]d", function()
						vim.diagnostic.jump({ count = 1, float = true })
					end, "Next Diagnostic")
				end,
			})
		end,
	},
}
