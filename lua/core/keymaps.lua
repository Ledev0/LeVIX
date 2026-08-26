local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- ============================================================
--  General
-- ============================================================
keymap("n", "<leader>w", "<cmd>write<CR>", { desc = "Save file" })
keymap("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })
keymap("n", "<leader>R", "<cmd>restart<CR>", { desc = "Restart" })

-- ============================================================
--  Window Navigation
-- ============================================================
keymap("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Move to bottom split" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Move to top split" })

-- Window Resize
keymap("n", "<C-Up>", ":resize -2<CR>", opts)
keymap("n", "<C-Down>", ":resize +2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- ============================================================
--  Visual Mode
-- ============================================================
keymap("v", "J", ":m '>+1<CR>gv=gv", opts)
keymap("v", "K", ":m '<-2<CR>gv=gv", opts)
keymap("v", "p", '"_dP', opts)

-- ============================================================
--  Buffers & Tabs
-- ============================================================
keymap("n", "<leader>v", "<cmd>enew<CR>", { desc = "New Buffer" })
keymap("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next Buffer" })
keymap("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous Buffer" })
keymap("n", "<leader>x", "<cmd>bdelete<CR>", { desc = "Close current buffer" })
keymap("n", "<Tab>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next Tab" })
keymap("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Prev Tab" })

-- ============================================================
--  Find / Search  (<leader>f)
-- ============================================================
keymap("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Find Files" })
keymap("n", "<leader>fs", "<cmd>Telescope live_grep<CR>", { desc = "Search Text" })
keymap("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Find Buffers" })
keymap("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Find Help" })
keymap("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", { desc = "Recent Files" })

-- ============================================================
--  Git  (<leader>g)
-- ============================================================
keymap("n", "]g", "<cmd>lua require('gitsigns').next_hunk()<CR>", { desc = "Next Git Change" })
keymap("n", "[g", "<cmd>lua require('gitsigns').prev_hunk()<CR>", { desc = "Prev Git Change" })
keymap("n", "<leader>gl", "<cmd>lua require('gitsigns').blame_line()<CR>", { desc = "Blame Line" })
keymap("n", "<leader>gp", "<cmd>lua require('gitsigns').preview_hunk()<CR>", { desc = "Preview Change Hunk" })
keymap("n", "<leader>gr", "<cmd>lua require('gitsigns').reset_hunk()<CR>", { desc = "Reset Line Change" })
keymap("n", "<leader>gg", "<cmd>lua LeVIX.lazygit_toggle()<CR>", { desc = "Toggle Lazygit" })

-- ============================================================
--  Code / LSP  (<leader>c)
-- ============================================================
keymap("n", "<leader>cf", function() require("conform").format({ async = true }) end, { desc = "Format File" })
keymap("n", "<leader>cl", function()
	local lint = require("lint")
	local ft = vim.bo.filetype
	local linters = lint.linters_by_ft[ft]
	if not linters then
		return
	end
	local executable_map = { clangtidy = "clang-tidy" }
	for _, name in ipairs(linters) do
		local exe = executable_map[name] or name
		if vim.fn.executable(exe) == 0 then
			vim.notify(
				string.format("LeVIX: linter '%s' not found. Install it for %s files.", exe, ft),
				vim.log.levels.WARN,
				{ title = "LeVIX Linter" }
			)
			return
		end
	end
	lint.try_lint()
end, { desc = "Lint File" })
keymap("n", "<leader>co", "<cmd>AerialToggle<CR>", { desc = "Toggle Outline" })

-- ============================================================
--  Harpoon  (<leader>h)
-- ============================================================
keymap("n", "<leader>ha", function() require("harpoon"):list():add() end, { desc = "Add File to Harpoon" })
keymap("n", "<leader>hh", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, { desc = "Show Harpoon Menu" })
keymap("n", "<C-1>", function() require("harpoon"):list():select(1) end, { desc = "Go to File 1" })
keymap("n", "<C-2>", function() require("harpoon"):list():select(2) end, { desc = "Go to File 2" })
keymap("n", "<C-3>", function() require("harpoon"):list():select(3) end, { desc = "Go to File 3" })
keymap("n", "<C-4>", function() require("harpoon"):list():select(4) end, { desc = "Go to File 4" })

-- ============================================================
--  Terminal  (<leader>t)
-- ============================================================
keymap("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<CR>", { desc = "Terminal Horizontal" })
keymap("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical size=60<CR>", { desc = "Terminal Vertical" })
keymap("n", "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", { desc = "Terminal Float" })

-- ============================================================
--  Debug  (<leader>d)
-- ============================================================
keymap("n", "<F5>", function() require("dap").continue() end, { desc = "Debug: Continue" })
keymap("n", "<F10>", function() require("dap").step_over() end, { desc = "Debug: Step Over" })
keymap("n", "<F11>", function() require("dap").step_into() end, { desc = "Debug: Step Into" })
keymap("n", "<F12>", function() require("dap").step_out() end, { desc = "Debug: Step Out" })
keymap("n", "<leader>db", function() require("dap").toggle_breakpoint() end, { desc = "Toggle Breakpoint" })
keymap("n", "<leader>du", function() require("dapui").toggle() end, { desc = "Toggle Debug UI" })

-- ============================================================
--  File Explorer
-- ============================================================
keymap("n", "<leader>o", "<CMD>Oil<CR>", { desc = "Open Oil File Explorer" })

-- ============================================================
--  Markdown Preview  (<leader>a)
-- ============================================================
keymap("n", "<leader>as", "<cmd>MarkdownPreview<CR>", { desc = "Markdown Start preview" })
keymap("n", "<leader>ap", "<cmd>MarkdownPreviewStop<CR>", { desc = "Markdown Stop preview" })
keymap("n", "<leader>ar", "<cmd>MarkdownPreviewRefresh<CR>", { desc = "Markdown Refresh preview" })

-- ============================================================
--  Live Server  (<leader>l)
-- ============================================================
keymap("n", "<leader>ls", "<cmd>LiveServerStart<cr>", { desc = "Start Live Server" })
keymap("n", "<leader>lo", "<cmd>LiveServerOpen<cr>", { desc = "Open in Browser" })
keymap("n", "<leader>lr", "<cmd>LiveServerReload<cr>", { desc = "Force Reload" })
keymap("n", "<leader>lt", "<cmd>LiveServerToggleLive<cr>", { desc = "Toggle Live Reload" })
keymap("n", "<leader>li", "<cmd>LiveServerStatus<cr>", { desc = "Show Server Status" })
keymap("n", "<leader>lS", "<cmd>LiveServerStop<cr>", { desc = "Stop Server" })
keymap("n", "<leader>lA", "<cmd>LiveServerStopAll<cr>", { desc = "Stop All Servers" })

-- ============================================================
--  Sessions  (<leader>s)
-- ============================================================
keymap("n", "<leader>ss", "<cmd>SessionSave<CR>", { desc = "Save Session" })
keymap("n", "<leader>sr", "<cmd>SessionRestore<CR>", { desc = "Restore Session" })

-- ============================================================
--  Todos  (<leader>m)
-- ============================================================
keymap("n", "<leader>mt", "<cmd>TodoTelescope<CR>", { desc = "Search Project Todos" })
keymap("n", "<leader>ml", "<cmd>TodoLocList<CR>", { desc = "List Local Todos" })

-- ============================================================
--  Theme Switcher  (<leader>T)
-- ============================================================
local theme_cache = vim.fn.stdpath("config") .. "/.levix_theme_cache"
local function save_theme(theme)
	local file = io.open(theme_cache, "w")
	if file then
		file:write(theme)
		file:close()
	end
end

keymap("n", "<leader>T", function()
	local success, builtin = pcall(require, "telescope.builtin")
	if success then
		builtin.colorscheme({
			enable_preview = true,
			previewer = false,
			layout_strategy = "center",
			layout_config = {
				width = 50,
				height = 20,
				prompt_position = "top",
				preview_cutoff = 1,
			},
			attach_mappings = function(_, map)
				map("i", "<CR>", function(prompt_bufnr)
					local actions = require("telescope.actions")
					local action_state = require("telescope.actions.state")
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selection then
						pcall(vim.cmd, "colorscheme " .. selection.value)
						save_theme(selection.value)
					end
				end)
				return true
			end,
		})
	else
		local themes = { "catppuccin", "tokyonight", "gruvbox", "rose-pine", "kanagawa" }
		vim.ui.select(themes, { prompt = " Select LeVIX Theme:" }, function(choice)
			if choice then
				pcall(vim.cmd, "colorscheme " .. choice)
				save_theme(choice)
			end
		end)
	end
end, { desc = "Switch Theme" })

-- ============================================================
--  Zen Mode  (<leader>z)
-- ============================================================
keymap("n", "<leader>z", "<cmd>ZenMode<cr>", { desc = "Toggle Zen Mode" })
