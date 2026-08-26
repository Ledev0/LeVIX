return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			java = { "checkstyle" },
			python = { "ruff" },
			c = { "clangtidy" },
			cpp = { "clangtidy" },
			html = { "htmlhint" },
			css = { "stylelint" },
			javascript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			typescript = { "eslint_d" },
			typescriptreact = { "eslint_d" },
		}

		local executable_map = {
			clangtidy = "clang-tidy",
		}

		local warned = {}

		local function try_lint_safe()
			local ft = vim.bo.filetype
			local linters = lint.linters_by_ft[ft]
			if not linters then
				return
			end

			for _, name in ipairs(linters) do
				local exe = executable_map[name] or name
				if vim.fn.executable(exe) == 0 then
					if not warned[name] then
						warned[name] = true
						vim.notify(
							string.format(
								"LeVIX: linter '%s' not found in PATH. Install it to enable linting for %s files.",
								exe,
								ft
							),
							vim.log.levels.WARN,
							{ title = "LeVIX Linter" }
						)
					end
					return
				end
			end

			lint.try_lint()
		end
		vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
			callback = try_lint_safe,
		})
	end,
}
