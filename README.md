# Dertfiles

Personal dotfiles that extend thoughtbot's [laptop](https://github.com/thoughtbot/laptop) and [dotfiles](https://github.com/thoughtbot/dotfiles). Everything here is the `*.local` overlay — thoughtbot's dotfiles source these automatically via their `rcm` setup.

## Repository structure

```
.
├── .laptop.local           # Laptop script extensions (brews, casks, asdf plugins, macOS defaults)
├── install.sh              # Codespaces bootstrap (auto-detected via $CODESPACES)
├── install-gh-extensions.sh# Installs gh CLI extensions (idempotent)
│
├── aliases.local           # Shell aliases (Rails, Heroku, Ruby, Git)
├── gitconfig.local         # Git identity, aliases, editor, diff tool
├── git_template.local/     # Git hooks (commit, pre-commit, prepare-commit-message)
├── zshrc.local             # Zsh prompt, history, PATH, plugins (fzf, fzf-tab, z, asdf)
├── zshenv.local            # (empty — reserved for env vars loaded before .zshrc)
├── ghostty/config          # Ghostty terminal config (keybindings, theme, font)
├── tmux.conf.local         # Tmux: rebinds prefix to C-a
│
├── vimrc.local             # Vim settings, keybindings, plugin config (NERDTree, FZF, Fugitive, ALE)
├── vimrc.bundles.local     # vim-plug plugins (NeoSolarized, fzf, Copilot, vim-plan, etc.)
├── nvim.local              # Neovim init — sources ~/.vimrc then loads Lua plugins
├── nvim/lua/               # Neovim Lua plugin configs (packer)
│
├── gemrc.local             # Gem defaults (skip ri/rdoc)
├── ripgreprc               # Ripgrep defaults (smart-case, max-columns, glob exclusions)
└── codespaces.local        # Codespaces-specific setup (linuxbrew, fzf, nvim, ctags)
```

## Fresh machine setup

```bash
# 1. Run thoughtbot's laptop script
curl --remote-name https://raw.githubusercontent.com/thoughtbot/laptop/master/mac
curl --remote-name https://raw.githubusercontent.com/maxbeizer/dertfiles/master/.laptop.local
less mac
sh mac 2>&1 | tee ~/laptop.log

# 2. Install gh CLI extensions
./install-gh-extensions.sh
```

Or run one command after cloning this repo:

```bash
~/dotfiles-local/bin/bootstrap-machine
```

## Project hygiene

- Track notable changes in [`CHANGELOG.md`](./CHANGELOG.md).
- Use [`AGENTS.md`](./AGENTS.md) for repeatable agent setup and VM rehearsal notes.

`.laptop.local` handles Homebrew packages, cask apps, Ruby gems, asdf language plugins, fzf setup, ripgrep config, and macOS keyboard repeat settings.

## Codespaces

When `$CODESPACES` is set, `install.sh` runs automatically and:

- Symlinks local dotfiles into `$HOME`
- Downloads thoughtbot base dotfiles
- Installs vim-plug plugins
- Sets up Neovim with packer
- Configures bash with aliases, editor, and Go/Copilot paths

## Key aliases

| Alias | Command |
|-------|---------|
| `gs` | `git status -b -s` |
| `dm` | `bin/rails db:migrate` |
| `rc` | `bin/rails c` |
| `be` | `bundle exec` |
| `h` | `heroku` |
| `speedtest` | `networkQuality` |

See `aliases.local` for the full list.

## Git aliases

Defined in `gitconfig.local`. Highlights:

| Alias | Description |
|-------|-------------|
| `git lg` | Pretty log graph |
| `git ap` | `add -p` (interactive staging) |
| `git syncm` | Checkout main, pull, rebase current branch |
| `git fwl` | `push --force-with-lease` |
| `git standup` | Yesterday's commits by you |
| `git brr` | Checkout recent branch via fzf |
| `git cleanupm` | Delete branches merged into main |

## Vim / Neovim

- **Leader**: `,`
- **Colorscheme**: NeoSolarized (dark)
- **File finder**: fzf (`Ctrl-P` files, `Ctrl-T` buffers)
- **File tree**: NERDTree (`Ctrl-N`)
- **Git**: Fugitive (`<leader>gs`, `<leader>gd`, etc.)
- **Debugger shortcuts**: `<leader>b` inserts `binding.pry`, `<leader>i` inserts `IEx.pry`
- Strips trailing whitespace on save for `.rb`, `.ex`, `.exs`, `.js`

Plugins are managed by vim-plug in `vimrc.bundles.local`.

## Dependencies

- [thoughtbot/laptop](https://github.com/thoughtbot/laptop) — base setup script
- [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles) — base dotfiles (sourced via rcm)
- [asdf](https://asdf-vm.com/) — runtime version manager (Ruby, Erlang, Elixir, Go, Node.js)
- [fzf](https://github.com/junegunn/fzf) — fuzzy finder
- [fzf-tab](https://github.com/Aloxaf/fzf-tab) — fzf-powered zsh tab completion (cloned to `~/code/fzf-tab`)
- [z](https://github.com/rupa/z) — directory jumper (sourced from `~/z.sh`)

## Verified commits without GPG

Yes — you can use SSH commit signing instead of GPG.

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
```

Then add the corresponding SSH signing key in GitHub settings under **SSH and GPG keys** as a **Signing key**.
