# Changelog

All notable changes to this dotfiles-local repo are documented in this file.

## [Unreleased]

### Added
- Added `AGENTS.md` with an agent-friendly bootstrap and VM rehearsal workflow.
- Added `bin/bootstrap-machine` for one-command local setup.

### Changed
- Updated shell startup ergonomics and completion wiring in local overlays.
- Disabled GPG commit signing by default in `gitconfig.local`.
- Added modular Neovim architecture using lazy.nvim with split plugin and core modules.
- Added `docs/CODESPACES.md` and `bin/codespaces-vim-lab` for iterative Codespaces Vim/Neovim testing.
- Updated `install.sh` Codespaces flow to use thoughtbot `main` branch and lazy.nvim plugin sync.
