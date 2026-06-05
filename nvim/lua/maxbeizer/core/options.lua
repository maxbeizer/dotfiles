vim.opt.number = true
vim.opt.mouse = 'a'
vim.opt.wrap = false
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 15
vim.opt.updatetime = 250
vim.opt.signcolumn = 'yes'
vim.opt.termguicolors = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.completeopt = 'menuone,noselect'

local function prepend_path(dir)
  if vim.fn.isdirectory(dir) == 1 and not vim.env.PATH:find(dir, 1, true) then
    vim.env.PATH = dir .. ':' .. vim.env.PATH
  end
end

-- Prefer package-manager binaries over Node-installed shims (tree-sitter, etc.).
prepend_path('/home/linuxbrew/.linuxbrew/bin')
prepend_path(vim.fn.expand('~/.linuxbrew/bin'))
prepend_path(vim.fn.expand('~/.cargo/bin'))
prepend_path(vim.fn.expand('~/.local/bin'))
prepend_path('/opt/homebrew/bin')

local function tree_sitter_works()
  local result = vim.system({ 'tree-sitter', '--version' }, { text = true }):wait()
  return result.code == 0
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
  prepend_path('/home/linuxbrew/.linuxbrew/bin')
  prepend_path(vim.fn.expand('~/.linuxbrew/bin'))
  prepend_path(vim.fn.expand('~/.cargo/bin'))
  prepend_path(vim.fn.expand('~/.local/bin'))
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

vim.g.maxbeizer_tree_sitter_cli_ok = vim.fn.executable('tree-sitter') == 1 and tree_sitter_works()
if vim.fn.executable('tree-sitter') == 1 and not vim.g.maxbeizer_tree_sitter_cli_ok then
  vim.notify(
    'tree-sitter CLI is present but failed to run; install it via brew or cargo, not npm',
    vim.log.levels.WARN
  )
end
