return {
	{
		"CRAG666/code_runner.nvim",
		ft = { "java", "python", "c", "cpp" },
		config = function()
			require("code_runner").setup({
				filetype = {
					java = "cd $dir && javac $fileName && java $fileNameWithoutExt",
					python = "python3 $file",
					c = "cd $dir && gcc -Wall -g $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt",
					cpp = "cd $dir && g++ -Wall -g -std=c++17 $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt",
				},
			})

			vim.keymap.set("n", "<leader>rc", "<cmd>RunCode<CR>", { desc = "Run Code" })
			vim.keymap.set("n", "<leader>rf", "<cmd>RunFile<CR>", { desc = "Run File" })
		end,
	},
}
