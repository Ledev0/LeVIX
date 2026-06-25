return {
	"f3fora/cmp-spell",
	dependencies = { "hrsh7th/nvim-cmp" },
	config = function()
		local cmp = require("cmp")
		local config = cmp.get_config()

		table.insert(config.sources, {
			name = "spell",
			option = {
				keep_all_entries = false,
				enable_in_context = function()
					return true
				end,
			},
		})

		cmp.setup(config)
	end,
}
