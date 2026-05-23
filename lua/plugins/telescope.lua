return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
    },
  },
  config = function()
    require('telescope').setup({
      defaults = {
        file_ignore_patterns = { 'node_modules', '.git' },
      },
    })
    require('telescope').load_extension('fzf')
    require('telescope').setup({
    defaults = {
    file_ignore_patterns = { 'node_modules', '.git' },
    },
        pickers = {
        find_files = {
        hidden = true,        -- show dotfiles
        },
      },
    })

    vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<CR>', { desc = 'Find Files' })
    vim.keymap.set('n', '<leader>fs', '<cmd>Telescope live_grep<CR>', { desc = 'Search Text' })
    vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<CR>', { desc = 'Find Buffers' })
    vim.keymap.set('n', '<leader>fh', '<cmd>Telescope help_tags<CR>', { desc = 'Find Help' })
  end,
}
