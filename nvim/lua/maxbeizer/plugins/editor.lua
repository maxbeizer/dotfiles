return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = function()
      if vim.g.maxbeizer_tree_sitter_cli_ok then
        vim.cmd.TSUpdate()
      else
        vim.notify(
          'Skipping TSUpdate: tree-sitter CLI is unavailable or broken',
          vim.log.levels.WARN
        )
      end
    end,
    config = function()
      require('nvim-treesitter').setup()

      local ensure = { 'lua', 'vim', 'vimdoc', 'ruby', 'javascript', 'typescript', 'go', 'json', 'markdown', 'elixir', 'heex', 'erlang' }
      local installed = require('nvim-treesitter').get_installed()
      local installed_set = {}
      for _, lang in ipairs(installed) do
        installed_set[lang] = true
      end
      local missing = {}
      for _, lang in ipairs(ensure) do
        if not installed_set[lang] then
          table.insert(missing, lang)
        end
      end
      if #missing > 0 and vim.g.maxbeizer_tree_sitter_cli_ok then
        require('nvim-treesitter').install(missing)
      elseif #missing > 0 then
        vim.notify(
          'Skipping treesitter parser install: tree-sitter CLI is unavailable or broken',
          vim.log.levels.WARN
        )
      end

      -- Enable treesitter highlighting for all filetypes with an installed parser
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
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
      { '<C-\\>', function() require('telescope.builtin').live_grep() end, desc = 'Live grep' },
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
      telescope.setup({
        defaults = {
          file_ignore_patterns = { '%.git/' },
        },
        pickers = {
          find_files = {
            hidden = true,
          },
        },
      })
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
    'stevearc/oil.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('oil').setup({
        view_options = { show_hidden = true },
        -- open files in the window you came from, not the oil window
        default_file_explorer = false,
      })
      vim.keymap.set('n', '-', '<cmd>Oil<CR>', { desc = 'Open parent directory' })
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
      local theme = 'mocha'
      local f = io.open(theme_file, 'r')
      if f then
        theme = f:read('*l') or 'mocha'
        f:close()
      end

      vim.opt.background = 'dark'
      if theme == 'solarized' then
        pcall(vim.cmd.colorscheme, 'NeoSolarized')
      else
        pcall(vim.cmd.colorscheme, 'catppuccin-mocha')
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

  { 'godlygeek/tabular', cmd = 'Tabularize' },
  {
    'linrongbin16/gitlinker.nvim',
    keys = {
      { '<leader>go', '<cmd>GitLink!<cr>', desc = 'Open on GitHub' },
      { '<leader>go', '<cmd>GitLink!<cr>', mode = 'v', desc = 'Open selection on GitHub' },
    },
    config = function()
      require('gitlinker').setup()
    end,
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = 'BufReadPost',
    config = function()
      require('ibl').setup({
        indent = { char = '│' },
        scope = { enabled = true, show_start = false, show_end = false },
      })
    end,
  },
}
