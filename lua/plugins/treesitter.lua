return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	opts = {
		ensure_installed = { "java", "python", "c", "cpp", "lua", "bash", "markdown", "markdown_inline" },
		sync_install = false,
		auto_install = true,
		highlight = {
			enable = true, -- Highlighting engine
			additional_vim_regex_highlighting = false,
		},
		indent = { enable = true },
	},
	config = function(_, opts)
		require("nvim-treesitter").setup(opts)
	end,
}
