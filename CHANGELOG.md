# Changelog

All notable changes to this dotfiles repo are documented in this file.

## [Unreleased]

### Added
- `bin/theme` — switch Ghostty, tmux, and nvim between Solarized Dark and
  Catppuccin Mocha with a single command. Theme state persists in `~/.config/theme`.
- `starship.toml` — Starship prompt config (git branch/status, command duration).
  Falls back to hand-rolled prompt when Starship is not installed.
- zoxide integration in zshrc (replaces z.sh for directory jumping).
- LazyGit alias (`lg`).
- `dotup` function — pulls latest dotfiles, re-runs install.sh, reloads shell.
  Works in both bash (codespaces) and zsh (local).
- 1Password SSH commit signing — `install.sh` detects `op-ssh-sign` at runtime
  and enables/disables signing accordingly.
- `catppuccin/nvim` plugin (lazy-loaded alongside NeoSolarized).
- Bash integration for codespaces: Starship, zoxide, fzf sourced in `.bashrc`.

### Changed
- **Self-contained**: removed dependency on `thoughtbot/dotfiles` and `rcm`.
  All config files (gitconfig, tmux.conf, aliases, gitignore, gitmessage, zshrc)
  are now maintained directly in this repo.
- `install.sh` rewritten as idempotent symlink installer with `--dry-run` support.
  Works for both local machines and codespaces — no separate code paths.
- `bootstrap-machine` simplified: clones one repo, runs `install.sh`, verifies.
  No longer requires Homebrew or rcm.
- Renamed `*.local` overlay files to standalone names (e.g., `gitconfig.local` → `gitconfig`).

### Removed
- `thoughtbot/dotfiles` dependency (no more `~/dotfiles` base layer).
- `rcm` dependency (replaced by simple symlinks in `install.sh`).
- Vim config (`vimrc.local`, `vimrc.bundles.local`) — Neovim is the sole editor.
- Rails/Ruby aliases (dm, dmr, rc, rss, rgm, rr, be, bundle).
- Heroku aliases and autocomplete.
- `git_template.local/` (ctags hooks).
- `.laptop.local` (thoughtbot laptop script config).
- `z.sh` sourcing (replaced by zoxide).
- VS Code PATH entry.
- Stale Heroku cache paths and old username references.

## [Previous]

### Added
- Tmux copy-mode bindings: mouse drag selects within pane boundaries and copies
  to system clipboard on release via `pbcopy`. Vim-style `v` to select, `y` to yank.
- Enabled tmux mouse support for click-to-focus, drag-to-resize, and scroll.
- `zsh/configs/post/cursor.zsh` to force block cursor on every prompt line.
- `AGENTS.md` with agent-friendly bootstrap and VM rehearsal workflow.
- `bin/bootstrap-machine` for one-command local setup.
- `bin/rdm-connect` for codespace clipboard/open forwarding with tmux pane titles.
- Tmux pane border labels showing codespace name or current path.

### Changed
- Updated shell startup ergonomics and completion wiring.
- Added modular Neovim architecture using lazy.nvim.
- Added `docs/CODESPACES.md` and `bin/codespaces-vim-lab` for Codespaces testing.
