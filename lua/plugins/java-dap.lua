return {
	"mfussenegger/nvim-jdtls",
	ft = "java",
	config = function()
		local config = {
			cmd = { "jdtls" },
			root_dir = vim.fs.dirname(vim.fs.find({ ".git", "mvnw", "gradlew", "pom.xml" }, { upward = true })[1]),
		}

		config["on_attach"] = function(client, bufnr)
			require("jdtls").setup_dap({ hotcodereplace = "auto" })
		end

		require("jdtls").start_or_attach(config)
	end,
}
