return {
	"mfussenegger/nvim-jdtls",
	ft = "java",
	config = function()
		local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")

		local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name

		local config = {
			cmd = { "jdtls", "-data", workspace_dir },

			root_dir = vim.fs.dirname(vim.fs.find({ ".git", "mvnw", "gradlew", "pom.xml" }, { upward = true })[1]),
		}

		config["on_attach"] = function(client, bufnr)
			require("jdtls").setup_dap({ hotcodereplace = "auto" })
		end

		require("jdtls").start_or_attach(config)
	end,
}
