return {
	"williamboman/mason.nvim",
	event = "VeryLazy",
	config = function()
		local ok, registry = pcall(require, "mason-registry")
		if not ok then
			return
		end

		local ensure_installed = {
			"jdtls",
			"java-debug-adapter",
		}

		for _, tool in ipairs(ensure_installed) do
			local pok, pkg = pcall(registry.get_package, tool)
			if pok and not pkg:is_installed() then
				pkg:install()
			end
		end
	end,
}
