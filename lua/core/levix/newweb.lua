local M = {}

-- Validate JSON syntax
local function validate_json(content, filename)
	local ok, result = pcall(function()
		vim.fn.json_decode(content)
	end)
	if not ok then
		vim.notify(
			string.format("❌ Invalid JSON in %s: %s", filename, result),
			vim.log.levels.ERROR,
			{ title = "LeVIX New Web" }
		)
		return false
	end
	return true
end

-- Validate HTML structure
local function validate_html(content)
	if not string.match(content, "<!DOCTYPE") then
		vim.notify(
			"⚠️  Warning: index.html may not be valid HTML5 (missing <!DOCTYPE>)",
			vim.log.levels.WARN,
			{ title = "LeVIX New Web" }
		)
	end
	return true
end

-- Check if npm package is installed globally
local function check_npm_dependency(package_name, install_hint)
	if vim.fn.executable("npm") == 0 then
		return false, "npm not found in PATH"
	end

	local handle = io.popen("npm list -g " .. package_name .. " 2>/dev/null | grep -q " .. package_name)
	if not handle then
		return false, install_hint
	end
	local ok, _, code = handle:close()
	return code == 0, install_hint
end

-- Copy a template file from template_dir to the project directory
local function copy_template(template_dir, template_name, dest_path)
	local template_file = template_dir .. "/" .. template_name
	local dest_file = dest_path .. "/" .. template_name

	if not vim.fn.filereadable(template_file) then
		vim.notify(
			string.format("❌ Template not found: %s", template_file),
			vim.log.levels.ERROR,
			{ title = "LeVIX New Web" }
		)
		return false
	end

	local content = vim.fn.readfile(template_file)
	vim.fn.writefile(content, dest_file)

	return true
end

-- Print a formatted summary of the created project
local function print_summary(project_name, project_path, project_type, npm_setup_needed, npm_command)
	local summary = {
		"",
		"════════════════════════════════════════════",
		"✨ " .. project_type .. " Project Created Successfully!",
		"════════════════════════════════════════════",
	}

	if npm_setup_needed then
		table.insert(summary, "⚠️  Additional setup required:")
		table.insert(summary, "   " .. npm_command)
		table.insert(summary, "")
	end

	table.insert(summary, "✍️  LeVIX features enabled in this project:")
	table.insert(summary, "   • Press <C-y>, for Emmet abbreviations")
	table.insert(summary, "   • <leader>cf to format file on save")
	table.insert(summary, "   • <leader>cl to lint file")
	table.insert(summary, "   • gd/gr/K for LSP navigation")
	table.insert(summary, "")
	table.insert(
		summary,
		"═══════════════════════════════════════════════════════════════════════════════"
	)
	table.insert(summary, "")

	for _, line in ipairs(summary) do
		print(line)
	end
end

-- Generic project scaffold from a template directory.
-- template_dir: absolute path to the template directory (e.g. stdpath("config") .. "/templates/frontend")
-- project_name: name of the new project directory
-- project_type: human-readable type label (e.g. "Frontend")
-- files_to_copy: list of filenames to copy from the template directory
-- returns boolean (success)
function M.new_from_template(template_dir, project_name, project_type, files_to_copy)
	if not project_name or project_name == "" then
		vim.notify("❌ Usage: :LeVIXNew<type> <project-name>", vim.log.levels.ERROR, {
			title = "LeVIX New " .. project_type,
		})
		return false
	end

	local cwd = vim.fn.getcwd()
	local project_path = cwd .. "/" .. project_name

	if vim.fn.isdirectory(project_path) == 1 then
		vim.notify(
			string.format("❌ Directory already exists: %s", project_path),
			vim.log.levels.ERROR,
			{ title = "LeVIX New " .. project_type }
		)
		return false
	end

	print(string.format(" [LeVIX] Creating %s project: %s", project_type, project_name))

	vim.fn.mkdir(project_path, "p")
	print(string.format(" [LeVIX] Created directory: %s", project_path))

	local all_copied = true
	for _, file in ipairs(files_to_copy) do
		if not copy_template(template_dir, file, project_path) then
			all_copied = false
		end
	end

	if not all_copied then
		vim.notify(
			"❌ Failed to copy some templates. Check templates directory.",
			vim.log.levels.ERROR,
			{ title = "LeVIX New " .. project_type }
		)
		return false
	end

	-- Validate JSON files
	local json_files = { ".prettierrc.json", ".eslintrc.json", ".stylelintrc.json", "package.json" }
	local validation_passed = true
	for _, file in ipairs(json_files) do
		local file_path = project_path .. "/" .. file
		if vim.fn.filereadable(file_path) == 1 then
			local content = table.concat(vim.fn.readfile(file_path), "\n")
			if not validate_json(content, file) then
				validation_passed = false
			end
		end
	end

	-- Validate HTML if index.html was copied
	local html_path = project_path .. "/index.html"
	if vim.fn.filereadable(html_path) == 1 then
		local html_content = table.concat(vim.fn.readfile(html_path), "\n")
		validate_html(html_content)
	end

	-- Validate starter files exist
	for _, file in ipairs(files_to_copy) do
		local file_path = project_path .. "/" .. file
		if vim.fn.filereadable(file_path) == 0 then
			vim.notify(
				string.format("❌ File not created: %s", file),
				vim.log.levels.ERROR,
				{ title = "LeVIX New " .. project_type }
			)
			validation_passed = false
		end
	end

	if not validation_passed then
		vim.notify("❌ File validation failed", vim.log.levels.ERROR, { title = "LeVIX New " .. project_type })
		return false
	end

	-- Check stylelint-config-standard only for frontend projects
	local npm_needed = false
	local npm_command = ""
	if project_type == "Frontend" then
		local stylelint_ok, stylelint_hint =
			check_npm_dependency("stylelint-config-standard", "npm install -g stylelint-config-standard")
		if not stylelint_ok then
			npm_needed = true
			npm_command = "npm install -g stylelint-config-standard"
			vim.notify("⚠️  " .. stylelint_hint, vim.log.levels.WARN, { title = "LeVIX New " .. project_type .. " - Optional" })
		end
	end

	vim.cmd("cd " .. project_path)
	vim.cmd("Oil")

	print_summary(project_name, project_path, project_type, npm_needed, npm_command)
	return true
end

-- Scaffold a frontend project from templates/frontend/
function M.new_web_project(project_name)
	local template_dir = vim.fn.stdpath("config") .. "/templates/frontend"
	local files = {
		"index.html",
		"style.css",
		"script.js",
		"package.json",
		".prettierrc.json",
		".eslintrc.json",
		".stylelintrc.json",
		".gitignore",
	}
	return M.new_from_template(template_dir, project_name, "Frontend", files)
end

return M
