return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	lazy = false,
	config = function()
		require("nvim-treesitter").setup({})

		-- pcall: parser download must never break startup (e.g. offline).
		pcall(function()
			require("nvim-treesitter").install({
				"java",
				"python",
				"c",
				"cpp",
				"lua",
				"bash",
				"markdown",
				"markdown_inline",
			})
		end)

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "*",
			callback = function()
				local ft = vim.bo.filetype
				if ft and ft ~= "" then
					-- Folding is intentionally left off (vim.opt.foldenable = false in options.lua).
					pcall(vim.treesitter.start)
					pcall(function()
						vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end)
				end
			end,
		})
	end,
}
