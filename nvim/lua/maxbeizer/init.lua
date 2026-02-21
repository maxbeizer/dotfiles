local M = {}

local function bootstrap_lazy()
  local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      'git',
      'clone',
      '--filter=blob:none',
      'https://github.com/folke/lazy.nvim.git',
      '--branch=stable',
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)
end

function M.setup()
  vim.g.mapleader = vim.g.mapleader or ','
  vim.g.maplocalleader = vim.g.maplocalleader or ','

  bootstrap_lazy()

  require('maxbeizer.core.options')
  require('maxbeizer.core.autocmds')
  require('maxbeizer.core.keymaps')

  require('lazy').setup({
    { import = 'maxbeizer.plugins' },
  }, {
    change_detection = { notify = false },
    checker = { enabled = false },
  })
end

return M
