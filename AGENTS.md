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
- Sets up git SSH signing via 1Password (when `op-ssh-sign` is available)
- Creates `~/.config/git/allowed_signers`
- Links Neovim config to `~/.config/nvim/`
- Links bin scripts to `~/.local/bin/`
- Links Ghostty config to `~/.config/ghostty/`
- Links sesh config to `~/.config/sesh/`
- Links television cable channels to `~/.config/television/cable/`
- In codespaces: wires up bash with Starship, zoxide, fzf, and aliases

## Iterating on changes
```bash
dotup    # pull, reinstall, reload shell (works in bash and zsh)
```

## Copilot CLI hooks (cmux notifications)

Global hooks live at `~/.copilot/hooks/hooks.json` with the notification script
at `~/.copilot/hooks/cmux-notify.sh`. These fire cmux desktop notifications when
the Copilot CLI agent needs user input (`ask_user` via `preToolUse`) or a session
ends (`sessionEnd`).

## Theme switching
```bash
theme solarized   # Solarized Dark (default)
theme mocha        # Catppuccin Mocha
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
| `bin/theme` | Theme switcher (solarized ↔ mocha) |
| `zshrc` | Shell config (prompt, PATH, tools) |
| `aliases` | Shell aliases |
| `gitconfig` | Git config (includes SSH signing) |
| `tmux.conf` | Tmux config |
| `starship.toml` | Starship prompt config |
| `sesh/sesh.toml` | sesh session manager config |
| `television/cable/` | Television custom cable channels |
| `codespaces.local` | Bash extras for codespaces + `dotup` |
