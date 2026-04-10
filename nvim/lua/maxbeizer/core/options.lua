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

-- Ensure homebrew binaries are on PATH (for tree-sitter, etc.)
if vim.fn.isdirectory('/opt/homebrew/bin') == 1 and not vim.env.PATH:find('/opt/homebrew/bin') then
  vim.env.PATH = '/opt/homebrew/bin:' .. vim.env.PATH
end

-- indentation defaults
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true

-- show indent guides
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Ensure gh/gh vendored Node is on PATH for copilot.vim and LSPs
local vendored_node = '/workspaces/github/vendor/node'
if vim.fn.isdirectory(vendored_node) == 1 then
  vim.env.PATH = vendored_node .. ':' .. vendored_node .. '/bin:' .. vim.env.PATH
  vim.g.copilot_node_command = vendored_node .. '/node'
else
  -- Locally, asdf's node has node:sqlite support that copilot-language-server
  -- requires; Homebrew's node (which nvim may find first) does not.
  local asdf_node = vim.fn.expand('~/.asdf/shims/node')
  if vim.fn.executable(asdf_node) == 1 then
    vim.g.copilot_node_command = asdf_node
  end
end

-- Use bundled language server instead of npx (avoids registry auth issues)
vim.g.copilot_npx = false
