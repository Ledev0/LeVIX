-- Distro Updater
vim.api.nvim_create_user_command("LeVIXUpdate", function()
	print(" [LeVIX] Starting core empire updates...")

	local has_lazy, lazy = pcall(require, "lazy")
	if has_lazy then
		print(" Updating plugins...")
		lazy.sync({ wait = true })
	end

	print("🌳 Updating Treesitter parsers...")
	local has_ts, ts_install = pcall(require, "nvim-treesitter.install")
	if has_ts then
		ts_install.update({ with_sync = true })
	else
		pcall(vim.cmd, "TSUpdate")
	end

	local handle = io.popen("git -C " .. vim.fn.stdpath("config") .. " pull origin main 2>&1")
	if handle then
		local result = handle:read("*a")
		handle:close()
		if string.find(result, "Already up to date") then
			print(" LeVIX core is already up to date!")
		else
			print("󱓟 Core updated successfully! Please restart Neovim.")
		end
	end
end, {})
