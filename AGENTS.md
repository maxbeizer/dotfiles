# Agent bootstrap guide

Use this guide when an agent is setting up a machine with these dotfiles.

## Goal
Set up a self-contained dotfiles environment. No external base layer needed.

## One-command bootstrap (recommended)
```bash
git clone https://github.com/maxbeizer/dotfiles.git ~/dotfiles
~/dotfiles/bin/bootstrap-machine
```

Useful flags:
```bash
~/dotfiles/bin/bootstrap-machine --dry-run
~/dotfiles/bin/bootstrap-machine --skip-verify
```

## What install.sh does
- Symlinks dotfiles (aliases, gitconfig, zshrc, tmux.conf, etc.) into `$HOME`
- Links Starship config to `~/.config/starship.toml`
- Links the fast Starship config to `~/.config/starship-fast-git.toml`
- Sets up git SSH signing via 1Password (when `op-ssh-sign` is available)
- Creates `~/.config/git/allowed_signers`
- Links Neovim config to `~/.config/nvim/`
- Links bin scripts to `~/.local/bin/`
- Links Ghostty config to `~/.config/ghostty/`
- Links sesh config to `~/.config/sesh/`
- Links television cable channels to `~/.config/television/cable/`
- Links Pi global customizations with `pi/install.sh` into `~/.pi/agent/`
  and `~/.agents/skills`, including extensions, prompt templates, and themes
- In codespaces: wires up bash with Starship, zoxide, fzf, aliases, and a
  package-manager `tree-sitter` CLI for Neovim parser builds

## Iterating on changes
```bash
dotup    # pull, reinstall, reload shell (works in bash and zsh)
```

## Documentation conventions

When making notable changes to dotfiles, update:
1. `CHANGELOG.md` — add entry under `[Unreleased]` with Added/Changed/Removed sections
2. `README.md` — update relevant sections (keybindings, aliases, tools, file tree)
3. `AGENTS.md` — update key files table and any affected bootstrap/workflow docs

Notable changes include: new tools/integrations, keybinding changes, new aliases,
config file additions, and workflow changes. Minor tweaks (typos, comment updates)
don't need changelog entries.

## Session management (sesh)

sesh manages tmux sessions with zoxide-based project discovery.

### Starting from scratch
```bash
tome                    # Start main session directly
# Then: prefix S to pick/create more sessions
```

### Session picker (prefix S)
Uses `bin/sesh-picker` — shows all tmux sessions (with 🔔 bell indicators sorted
to the top), zoxide directories, and configured sessions from `sesh/sesh.toml`.
- `Enter` to connect, `ctrl-d` to remove a session
- Sessions with pending bells (e.g., Copilot CLI finished) appear first

### After a reboot
```bash
tome                    # or: tmux → prefix Ctrl-r to resurrect
```

### Seeding zoxide for new directories
```bash
for d in ~/code/myorg/*; do zoxide add "$d"; done
```

## Television channels

Custom cable channels in `television/cable/` provide fuzzy pickers with previews:
- `tv gh-notifications` — triage notifications (ctrl-e=done, ctrl-g=unsubscribe)
- `tv gh-issues` / `tv gh-prs` — browse with metadata + markdown preview
- `tv processes` — find/manage processes by CPU usage
- `tv tldr` — browse command help pages
- `tv brew-packages` — manage Homebrew packages
- `tv channels` — meta-channel to browse all channels

## Copilot CLI hooks (tmux bells)

Global hooks live in `copilot/hooks/` and are linked to `~/.copilot/hooks/` by
`install.sh`. These send a tmux terminal bell and write a local attention marker
when the Copilot CLI agent needs user input (`ask_user`) or a session ends
(`sessionEnd`), so `bin/sesh-picker` can float sessions needing attention even
if tmux's transient bell flag is missed or cleared. If no local tmux pane can be
resolved (for example inside an SSH-backed Codespace), the hook falls back to
ringing `/dev/tty`. Attention clears
automatically when the marked session/window becomes visible, and `sesh-picker`
suppresses bells for sessions attached to active tmux clients.

## Theme switching
```bash
theme mocha        # Catppuccin Mocha (default)
theme solarized    # Solarized Dark
theme              # show current theme
```
Applies to Ghostty (restart required), tmux (live), nvim (live via remote-send), and television.

## Verification checklist
```bash
zsh -lic 'echo shell-ok'      # shell starts cleanly
theme                          # shows current theme
command -v starship            # prompt installed
command -v zoxide              # directory jumper installed
```

## Codespaces test loop for Neovim
```bash
CODESPACES=true ./install.sh
./bin/codespaces-vim-lab doctor
./bin/codespaces-vim-lab refresh
./bin/codespaces-vim-lab startup
```

## Key files
| File | Purpose |
|------|---------|
| `install.sh` | Idempotent installer (local + codespace) |
| `bin/bootstrap-machine` | Fresh machine setup |
| `bin/copilot-clear-attention` | Clears Copilot tmux attention markers when sessions/windows become visible |
| `bin/gh-new-cs` | Creates/connects a github/github Codespace and deploys gh-test |
| `bin/sesh-picker` | Session picker with 🔔 bell indicators |
| `bin/theme` | Theme switcher (solarized ↔ mocha) |
| `zshrc` | Shell config (prompt, PATH, tools) |
| `aliases` | Shell aliases (including `tome`) |
| `gitconfig` | Git config (includes SSH signing) |
| `tmux.conf` | Tmux config (sesh picker, resurrect, vim keys) |
| `starship.toml` | Starship prompt config |
| `starship-fast-git.toml` | Branch-only Starship config used under `~/code/github/github` |
| `sesh/sesh.toml` | sesh session manager config |
| `television/cable/` | Television custom cable channels |
| `codespaces.local` | Bash extras for codespaces + `dotup` |
| `copilot/hooks/` | Copilot CLI hooks (symlinked to `~/.copilot/hooks/`) |
| `copilot/skills/` | Copilot CLI skills (symlinked to `~/.copilot/skills/` and `~/.agents/skills`) |
| `pi/` | Pi coding agent global extensions, themes, and installer |
| `CHANGELOG.md` | Document notable changes here |
