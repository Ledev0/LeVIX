return {
	-- Code Runner
	{
		"CRAG666/code_runner.nvim",
		config = function()
			require("code_runner").setup({
				filetype = {
					java = "cd $dir && javac $fileName && java $fileNameWithoutExt",
					python = "python3 $file",
					c = "cd $dir && gcc $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt",
					cpp = "cd $dir && g++ $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt",
				},
			})

			vim.keymap.set("n", "<leader>rc", "<cmd>RunCode<CR>", { desc = "Run Code" })
			vim.keymap.set("n", "<leader>rf", "<cmd>RunFile<CR>", { desc = "Run File" })
		end,
	},
}
