# Codespaces Vim/Neovim testing guide

Use this workflow to test Vim/Neovim changes safely before applying them on your laptop.

## 1) Start from this repository in Codespaces

```bash
git clone https://github.com/maxbeizer/dotfiles.git ~/dotfiles-local
cd ~/dotfiles-local
```

## 2) Run Codespaces bootstrap

```bash
CODESPACES=true ./install.sh
```

This wires local overlays, fetches thoughtbot base files, and configures Neovim.

## 3) Use the lab helper

```bash
./bin/codespaces-vim-lab doctor
./bin/codespaces-vim-lab refresh
./bin/codespaces-vim-lab startup
```

- `doctor`: verify config files and binaries
- `refresh`: sync vim-plug and lazy.nvim plugins
- `startup`: capture startup timing logs

## 4) Validate expected workflows

Inside Neovim, check your habitual flows still work:

- `<C-p>` files picker
- `<C-t>` buffer picker
- `<C-n>` file tree toggle
- `,gs` and `,gd` fugitive shortcuts
- `,b` / `,i` debug macros from your legacy `.vimrc` setup

## 5) Iterate and reset

- Commit experiments on a feature branch
- Rebuild Codespace or open a fresh one for clean-slate verification
