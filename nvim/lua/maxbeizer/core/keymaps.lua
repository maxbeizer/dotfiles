local map = vim.keymap.set

map('n', '<leader>f', function()
  vim.lsp.buf.format({ async = true })
end)
map({ 'n', 'v' }, '<leader>y', [['_y]])
map('n', '<leader>Y', [['_Y]])
map('n', '<leader>rtw', [[:%s/\s\+$//e<CR>]])
map('n', '<leader>vs', function()
  local dir = vim.fn.expand('%:p:h')
  vim.cmd('vsplit')
  require('oil').open(dir)
end, { desc = 'Split right + browse dir with Oil' })
map('n', '<leader><space>', '<C-^>')
map('n', '<space><space>', '<C-^>', { desc = 'Toggle last buffer' })

map('n', '<leader>bg', function()
  vim.o.background = vim.o.background == 'dark' and 'light' or 'dark'
end)

map('n', '<leader>tw', function()
  vim.wo.wrap = not vim.wo.wrap
  vim.wo.linebreak = vim.wo.wrap
  print('wrap ' .. (vim.wo.wrap and 'on' or 'off'))
end, { desc = 'Toggle line wrap' })

-- Telescope and nvim-tree keymaps are defined in their lazy.nvim `keys` specs
