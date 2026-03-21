#!/bin/bash
#
# Self-contained dotfiles installer. Idempotent — safe to run repeatedly.
# No external dependencies (no rcm, no thoughtbot/dotfiles).
#
# Usage:
#   ./install.sh              # detect environment and install
#   ./install.sh --dry-run    # show what would happen
#

set -eu

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

fancy_echo() {
  printf "\n%s\n" "$1"
}

link_file() {
  local src="$1" dst="$2"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] $src -> $dst"
  else
    ln -sf "$src" "$dst"
    echo "  ✓ $(basename "$dst")"
  fi
}

# --- Dotfiles to symlink into $HOME as dotfiles (.<name>) ---
DOTFILES=(
  aliases
  gemrc
  gitconfig
  gitignore
  gitmessage
  ripgreprc
  starship.toml
  tmux.conf
  zshrc
  zshenv.local
)

fancy_echo "Linking dotfiles to \$HOME"
for f in "${DOTFILES[@]}"; do
  [ -f "$DOTFILES_DIR/$f" ] && link_file "$DOTFILES_DIR/$f" "$HOME/.$f"
done

# Starship config goes to ~/.config/starship.toml (not dotfile)
if [ -f "$DOTFILES_DIR/starship.toml" ]; then
  mkdir -p "$HOME/.config"
  link_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
fi

# --- Zsh configs directory ---
fancy_echo "Linking zsh config directory"
mkdir -p "$HOME/.zsh"
[ -d "$DOTFILES_DIR/zsh/configs" ] && link_file "$DOTFILES_DIR/zsh/configs" "$HOME/.zsh/configs"
[ -d "$DOTFILES_DIR/zsh/functions" ] && link_file "$DOTFILES_DIR/zsh/functions" "$HOME/.zsh/functions"

# --- Git SSH commit signing (1Password, when available) ---
if [ -x "/Applications/1Password.app/Contents/MacOS/op-ssh-sign" ]; then
  git config --global gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
  git config --global commit.gpgsign true
  echo "  ✓ 1Password SSH signing enabled"
else
  git config --global commit.gpgsign false
  echo "  · no op-ssh-sign found — commit signing disabled"
fi

# --- Git allowed signers (for SSH commit verification) ---
fancy_echo "Setting up git allowed signers"
mkdir -p "$HOME/.config/git"
if [ ! -f "$HOME/.config/git/allowed_signers" ] || ! grep -q "max.beizer@gmail.com" "$HOME/.config/git/allowed_signers" 2>/dev/null; then
  echo "max.beizer@gmail.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINrEq8YlmAUVnpK/xXjnLclUTi/kxO5XA8iVPFIjEPac" >> "$HOME/.config/git/allowed_signers"
  echo "  ✓ allowed_signers"
fi

# --- Neovim ---
fancy_echo "Linking Neovim config"
mkdir -p "$HOME/.config/nvim"
[ -f "$DOTFILES_DIR/nvim.local" ] && link_file "$DOTFILES_DIR/nvim.local" "$HOME/.config/nvim/init.vim"
if [ -d "$DOTFILES_DIR/nvim/lua" ]; then
  rm -rf "$HOME/.config/nvim/lua"
  if [ "$DRY_RUN" -eq 0 ]; then
    cp -R "$DOTFILES_DIR/nvim/lua" "$HOME/.config/nvim/lua"
  fi
  echo "  ✓ nvim/lua"
fi

# --- Bin scripts ---
fancy_echo "Linking bin scripts to ~/.local/bin"
mkdir -p "$HOME/.local/bin"
for f in "$DOTFILES_DIR/bin/"*; do
  [ -f "$f" ] && link_file "$f" "$HOME/.local/bin/$(basename "$f")"
done

# --- Ghostty ---
if [ -d "$DOTFILES_DIR/ghostty" ]; then
  fancy_echo "Linking Ghostty config"
  mkdir -p "$HOME/.config/ghostty"
  link_file "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"
fi

# --- Codespace-specific extras ---
if [ "${CODESPACES:-}" = "true" ]; then
  fancy_echo "Codespace extras"

  # gh/gh vendors a modern Node; prefer it over the ancient system one
  if [ -x "/workspaces/github/vendor/node/node" ]; then
    export PATH="/workspaces/github/vendor/node:/workspaces/github/vendor/node/bin:$PATH"
  fi

  link_file "$DOTFILES_DIR/codespaces.local" "$HOME/.codespaces.local"

  # Neovim plugin sync
  if command -v nvim >/dev/null 2>&1; then
    fancy_echo "Syncing Neovim plugins"
    [ "$DRY_RUN" -eq 0 ] && nvim --headless '+Lazy! sync' +qa 2>/dev/null || true
  fi

  # Bash integration (codespaces default shell)
  if [ "$DRY_RUN" -eq 0 ]; then
    _bashrc_ensure() {
      grep -qF "$1" "$HOME/.bashrc" 2>/dev/null || echo "$1" >> "$HOME/.bashrc"
    }

    _bashrc_ensure 'source $HOME/.aliases'
    _bashrc_ensure 'source $HOME/.codespaces.local'
    _bashrc_ensure 'export EDITOR=vim'
    _bashrc_ensure 'for fn in $HOME/.zsh/functions/*; do [ -f "$fn" ] && source "$fn"; done'
    _bashrc_ensure 'command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"'
    _bashrc_ensure 'command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"'
    _bashrc_ensure '[ -f ~/.fzf.bash ] && source ~/.fzf.bash'

    if [ -d "/workspaces/github/bin" ]; then
      _bashrc_ensure 'export PATH="$PATH:/workspaces/github/bin"'
    fi
    grep -q '\.bashrc' "$HOME/.bash_profile" 2>/dev/null || \
      echo "source \$HOME/.bashrc" >> "$HOME/.bash_profile"
  fi

  # Copilot CLI
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    fancy_echo "Installing Copilot CLI"
    if [ "$DRY_RUN" -eq 0 ]; then
      npm config set "//npm.pkg.github.com/:_authToken=$GITHUB_TOKEN"
      npm config set "@github:registry=https://npm.pkg.github.com/"
      npm install -g @github/copilot 2>/dev/null || true
    fi
  fi
fi

fancy_echo "Done ✓"
