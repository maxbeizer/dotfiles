# Changelog

All notable changes to this dotfiles-local repo are documented in this file.

## [Unreleased]

### Added
- Added `zsh/configs/post/cursor.zsh` to force a block (fat) cursor on every
  new prompt line, overriding vi-mode's default beam cursor.
- Added `AGENTS.md` with an agent-friendly bootstrap and VM rehearsal workflow.
- Added `bin/bootstrap-machine` for one-command local setup.
- Added `bin/rdm-connect` script to replace `gh rdm-connect` alias. Connects to
  a codespace with gh-rdm clipboard/open forwarding and auto-sets the tmux pane
  border title to `🚀 <codespace-name>` so you always know which codespace each
  pane is connected to. Supports interactive fzf picker or direct name argument.
- Added tmux pane border labels in `tmux.conf.local` — shows codespace name
  (via pane title) when SSH'd in, falls back to current path for local panes.

### Changed
- Updated shell startup ergonomics and completion wiring in local overlays.
- Disabled GPG commit signing by default in `gitconfig.local`.
- Added modular Neovim architecture using lazy.nvim with split plugin and core modules.
- Added `docs/CODESPACES.md` and `bin/codespaces-vim-lab` for iterative Codespaces Vim/Neovim testing.
- Updated `install.sh` Codespaces flow to use thoughtbot `main` branch and lazy.nvim plugin sync.
