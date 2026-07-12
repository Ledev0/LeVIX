return {
	{
		"CRAG666/code_runner.nvim",
		ft = { "java", "python", "c", "cpp" },
		config = function()
			require("code_runner").setup({
				filetype = {
					java = "cd $dir && javac $fileName && java $fileNameWithoutExt < input.txt",
					python = "python3 $file < input.txt",
					c = "cd $dir && gcc -Wall -g $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt < input.txt",
					cpp = "cd $dir && g++ -Wall -g -std=c++17 $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt < input.txt",
				},
			})

			vim.keymap.set("n", "<leader>rc", "<cmd>RunCode<CR>", { desc = "Run Code" })
			vim.keymap.set("n", "<leader>rf", "<cmd>RunFile<CR>", { desc = "Run File" })

			vim.keymap.set("n", "<leader>ri", function()
				local dir = vim.fn.expand("%:p:h")
				local input_path = dir .. "/input.txt"
				vim.cmd("botright 10split " .. vim.fn.fnameescape(input_path))
			end, { desc = "Open Input File" })
		end,
	},
}
