return {
  {
    'williamboman/mason.nvim',
    config = function()
      require('mason').setup()
    end,
  },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    config = function()
      require('mason-lspconfig').setup({
        ensure_installed = { 'lua_ls', 'ts_ls', 'gopls' },
      })
    end,
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'williamboman/mason-lspconfig.nvim',
    },
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- Servers configured via native vim.lsp.config (nvim 0.11+)
      vim.lsp.config('lua_ls', {
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { 'vim' } },
          },
        },
      })

      vim.lsp.config('ts_ls', { capabilities = capabilities })
      vim.lsp.config('gopls', { capabilities = capabilities })

      local enable = { 'lua_ls', 'ts_ls', 'gopls' }

      if vim.fn.executable('solargraph') == 1 or vim.fn.executable('bin/solargraph') == 1 then
        vim.lsp.config('solargraph', { capabilities = capabilities })
        table.insert(enable, 'solargraph')
      end

      -- gh/gh codespace: use the repo's run-sorbet wrapper with RBI skip
      if vim.fn.filereadable('.vscode/run-sorbet') == 1 then
        vim.lsp.config('sorbet', {
          capabilities = capabilities,
          cmd = { 'env', 'SRB_SKIP_GEM_RBIS=1', '.vscode/run-sorbet', '--lsp' },
        })
        table.insert(enable, 'sorbet')
      elseif vim.fn.executable('srb') == 1 or vim.fn.executable('bin/srb') == 1 then
        vim.lsp.config('sorbet', { capabilities = capabilities })
        table.insert(enable, 'sorbet')
      end

      vim.lsp.enable(enable)

      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
      vim.keymap.set('n', '<leader>vd', vim.diagnostic.open_float)

      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(event)
          local opts = { buffer = event.buf }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', '<leader>vca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', '<leader>vrn', vim.lsp.buf.rename, opts)
          vim.keymap.set('n', '<leader>vws', vim.lsp.buf.workspace_symbol, opts)
          vim.keymap.set('i', '<C-h>', vim.lsp.buf.signature_help, opts)
        end,
      })
    end,
  },
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'rafamadriz/friendly-snippets',
    },
    config = function()
      local cmp = require('cmp')
      require('luasnip.loaders.from_vscode').lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-p>'] = cmp.mapping.select_prev_item(),
          ['<C-n>'] = cmp.mapping.select_next_item(),
          ['<C-y>'] = cmp.mapping.confirm({ select = true }),
          ['<C-Space>'] = cmp.mapping.complete(),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }),
      })
    end,
  },
}
