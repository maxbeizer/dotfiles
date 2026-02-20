local map = vim.keymap.set

map('n', '<leader>f', function()
  vim.lsp.buf.format({ async = true })
end)
map({ 'n', 'v' }, '<leader>y', [['_y]])
map('n', '<leader>Y', [['_Y]])
map('n', '<leader>rtw', [[:%s/\s\+$//e<CR>]])
map('n', '<leader>vs', [[:vs <C-r>=expand('%:p:h')<CR>/]])
map('n', '<leader><space>', '<C-^>')

map('n', '<leader>bg', function()
  vim.o.background = vim.o.background == 'dark' and 'light' or 'dark'
end)

map('n', '<C-p>', function()
  require('telescope.builtin').find_files()
end)
map('n', '<C-t>', function()
  require('telescope.builtin').buffers()
end)

map('n', '<C-n>', function()
  local ok, api = pcall(require, 'nvim-tree.api')
  if ok then
    api.tree.toggle()
  end
end)
