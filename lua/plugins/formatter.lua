return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				java = { "google-java-format" },
				python = { "ruff_format" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				lua = { "stylua" },
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
						return
					end
				end

				conform.format({ bufnr = args.buf, timeout_ms = 500, lsp_fallback = true })
			end,
		})

		vim.keymap.set("n", "<leader>cf", function()
			conform.format({ async = true })
		end, { desc = "Format File" })
	end,
}
