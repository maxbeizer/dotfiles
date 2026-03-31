# Changelog

Notable changes to this dotfiles repo, newest first.

## 2026-03-31

### Changed
- `rdm-connect` now uses the `tv codespaces` channel instead of fzf, showing
  branch, repo, and state inline with a rich preview pane
- `tv codespaces`: Enter now SSHes into the selected codespace (same as ctrl-s)

## 2026-03-29

### Added
- sesh: `prefix L` quick-toggles last session (`sesh last`) — like `cd -` for tmux
- sesh: `prefix R` jumps to project root via `sesh root`
- sesh: `ctrl-g` in picker prompts for a git URL to `sesh clone` into a session
- sesh: picker now shows nerd font icons (`--icons`) and hides attached/duplicate
  sessions for a cleaner list

### Changed
- Default theme switched from Solarized Dark to Catppuccin Mocha. Solarized
  remains available via `theme solarized`. Affects `bin/theme` fallback,
  `tmux.conf` baseline colors, and Neovim colorscheme default.

## 2026-03-24

### Added
- Git aliases `gone` and `tidy` for branch cleanup. `gone` deletes local
  branches whose upstream tracking branch no longer exists (squash-merged PRs).
  `tidy` combines both merged-branch cleanup and gone-upstream cleanup in one
  command — fetch, prune, delete merged, delete gone, done.
- Copilot CLI skills managed via dotfiles — `grill-me`, `mikado`, and
  `agent-orchestration` now live in `copilot/skills/` and are symlinked to
  `~/.copilot/skills/` by `install.sh`. New skills added to this directory are
  automatically linked on next install.
- Elixir LSP support — `elixir-ls` auto-installed via Mason and unconditionally
  enabled (Mason manages the binary). Treesitter grammars for `elixir`, `heex`,
  and `erlang` added to `ensure_installed`.

### Fixed
- Treesitter — removed duplicate plugin spec in `editor.lua` that was overriding
  `ensure_installed` with empty opts. Rewrote config for new nvim-treesitter API
  (nvim 0.11+) which no longer supports `ensure_installed` in `setup()`. Parsers
  are now auto-installed by comparing against `get_installed()`. Added `FileType`
  autocmd to enable treesitter highlighting for all filetypes with an installed
  parser (nvim 0.11 only auto-enables it for lua, help, and query).
- LSP — disabled mason-lspconfig `automatic_enable` to prevent duplicate server
  launches (elixir-ls was starting twice).
- `tv gh-notifications` — rebind unsubscribe from `ctrl-m` to `ctrl-g`. `ctrl-m`
  is interpreted as Enter in terminals, and `ctrl-u` is a built-in tv keybinding
  (clear input line), so neither worked for custom actions.

## 2026-03-22

### Changed
- `bin/sesh-picker` — 🔔 indicators now check `window_bell_flag` per-window
  instead of `session_alerts`, so activity (terminal output) no longer triggers
  false bells. Only actual terminal bells (e.g., Copilot waiting for input) show 🔔.
  Sessions are now sorted by most recently visited (via `session_last_attached`).
- Copilot CLI hooks — switched `ask_user` detection from `postToolUse` to
  `preToolUse` so the bell fires when Copilot *starts* waiting, not after
  the user has already answered. Hooks now also send a tmux terminal bell
  alongside the cmux desktop notification.

### Added
- `sesh` integration — tmux session manager with zoxide project discovery.
  Named sessions configured in `sesh/sesh.toml`. Replaces tmuxinator for
  most workflows.
- `bin/sesh-picker` — session picker with 🔔 bell indicators sorted to the
  top, preview via `sesh preview`, ctrl-d to remove sessions.
- `tome` alias — start main tmux session directly from a fresh terminal.
- `television` cable channels for fuzzy picking:
  - `gh-issues` / `gh-prs` — browse with metadata + markdown preview (bat)
  - `gh-notifications` — triage with done (ctrl-e), unsubscribe (ctrl-g),
    mark read (ctrl-d), open (ctrl-o). Matches GitHub web UI keybindings.
  - `my-prs` — all open PRs across repos (like github.com/pulls)
  - `codespaces` — manage codespaces with friendly names, SSH via rdm-connect
  - `processes` — sort by CPU, ctrl-k to send SIGTERM
  - `tldr` — browse command help pages with preview
  - `brew-packages` — installed formulas + casks, upgrade/uninstall
  - `channels` — meta-channel to browse all channels
  Configs live in `television/cable/` and are symlinked by `install.sh`.
- `glow` added to Brewfile for markdown rendering in tv previews.
- `EDITOR`/`VISUAL` set to `nvim` in zshrc.
- Starship git_status: `stashed = "≡${count}"` — shows stash count instead
  of confusing bare `$`.
- tmux: `bind-key x kill-pane` (skip confirmation), `detach-on-destroy off`
  (stay in tmux when closing a session).
- `bin/theme` now also switches television theme (catppuccin ↔ solarized-dark).

### Changed
- `prefix S` now opens `bin/sesh-picker` (sesh + fzf with bell indicators).
- `prefix W` removed (sessions consolidated into prefix S).
- `install.sh` now symlinks sesh and television cable configs.

### Removed
- tmuxinator configs for ghae, flags, memex, dotcom, tome (replaced by sesh).
- `bin/tmux-nav` sessions mode (replaced by `bin/sesh-picker`).

## 2026-03-21

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

## 2026-03-21 (earlier)

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
