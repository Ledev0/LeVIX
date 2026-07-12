local M = {}

local function check_executable(name, hint)
	if vim.fn.executable(name) == 1 then
		vim.health.ok(name .. " found")
	else
		vim.health.error(name .. " not found in PATH", { hint })
	end
end

function M.check()
	vim.health.start("LeVIX — Core Tools")
	check_executable("git", "Required by lazy.nvim")
	check_executable("rg", "Install ripgrep for Telescope search")
	check_executable("fd", "Install fd-find for Telescope file finding")
	check_executable("curl", "Required by mason.nvim")

	vim.health.start("LeVIX — Language Tooling")
	check_executable("java", "Install a JDK >= 17")
	check_executable("python3", "Install Python 3")
	check_executable("ruff", "pip install --user ruff")
	check_executable("gcc", "Required for C compiling")
	check_executable("g++", "Required for C++ compiling")
	check_executable("clang-tidy", "Install clang-tools-extra for linting")

	vim.health.start("LeVIX — Build Requirements")
	check_executable("cargo", "Required to build blink.cmp's fuzzy matcher")
	check_executable("make", "Required for Treesitter parsers")

	vim.health.start("LeVIX — Runtime")
	if vim.fn.has("nvim-0.12") == 1 then
		vim.health.ok("Neovim version >= 0.12")
	else
		vim.health.error("Neovim < 0.12 — LeVIX requires 0.12+")
	end
end

return M
