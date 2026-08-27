return {
	"stevearc/conform.nvim",
	event = "VeryLazy",
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				java = { "google-java-format" },
				python = { "ruff_format" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				lua = { "stylua" },
				html = { "prettier" },
				css = { "prettier" },
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
			},
		})

		local warned = {}

		vim.api.nvim_create_autocmd("BufWritePre", {
			callback = function(args)
				local ft = vim.bo[args.buf].filetype
				local formatters = conform.formatters_by_ft[ft]
				if not formatters then
					return
				end

				for _, name in ipairs(formatters) do
					local info = conform.get_formatter_info(name, args.buf)
					if not info.available then
						if not warned[name] then
							warned[name] = true
							vim.notify(
								string.format(
									"LeVIX: formatter '%s' not found. Install it to enable formatting for %s files.",
									name,
									ft
								),
								vim.log.levels.WARN,
								{ title = "LeVIX Formatter" }
							)
						end
					end
				end

				conform.format({ bufnr = args.buf, timeout_ms = 3000, lsp_fallback = true })
			end,
		})
	end,
}
