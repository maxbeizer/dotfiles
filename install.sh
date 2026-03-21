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

# --- Homebrew packages (local only, skip in codespaces) ---
if [ "${CODESPACES:-}" != "true" ] && command -v brew >/dev/null 2>&1; then
  if [ -f "$DOTFILES_DIR/Brewfile" ]; then
    fancy_echo "Installing Homebrew packages"
    if [ "$DRY_RUN" -eq 0 ]; then
      brew bundle --file="$DOTFILES_DIR/Brewfile" --no-lock --quiet
    else
      echo "  [dry-run] brew bundle --file=$DOTFILES_DIR/Brewfile"
    fi
  fi
fi

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
  zshenv
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
for zdir in configs functions; do
  if [ -d "$DOTFILES_DIR/zsh/$zdir" ]; then
    # Remove existing dir/symlink to avoid nesting a symlink inside itself
    rm -rf "$HOME/.zsh/$zdir"
    link_file "$DOTFILES_DIR/zsh/$zdir" "$HOME/.zsh/$zdir"
  fi
done

# --- Zsh plugins (syntax highlighting, autosuggestions) ---
fancy_echo "Setting up zsh plugins"
mkdir -p "$HOME/.zsh/plugins"
if [ "$DRY_RUN" -eq 0 ]; then
  for plugin in zsh-users/zsh-syntax-highlighting zsh-users/zsh-autosuggestions; do
    name="${plugin#*/}"
    if [ ! -d "$HOME/.zsh/plugins/$name" ]; then
      git clone --depth 1 "https://github.com/$plugin.git" "$HOME/.zsh/plugins/$name" 2>/dev/null
      echo "  ✓ $name"
    fi
  done
fi

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

  # Set zsh as default shell in codespaces
  if [ "$DRY_RUN" -eq 0 ] && command -v zsh >/dev/null 2>&1; then
    if [ "$(basename "$SHELL")" != "zsh" ]; then
      sudo chsh -s "$(which zsh)" "$(whoami)" 2>/dev/null || true
      echo "  ✓ default shell set to zsh"
    fi
  fi

  # Source codespaces.local from zshrc if not already
  if [ "$DRY_RUN" -eq 0 ]; then
    grep -qF 'codespaces.local' "$HOME/.zshrc" 2>/dev/null || \
      echo '[ -f ~/.codespaces.local ] && source ~/.codespaces.local' >> "$HOME/.zshrc"
    if [ -d "/workspaces/github/bin" ]; then
      grep -qF '/workspaces/github/bin' "$HOME/.zshrc" 2>/dev/null || \
        echo 'export PATH="$PATH:/workspaces/github/bin"' >> "$HOME/.zshrc"
    fi
  fi

  # Install CLI tools if not present
  if [ "$DRY_RUN" -eq 0 ]; then
    # Starship prompt
    if ! command -v starship >/dev/null 2>&1; then
      curl -sS https://starship.rs/install.sh | sh -s -- -y >/dev/null 2>&1
      echo "  ✓ starship installed"
    fi
    # zoxide (directory jumper)
    if ! command -v zoxide >/dev/null 2>&1; then
      curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh >/dev/null 2>&1
      echo "  ✓ zoxide installed"
    fi
    # fzf
    if ! command -v fzf >/dev/null 2>&1; then
      if [ ! -d "$HOME/.fzf" ]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" 2>/dev/null
      fi
      "$HOME/.fzf/install" --all --no-update-rc --no-bash --no-fish 2>/dev/null || true
      echo "  ✓ fzf installed"
    fi
    # lazygit
    if ! command -v lazygit >/dev/null 2>&1; then
      LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
      curl -sLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
      tar xzf /tmp/lazygit.tar.gz -C /tmp lazygit 2>/dev/null
      sudo install /tmp/lazygit /usr/local/bin/lazygit 2>/dev/null && echo "  ✓ lazygit installed"
      rm -f /tmp/lazygit /tmp/lazygit.tar.gz
    fi
  fi

  # Neovim plugin sync
  if command -v nvim >/dev/null 2>&1; then
    fancy_echo "Syncing Neovim plugins"
    [ "$DRY_RUN" -eq 0 ] && nvim --headless '+Lazy! sync' +qa 2>/dev/null || true
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
