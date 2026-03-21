return {
  {
    'nvim-treesitter/nvim-treesitter',
    event = 'BufReadPost',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').setup({
        ensure_installed = { 'lua', 'vim', 'vimdoc', 'ruby', 'javascript', 'typescript', 'go', 'json', 'markdown' },
      })
    end,
  },
  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    keys = {
      { '<C-p>', function() require('telescope.builtin').find_files() end, desc = 'Find files' },
      { '<C-t>', function() require('telescope.builtin').buffers() end, desc = 'Buffers' },
      { '\\', function() require('telescope.builtin').live_grep() end, desc = 'Live grep' },
    },
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
    cmd = { 'NvimTreeToggle', 'NvimTreeFindFile' },
    keys = {
      { '<C-n>', '<cmd>NvimTreeToggle<CR>', desc = 'Toggle file tree' },
    },
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
    event = 'BufReadPost',
    config = function()
      require('Comment').setup()
    end,
  },
  {
    'lewis6991/gitsigns.nvim',
    event = 'BufReadPost',
    config = function()
      require('gitsigns').setup()
    end,
  },
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    config = function()
      require('lualine').setup({
        options = {
          component_separators = '|',
          section_separators = '',
        },
      })
    end,
  },
  {
    'iCyMind/NeoSolarized',
    lazy = false,
    priority = 1000,
  },
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,
    priority = 1000,
    config = function()
      -- Read theme from ~/.config/theme (set by bin/theme)
      local theme_file = vim.fn.expand('~/.config/theme')
      local theme = 'solarized'
      local f = io.open(theme_file, 'r')
      if f then
        theme = f:read('*l') or 'solarized'
        f:close()
      end

      vim.opt.background = 'dark'
      if theme == 'mocha' then
        pcall(vim.cmd.colorscheme, 'catppuccin-macchiato')
      else
        pcall(vim.cmd.colorscheme, 'NeoSolarized')
      end
    end,
  },
  {
    'mbbill/undotree',
    keys = {
      { '<leader>u', vim.cmd.UndotreeToggle, desc = 'Toggle Undotree' },
    },
  },
  { 'github/copilot.vim', event = 'InsertEnter' },
  { 'tpope/vim-abolish', event = 'BufReadPost' },
}
