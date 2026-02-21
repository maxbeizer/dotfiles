local group = vim.api.nvim_create_augroup('MaxBeizerCore', { clear = true })

-- Clear the ALE augroup inherited from base vimrc; LSP handles linting now
vim.api.nvim_create_augroup('ale', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  group = group,
  callback = function()
    vim.highlight.on_yank({ timeout = 120 })
  end,
})

vim.api.nvim_create_autocmd('BufWritePre', {
  group = group,
  pattern = { '*.rb', '*.ex', '*.exs', '*.js' },
  command = [[%s/\s\+$//e]],
})

vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
  group = group,
  pattern = '*',
  callback = function()
    local line = vim.fn.line([[\"]])
    if line > 0 and line <= vim.fn.line('$') then
      vim.cmd('normal! g`"')
    end
  end,
})
