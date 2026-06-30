return {
    "rmagatti/auto-session",
    lazy = false,
    opts = {
        auto_restore = false,
        suppressed_dirs = { "~/", "~/Downloads", "/" },
        session_lens = { load_on_setup = false },
    },
    keys = {
        { "<leader>ss", "<cmd>SessionSave<CR>", desc = "Save Session" },
        { "<leader>sr", "<cmd>SessionRestore<CR>", desc = "Restore Session" },
    },
}
