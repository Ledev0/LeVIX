return {
	"rmagatti/auto-session",
	-- Lazy: only needed for manual save/restore commands. Auto-save on exit is
	-- therefore disabled (it needs the plugin loaded at startup) — matches the
	-- manual <leader>ss/<leader>sr workflow.
	cmd = { "AutoSession" },
	opts = {
		auto_save = false,
		auto_restore = false,
		suppressed_dirs = { "~/", "~/Downloads", "/" },
		session_lens = { load_on_setup = false },
	},
}
