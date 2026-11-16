return {
	"mfussenegger/nvim-jdtls",
	ft = "java",
	config = function()
		local function setup_jdtls()
			local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
			local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name

			-- Guard: vim.fs.find() returns {} outside a project; fall back to cwd
			-- instead of erroring on vim.fs.dirname(nil).
			local root_markers = vim.fs.find({ ".git", "mvnw", "gradlew", "pom.xml" }, { upward = true })
			local root_dir = root_markers[1] and vim.fs.dirname(root_markers[1]) or vim.fn.getcwd()

			local config = {
				cmd = { "jdtls", "-data", workspace_dir },
				root_dir = root_dir,
				capabilities = require("blink.cmp").get_lsp_capabilities(),
				on_attach = function(client, bufnr)
					local dap = require("dap")
					require("jdtls").setup_dap({ hotcodereplace = "auto" })
					-- Pause at first line so the DAP UI stays open for breakpoints/stepping
					vim.schedule(function()
						for _, cfg in ipairs(dap.configurations.java or {}) do
							cfg.stopOnEntry = true
						end
					end)
				end,
			}

			require("jdtls").start_or_attach(config)
		end

		-- Attach to the buffer that triggered this lazy load (FileType already
		-- fired), then register the autocmd for future java buffers. Direct call
		-- + autocmd together avoid double start_or_attach on first open.
		if vim.bo.filetype == "java" then
			setup_jdtls()
		end
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "java",
			callback = setup_jdtls,
		})
	end,
}
