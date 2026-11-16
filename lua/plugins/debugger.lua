return {
	{
		"mfussenegger/nvim-dap",
		keys = {
			{ "<F6>", function() require("core.levix.runner").debug() end, desc = "Debug: Continue" },
			{ "<F10>", function() require("dap").step_over() end, desc = "Debug: Step Over" },
			{ "<F11>", function() require("dap").step_into() end, desc = "Debug: Step Into" },
			{ "<F12>", function() require("dap").step_out() end, desc = "Debug: Step Out" },
			{ "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
			{ "<leader>du", function() require("dapui").toggle() end, desc = "Toggle Debug UI" },
		},
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
				ensure_installed = { "codelldb", "bash-debug-adapter" },
				automatic_installation = true,
			})

			local mason_registry = require("mason-registry")
			local ok_pkg, pkg = pcall(mason_registry.get_package, "codelldb")
			if ok_pkg and pkg:is_installed() then
				local codelldb_path = pkg:get_install_path()
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
			else
				vim.notify(
					"LeVIX: codelldb not installed yet. Run :Mason to install it.",
					vim.log.levels.WARN,
					{ title = "LeVIX Debugger" }
				)
			end

			dap.configurations.cpp = {
				{
					name = "Launch file (stop on entry)",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					-- Pause at first line so the UI stays open; set breakpoints, then F6 to continue
					stopOnEntry = true,
					sourceMap = nil,
					expressions = "simple",
				},
			}
			dap.configurations.c = dap.configurations.cpp

			-- Bash debugging via Mason's bash-debug-adapter (vscode-bash-debug).
			local ok_bash, bashpkg = pcall(mason_registry.get_package, "bash-debug-adapter")
			if ok_bash and bashpkg:is_installed() then
				local bashdb_dir = bashpkg:get_install_path() .. "/extension/bashdb_dir"

				dap.adapters.bashdb = {
					type = "executable",
					command = "bash-debug-adapter", -- Mason bin dir is on PATH
					name = "bashdb",
				}
				local bash_config = {
					name = "Launch file",
					type = "bashdb",
					request = "launch",
					showDebugOutput = true,
					pathBashdb = bashdb_dir .. "/bashdb",
					pathBashdbLib = bashdb_dir,
					trace = true,
					fsRepr = "pretty-print",
					program = "${file}",
					cwd = "${workspaceFolder}",
				}
				dap.configurations.sh = { bash_config }
				dap.configurations.bash = dap.configurations.sh
			else
				vim.notify(
					"LeVIX: bash-debug-adapter not installed yet. Run :Mason to install it.",
					vim.log.levels.WARN,
					{ title = "LeVIX Debugger" }
				)
			end

			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end

			-- Python: debugpy can't pip-install system-wide (PEP 668), so
			-- bootstrap a dedicated venv once and point dap-python at it.
			-- Chain: venv → ensurepip (distro venvs ship without pip) → pip install.
			local function bootstrap_python_dap()
				local venv = vim.fn.stdpath("data") .. "/levix-dap-venv"
				local venv_python = venv .. "/bin/python"

				local function ready()
					require("dap-python").setup(venv_python)
					vim.notify(
						"LeVIX: python debugger ready (debugpy venv at " .. venv .. ")",
						vim.log.levels.INFO,
						{ title = "LeVIX Debugger" }
					)
				end

				local function install_debugpy()
					vim.fn.jobstart({ venv_python, "-m", "pip", "install", "--quiet", "debugpy" }, {
						on_exit = function(_, code)
							vim.schedule(function()
								if code == 0 then
									ready()
								else
									vim.notify(
										"LeVIX: debugpy install failed — python debug (F6) unavailable",
										vim.log.levels.WARN,
										{ title = "LeVIX Debugger" }
									)
								end
							end)
						end,
					})
				end

				local function ensure_pip()
					vim.fn.jobstart({ venv_python, "-m", "ensurepip", "--upgrade" }, {
						on_exit = function(_, code)
							vim.schedule(function()
								if code == 0 then
									install_debugpy()
								else
									vim.notify(
										"LeVIX: could not seed pip in dap venv — install python3-venv and retry F6",
										vim.log.levels.WARN,
										{ title = "LeVIX Debugger" }
									)
								end
							end)
						end,
					})
				end

				if vim.fn.executable(venv_python) == 1 then
					ensure_pip()
				else
					vim.fn.jobstart({ "python3", "-m", "venv", venv }, {
						on_exit = function(_, code)
							vim.schedule(function()
								if code == 0 then
									ensure_pip()
								end
							end)
						end,
					})
				end
			end

			require("dap-python").setup("python3") -- works immediately; venv upgrades it when ready
			bootstrap_python_dap()

			dap.configurations.python = {
				{
					name = "Launch file (stop on entry)",
					type = "python",
					request = "launch",
					program = "${file}",
					console = "integratedTerminal",
					pythonPath = function()
						local venv_python = vim.fn.stdpath("data") .. "/levix-dap-venv/bin/python"
						if vim.fn.executable(venv_python) == 1 then
							return venv_python
						end
						return "python3"
					end,
					-- Pause at first line so the UI stays open
					stopOnEntry = true,
				},
			}
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
