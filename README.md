# dotfiles

Self-contained personal dotfiles. No external base layer — everything lives in this repo.

## What's here

```
.
├── install.sh                # Idempotent installer (local + codespaces)
├── bin/
│   ├── bootstrap-machine     # One-command fresh machine setup
│   ├── sesh-picker           # Session picker with 🔔 bell indicators
│   ├── theme                 # Switch between solarized dark ↔ catppuccin mocha
│   ├── codespaces-vim-lab    # Codespaces helper for Vim/Neovim testing
│   └── rdm-connect           # Connect to codespace with clipboard forwarding
│
├── aliases                   # Shell aliases (git, gh, misc)
├── gitconfig                 # Git identity, aliases, SSH signing (1Password)
├── gitignore                 # Global gitignore
├── gitmessage                # Commit message template
├── zshrc                     # Zsh config (Starship prompt, fzf, zoxide, PATH)
├── zshenv.local              # Env vars loaded before zshrc
├── zsh/
│   ├── configs/post/         # Completion, cursor settings
│   └── functions/            # ghcr, ghcrl (Copilot CLI session resume)
│
├── tmux.conf                 # Tmux: C-a prefix, vim keys, mouse, sesh sessions
├── starship.toml             # Starship prompt config
├── ghostty/config            # Ghostty terminal (theme, font, keybinds)
├── sesh/sesh.toml            # sesh session manager config
├── television/cable/         # Television custom cable channels
│
├── nvim.local                # Neovim init (loads Lua modules)
├── nvim/lua/                 # Neovim Lua config (lazy.nvim plugins)
│
├── gemrc                     # Gem defaults (skip docs)
├── ripgreprc                 # Ripgrep defaults
├── codespaces.local          # Codespace-specific bash setup + dotup function
└── install-gh-extensions.sh  # gh CLI extensions (idempotent)
```

## Fresh machine setup

```bash
git clone https://github.com/maxbeizer/dotfiles.git ~/dotfiles
~/dotfiles/bin/bootstrap-machine
~/dotfiles/install-gh-extensions.sh
```

`bootstrap-machine` clones the repo (if needed), runs `install.sh`, and verifies the shell starts cleanly. Supports `--dry-run` and `--skip-verify`.

## Codespaces

When `$CODESPACES` is set, `install.sh` also:
- Wires up bash with aliases, Starship, zoxide, and fzf
- Links codespaces.local for the `dotup` and `codespace` functions
- Installs Copilot CLI (when `$GITHUB_TOKEN` is available)

To iterate on config changes in a codespace:

```bash
dotup    # pull, reinstall, reload shell
```

## Theme switching

Switch between Solarized Dark and Catppuccin Mocha across Ghostty, tmux, nvim, and television:

```bash
theme solarized   # or: theme mocha
theme              # show current
```

Ghostty auto-reloads; tmux and nvim update live.

## Session management (sesh + fzf)

`sesh` manages tmux sessions with automatic project discovery via zoxide.
`fzf` provides the fuzzy picker with previews. Sessions with pending bells (🔔) float to the top.

### Daily workflow

```bash
# After a reboot or fresh terminal:
tome                    # Start your main session directly
# Then use prefix S to pick/create more sessions

# Inside tmux:
prefix S                # Session picker (fuzzy search, preview, 🔔 indicators)
prefix s                # Default tmux session list (tree view)
prefix Ctrl-s           # Save all sessions (tmux-resurrect)
prefix Ctrl-r           # Restore sessions after reboot
```

### Session picker keybindings (prefix S)

| Key | Action |
|-----|--------|
| `Enter` | Connect to selected session |
| `ctrl-d` | Remove selected session and reload list |
| Type to filter | Fuzzy search across all sessions |

Sessions with a 🔔 (bell/notification) are sorted to the top — useful for spotting
when Copilot CLI or a background process needs attention.

### sesh configuration

Session config lives in `sesh/sesh.toml`. Named sessions connect to specific repos;
everything else is discovered via zoxide history. `dir_length = 2` keeps session
names short (e.g., `github/memex` instead of the full path).

To add a project to the session list, either:
- Add a `[[session]]` entry in `sesh/sesh.toml` for pinned projects
- Visit the directory with `z` or `cd` — zoxide adds it automatically
- Seed directories in bulk: `for d in ~/code/myorg/*; do zoxide add "$d"; done`

### After a reboot

1. Open Ghostty
2. `tome` — starts your main session
3. `prefix S` — pick additional sessions as needed
4. Or: `tmux` → `prefix Ctrl-r` — resurrect restores everything

## Television channels

[Television](https://github.com/alexpasmantier/television) is a fuzzy picker with
preview panels and custom actions. Custom cable channels live in `television/cable/`
and are symlinked to `~/.config/television/cable/` by `install.sh`.

Run channels from any terminal with `tv <channel>`, or use `tv channels` to browse.

| Channel | Command | Description |
|---------|---------|-------------|
| `tv gh-issues` | Issue browser | Open issues with metadata + markdown preview |
| `tv gh-prs` | PR browser | Open PRs with diff stats + markdown preview |
| `tv gh-notifications` | Notification triage | Preview, open, mark read, done, unsubscribe |
| `tv processes` | Process manager | Sort by CPU, ctrl-k to send SIGTERM |
| `tv tldr` | TLDR pages | Browse command help with preview |
| `tv brew-packages` | Brew packages | Installed formulas + casks, upgrade/uninstall |
| `tv channels` | Channel picker | Browse and launch tv channels |

### Notification triage (tv gh-notifications)

Mirrors GitHub web UI keybindings:

| Key | Action |
|-----|--------|
| `ctrl-o` | Open in browser |
| `ctrl-d` | Mark as read |
| `ctrl-e` | Done (dismiss) |
| `ctrl-m` | Unsubscribe |
| `ctrl-x` | Action picker (see all actions) |

### Shell integration (ctrl-t)

Television also integrates with your shell. Press `ctrl-t` while typing a command
to fuzzy-pick arguments. Channel triggers are configured in `~/.config/television/config.toml`:

- `git checkout` + `ctrl-t` → pick from branches
- `cd` + `ctrl-t` → pick from directories
- `nvim` + `ctrl-t` → pick from git repos
- `git add` + `ctrl-t` → pick from changed files

## Tmux keybindings

Prefix is `Ctrl-a`.

| Keybinding | Action |
|------------|--------|
| `prefix S` | Session picker (sesh + fzf with 🔔 indicators) |
| `prefix s` | Default session list (tree view) |
| `prefix x` | Kill pane (no confirmation) |
| `prefix Ctrl-s` | **Save** all sessions (tmux-resurrect) |
| `prefix Ctrl-r` | **Restore** sessions after reboot |
| `prefix I` | Install/update tmux plugins (TPM) |
| `prefix h/j/k/l` | Navigate panes (vim-style) |
| `prefix M-Arrow` | Resize panes |

### After a reboot
1. Open a terminal
2. `tome` — starts your main session
3. `prefix S` — pick additional sessions
4. Or: `tmux` → `prefix Ctrl-r` — resurrect restores everything

## Key aliases

| Alias | Command |
|-------|---------|
| `tome` | Start tome tmux session via sesh |
| `g` | `git` |
| `gs` | `git status -b -s` |
| `lg` | `lazygit` |
| `ghpr` | `gh pr create --fill` |
| `ghpv` | `gh pr view --web` |
| `speedtest` | `networkQuality` |

## Git aliases

| Alias | Description |
|-------|-------------|
| `git lg` | Pretty log graph |
| `git ap` | Interactive staging |
| `git syncm` | Checkout main, pull, rebase current branch |
| `git fwl` | `push --force-with-lease` |
| `git standup` | Yesterday's commits by you |
| `git brr` | Checkout recent branch via fzf |
| `git cleanupm` | Delete branches merged into main |

## Commit signing

Commits are signed with SSH via 1Password when available. `install.sh` detects `op-ssh-sign` at runtime — on machines without 1Password, signing is disabled automatically.

## Tools

| Tool | Purpose | Required? |
|------|---------|-----------|
| zsh | Shell | Yes (local) |
| tmux | Terminal multiplexer | Yes |
| nvim | Editor | Yes |
| gh | GitHub CLI | Yes |
| copilot-cli | AI pair programming | Yes |
| Ghostty | Terminal emulator | Local only |
| [Starship](https://starship.rs/) | Prompt | Falls back to built-in |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder | Recommended |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Directory jumper | Optional |
| [LazyGit](https://github.com/jesseduffield/lazygit) | Git TUI | Optional |
| [Television](https://github.com/alexpasmantier/television) | Fuzzy picker (sessions, issues, PRs, etc.) | Recommended |
| [sesh](https://github.com/joshmedeski/sesh) | Tmux session manager | Recommended |
| [glow](https://github.com/charmbracelet/glow) | Markdown renderer | Optional |
| [Posting](https://github.com/darrenburns/posting) | API client | Optional |
| [bat](https://github.com/sharkdp/bat) | `cat` with syntax highlighting | Optional |
| [eza](https://github.com/eza-community/eza) | Modern `ls` | Optional |
| [fd](https://github.com/sharkdp/fd) | Fast `find` | Optional |
| [btop](https://github.com/aristocratos/btop) | System monitor | Optional |
| [fzf-tab](https://github.com/Aloxaf/fzf-tab) | fzf tab completion | Optional (`~/code/fzf-tab`) |

## After a fresh install

After `install.sh` and `brew bundle`, open nvim and run:

```vim
:Lazy sync
:TSInstall yaml markdown bash json lua ruby go javascript typescript
```

This installs nvim plugins and treesitter parsers (one-time setup). Requires
`tree-sitter` CLI (included in Brewfile).
