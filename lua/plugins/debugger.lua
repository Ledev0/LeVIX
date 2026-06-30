return {
	{
		"mfussenegger/nvim-dap",
		keys = { "<F5>", "<F10>", "<F11>", "<F12>", "<leader>db", "<leader>du" },
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
			"jay-babu/mason-nvim-dap.nvim",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			dapui.setup()

			require("mason-nvim-dap").setup({
				ensure_installed = { "codelldb" },
				automatic_installation = true,
			})

			local mason_registry = require("mason-registry")
			local codelldb_path = mason_registry.get_package("codelldb"):get_install_path()
			local extension_path = codelldb_path .. "/extension/"
			local codelldb_bin = extension_path .. "adapter/codelldb"

			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = codelldb_bin,
					args = { "--port", "${port}" },
				},
			}

			dap.configurations.cpp = {
				{
					name = "Launch file",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					sourceMap = nil,
					expressions = "simple",
				},
			}
			dap.configurations.c = dap.configurations.cpp

			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end

			vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Continue" })
			vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
			vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
			vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })
			vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
			vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle Debug UI" })
		end,
	},

	{
		"mfussenegger/nvim-dap-python",
		ft = "python",
		dependencies = { "mfussenegger/nvim-dap" },
		config = function()
			require("dap-python").setup("python3")
		end,
	},
}
