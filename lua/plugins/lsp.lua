return {
	{
		"mason-org/mason.nvim",
		cmd = { "Mason", "MasonInstall", "MasonUpdate" },
		config = function()
			require("mason").setup({
				ui = {
					border = "rounded",
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})

			local ok, registry = pcall(require, "mason-registry")
			if not ok then
				return
			end

			local ensure_installed = { "jdtls", "java-debug-adapter", "google-java-format", "stylua" }
			for _, tool in ipairs(ensure_installed) do
				local pok, pkg = pcall(registry.get_package, tool)
				if pok and not pkg:is_installed() then
					pkg:install()
				end
			end
		end,
	},

	{
		"mason-org/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = { "pyright", "clangd", "ruff", "html", "cssls", "ts_ls", "lua_ls" },
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			vim.lsp.config("pyright", {
				settings = {
					python = {
						analysis = {
							typeCheckingMode = "basic",
						},
					},
				},
			})
			vim.lsp.config("ruff", {})
			-- clangd: system binary preferred over Mason's, compile_commands.json
			-- and --query-driver wired from detected compilers (core/levix/cpp/clangd.lua).
			-- nvim 0.12: a function `cmd` must return an RPC client, so we start it here.
			vim.lsp.config("clangd", {
				-- CMakeLists.txt is missing from lspconfig's defaults, so a
				-- non-git CMake project would get no root at all and clangd
				-- would never see build/compile_commands.json.
				root_markers = {
					"compile_commands.json",
					"compile_flags.txt",
					"CMakeLists.txt",
					".clangd",
					".clang-tidy",
					".clang-format",
					".git",
				},
				cmd = function(dispatchers, config)
					local cfg = config or {}
					local ok, cpp_clangd = pcall(require, "core.levix.cpp.clangd")
					local root = cfg.root_dir
					if not root then
						-- Derive the project root from the buffer when LSP found none.
						local name = vim.api.nvim_buf_get_name(0)
						local ok_project, project = pcall(require, "core.levix.cpp.project")
						if name ~= "" and ok_project then
							root = project.find_cmake_root(vim.fs.dirname(name))
						end
					end
					local argv = (ok and cpp_clangd.build_cmd(root)) or { "clangd" }
					return vim.lsp.rpc.start(argv, dispatchers, {
						cwd = cfg.cmd_cwd,
						env = cfg.cmd_env,
						detached = cfg.detached,
					})
				end,
			})
			vim.lsp.config("html", {})
			vim.lsp.config("cssls", {})
			vim.lsp.config("ts_ls", {})
			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						diagnostics = { globals = { "vim" } },
						workspace = {
							checkThirdParty = false,
							library = vim.api.nvim_get_runtime_file("", true),
						},
						telemetry = { enable = false },
					},
				},
			})
			vim.lsp.enable({ "pyright", "ruff", "clangd", "html", "cssls", "ts_ls", "lua_ls" })

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local map = function(key, action, desc)
						vim.keymap.set("n", key, action, { buffer = args.buf, desc = desc })
					end

					map("gd", vim.lsp.buf.definition, "Go to Definition")
					map("gr", vim.lsp.buf.references, "Go to References")
					map("K", vim.lsp.buf.hover, "Hover Documentation")
					map("<leader>cr", vim.lsp.buf.rename, "Rename")
					map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
					map("[d", function()
						vim.diagnostic.jump({ count = -1, float = true })
					end, "Previous Diagnostic")
					map("]d", function()
						vim.diagnostic.jump({ count = 1, float = true })
					end, "Next Diagnostic")
				end,
			})
		end,
	},
}
