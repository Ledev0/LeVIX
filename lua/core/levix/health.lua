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
	check_executable("unzip", "Required by mason.nvim downloads")

	vim.health.start("LeVIX — Language Tooling")
	check_executable("java", "Install a JDK >= 17")
	check_executable("python3", "Install Python 3")
	check_executable("ruff", "pip install --user ruff")
	check_executable("gcc", "Required for C compiling")
	check_executable("g++", "Required for C++ compiling")
	check_executable("clang-tidy", "Install clang-tools-extra for linting")

	vim.health.start("LeVIX — Web Development Tools")
	check_executable("prettier", "npm install -g prettier")
	check_executable("htmlhint", "npm install -g htmlhint")
	check_executable("stylelint", "npm install -g stylelint")
	check_executable("eslint_d", "npm install -g eslint_d")

	vim.health.start("LeVIX — Build Requirements")
	check_executable("make", "Required for telescope-fzf-native and Treesitter parsers")

	vim.health.start("LeVIX — C++ Build")
	if vim.fn.executable("cmake") == 1 then
		vim.health.ok("cmake found")
	else
		vim.health.warn("cmake not found — CMake projects unavailable (single-file still works)")
	end
	if vim.fn.executable("ninja") == 1 then
		vim.health.ok("ninja found (preferred CMake generator)")
	else
		vim.health.info("ninja not found — CMake falls back to the default generator")
	end
	local ok_build, cpp_build = pcall(require, "core.levix.cpp.build")
	if not ok_build then
		vim.health.error("core.levix.cpp.build failed to load: " .. tostring(cpp_build))
	else
		local compiler = cpp_build.find_compiler()
		if compiler then
			vim.health.ok("C++ compiler: " .. compiler)
		else
			vim.health.error("no C++ compiler found", { "Install g++ or clang++" })
		end
		local c_compiler = cpp_build.find_compiler_for("c")
		if c_compiler then
			vim.health.ok("C compiler: " .. c_compiler)
		else
			vim.health.warn("no C compiler found", { "Install gcc or clang (needed for .c files)" })
		end
	end
	local ok_clangd, cpp_clangd = pcall(require, "core.levix.cpp.clangd")
	if not ok_clangd then
		vim.health.error("core.levix.cpp.clangd failed to load: " .. tostring(cpp_clangd))
	else
		local clangd = cpp_clangd.resolve_executable()
		if clangd then
			vim.health.ok("clangd: " .. clangd)
		else
			vim.health.warn("clangd not found", { "Install clangd (system package or Mason)" })
		end
	end

	vim.health.start("LeVIX — C++ Debug")
	do
		local ok_mason, mason_registry = pcall(require, "mason-registry")
		local codelldb_bin = nil
		if ok_mason then
			local ok_pkg, pkg = pcall(mason_registry.get_package, "codelldb")
			if ok_pkg and pkg:is_installed() then
				codelldb_bin = pkg:get_install_path() .. "/extension/adapter/codelldb"
			end
		end
		if codelldb_bin and vim.fn.executable(codelldb_bin) == 1 then
			vim.health.ok("codelldb: " .. codelldb_bin)
		else
			vim.health.warn("codelldb not available", { "Run :Mason and install codelldb for :LeVIXCppDebug" })
		end
	end

	vim.health.start("LeVIX — Runtime")
	if vim.fn.has("nvim-0.12") == 1 then
		vim.health.ok("Neovim version >= 0.12")
	else
		vim.health.error("Neovim < 0.12 — LeVIX requires 0.12+")
	end
end

return M
