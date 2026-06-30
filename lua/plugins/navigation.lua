return {
    {
        "folke/flash.nvim",
        keys = {
            { "<leader>jj", mode = { "n" }, desc = "Flash Motion" },
            { "<leader>js", mode = { "n" }, desc = "Flash Treesitter" },
            { "s", mode = { "n", "x", "o" }, desc = "Flash" },
        },
        opts = {
            labels = "asdfghjklqwertyuiopzxcvbnm",
            search = { mode = "exact" },
        },
        config = function(_, opts)
            require("flash").setup(opts)
        end,
    },
}
