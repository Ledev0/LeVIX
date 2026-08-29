-- Import the newweb module
local newweb = require("core.levix.newweb")

-- LeVIXUpdate: Update LeVIX core, plugins, and Treesitter
vim.api.nvim_create_user_command("LeVIXUpdate", function()
	print(" [LeVIX] Starting core empire updates...")
	local has_lazy, lazy = pcall(require, "lazy")
	if has_lazy then
		print(" Updating plugins...")
		lazy.sync({ wait = true })
	end

	print(" Updating Treesitter parsers...")
	local has_ts, ts_install = pcall(require, "nvim-treesitter.install")
	if has_ts then
		ts_install.update({ with_sync = true })
	end

	local handle = io.popen("git -C " .. vim.fn.stdpath("config") .. " pull origin main 2>&1")
	if handle then
		local result = handle:read("*a")
		handle:close()
		if string.find(result, "Already up to date") then
			print(" LeVIX core is already up to date!")
		else
			print("󱓟 Core updated successfully! Please restart Neovim.")
		end
	end
end, {})

-- LeVIXNewWeb: Scaffold a new frontend project
vim.api.nvim_create_user_command("LeVIXNewWeb", function(opts)
	local project_name = opts.args
	newweb.new_web_project(project_name)
end, { nargs = 1, desc = "Scaffold a new frontend project with HTML, CSS, and JavaScript" })

-- Check for LeVIX updates on startup
local function check_for_updates()
	local config_path = vim.fn.stdpath("config")
	vim.fn.jobstart({ "git", "-C", config_path, "fetch", "origin", "main" }, {
		on_exit = function(_, exit_code)
			if exit_code == 0 then
				vim.fn.jobstart({ "git", "-C", config_path, "rev-list", "HEAD...origin/main", "--count" }, {
					stdout_buffered = true,
					on_stdout = function(_, data)
						local count = tonumber(data[1] or "0")
						if count and count > 0 then
							vim.schedule(function()
								vim.notify(
									"✨ New updates available for LeVIX! Run :LeVIXUpdate to pull changes.",
									vim.log.levels.INFO,
									{ title = "LeVIX System", timeout = 10000 }
								)
							end)
						end
					end,
				})
			end
		end,
	})
end

if vim.g.levix_check_updates ~= false then
	vim.defer_fn(function()
		check_for_updates()
	end, 2000)
end
