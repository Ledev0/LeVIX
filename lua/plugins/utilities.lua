-- ~/.config/nvim/lua/plugins/utilities.lua
return {
  -- Auto pairs: automatically closes brackets, quotes, and parens
  {
    'windwp/nvim-autopairs',
    event = "InsertEnter",
    config = function()
      require('nvim-autopairs').setup({
        check_ts = true, -- Enable Treesitter integration
        ts_config = {
          lua = { 'string' }, -- Don't add pairs in lua string treesitter nodes
          java = { 'string_literal' }, -- Don't add pairs in java string literals
        }
      })
    end
  },

  -- Comment.nvim: Smart and powerful commenting using treesitter
  {
    'numToStr/Comment.nvim',
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require('Comment').setup()
    end
  },
}
