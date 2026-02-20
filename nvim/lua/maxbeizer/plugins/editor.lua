return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').setup({
        ensure_installed = { 'lua', 'vim', 'vimdoc', 'ruby', 'javascript', 'typescript', 'go', 'json', 'markdown' },
      })
    end,
  },
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable('make') == 1
        end,
      },
    },
    config = function()
      local telescope = require('telescope')
      telescope.setup({})
      pcall(telescope.load_extension, 'fzf')
    end,
  },
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('nvim-tree').setup({
        update_focused_file = { enable = true },
        view = { width = 36 },
      })
    end,
  },
  {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end,
  },
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup()
    end,
  },
  {
    'nvim-lualine/lualine.nvim',
    config = function()
      require('lualine').setup({
        options = {
          component_separators = '|',
          section_separators = '',
        },
      })
    end,
  },
  { 'github/copilot.vim' },
}
