return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	lazy = false,
	config = function()
		require("nvim-treesitter").setup({})

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

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "*",
			callback = function()
				local ft = vim.bo.filetype
				if ft and ft ~= "" then
					pcall(vim.treesitter.start)
					pcall(function()
						vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
						vim.wo[0][0].foldmethod = "expr"
						vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end)
				end
			end,
		})
	end,
}
