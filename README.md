# dotfiles

Self-contained personal dotfiles. No external base layer — everything lives in this repo.

## What's here

```
.
├── install.sh                # Idempotent installer (local + codespaces)
├── bin/
│   ├── bootstrap-machine     # One-command fresh machine setup
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
├── tmux.conf                 # Tmux: C-a prefix, vim keys, mouse, pane labels
├── starship.toml             # Starship prompt config
├── ghostty/config            # Ghostty terminal (theme, font, keybinds)
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

Switch between Solarized Dark and Catppuccin Mocha across Ghostty, tmux, and nvim:

```bash
theme solarized   # or: theme mocha
theme              # show current
```

Ghostty auto-reloads; tmux and nvim update live.

## Tmux keybindings

Prefix is `Ctrl-a`.

| Keybinding | Action |
|------------|--------|
| `prefix S` | Session navigator (fzf, create/kill) |
| `prefix W` | Window navigator (fzf, all sessions, sorted by recent) |
| `prefix s` | Default session list (tree view) |
| `prefix Ctrl-s` | **Save** all sessions (tmux-resurrect) |
| `prefix Ctrl-r` | **Restore** sessions after reboot |
| `prefix I` | Install/update tmux plugins (TPM) |
| `prefix h/j/k/l` | Navigate panes (vim-style) |
| `prefix M-Arrow` | Resize panes |

### After a reboot
1. Open a terminal
2. `tmux`
3. `Ctrl-a Ctrl-r` — everything comes back

## Key aliases

| Alias | Command |
|-------|---------|
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
| [Television](https://github.com/alexpasmantier/television) | Fuzzy finder | Optional |
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
