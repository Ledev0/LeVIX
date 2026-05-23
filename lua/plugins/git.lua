-- ~/.config/nvim/lua/plugins/git.lua
return {
  -- Gitsigns: Inline Git diff markers in the gutter & line blame
  {
    'lewis6991/gitsigns.nvim',
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require('gitsigns').setup({
        signs = {
          add          = { text = '┃' },
          change       = { text = '┃' },
          delete       = { text = '_' },
          topdelete    = { text = '‾' },
          changedelete = { text = '~' },
          untracked    = { text = '┆' },
        },
        signcolumn = true,
        watch_gitdir = { follow_files = true },
        auto_attach = true,
        current_line_blame = true, -- Inline VS Code GitLens style blame
        current_line_blame_opts = {
          delay = 500,
          virt_text_pos = 'eol',
        },
      })
      local gs = require('gitsigns')
      -- Register keymaps directly under the <leader>g prefix group
      vim.keymap.set('n', ']g', gs.next_hunk, { desc = 'Next Git Change' })
      vim.keymap.set('n', '[g', gs.prev_hunk, { desc = 'Prev Git Change' })
      vim.keymap.set('n', '<leader>gl', gs.blame_line, { desc = 'Blame Line' })
      vim.keymap.set('n', '<leader>gp', gs.preview_hunk, { desc = 'Preview Change Hunk' })
      vim.keymap.set('n', '<leader>gr', gs.reset_hunk, { desc = 'Reset Line Change' })
        

    end,
  }, 
}
