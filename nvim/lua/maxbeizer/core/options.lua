vim.opt.number = true
vim.opt.mouse = 'a'
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 15
vim.opt.updatetime = 250
vim.opt.signcolumn = 'yes'
vim.opt.termguicolors = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.completeopt = 'menuone,noselect'

-- Ensure gh/gh vendored Node is on PATH for copilot.vim and LSPs
local vendored_node = '/workspaces/github/vendor/node'
if vim.fn.isdirectory(vendored_node) == 1 then
  vim.env.PATH = vendored_node .. ':' .. vendored_node .. '/bin:' .. vim.env.PATH
  vim.g.copilot_node_command = vendored_node .. '/node'
end
