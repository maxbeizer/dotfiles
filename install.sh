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

# Ensure the ready sentinel is created even if the script fails partway through,
# so the codespace shell wait loop (codespaces.local) doesn't spin forever.
trap 'touch "$HOME/.dotfiles_ready"' EXIT

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

fancy_echo() {
  printf "\n%s\n" "$1"
}

is_broken_tree_sitter() {
  ! command -v tree-sitter >/dev/null 2>&1 || ! tree-sitter --version >/dev/null 2>&1
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
    fancy_echo "Installing Homebrew packages (may prompt for password)"
    if [ "$DRY_RUN" -eq 0 ]; then
      brew bundle --file="$DOTFILES_DIR/Brewfile" --quiet
    else
      echo "  [dry-run] brew bundle --file=$DOTFILES_DIR/Brewfile"
    fi
  fi
fi

# --- macOS defaults ---
if [ "$(uname)" = "Darwin" ] && [ "$DRY_RUN" -eq 0 ]; then
  fancy_echo "Setting macOS defaults"
  defaults write -g InitialKeyRepeat -int 15
  defaults write -g KeyRepeat -int 2
  echo "  ✓ fast key repeat enabled"
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
if [ -f "$DOTFILES_DIR/starship-fast-git.toml" ]; then
  mkdir -p "$HOME/.config"
  link_file "$DOTFILES_DIR/starship-fast-git.toml" "$HOME/.config/starship-fast-git.toml"
fi

# --- Zsh configs directory ---
fancy_echo "Linking zsh config directory"
mkdir -p "$HOME/.zsh"
for zdir in configs functions; do
  if [ -d "$DOTFILES_DIR/zsh/$zdir" ]; then
    # Remove existing dir/symlink to avoid nesting a symlink inside itself
    [ "$DRY_RUN" -eq 0 ] && rm -rf "$HOME/.zsh/$zdir"
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

# --- Git SSH commit signing (generated ~/.gitconfig.local) ---
fancy_echo "Generating ~/.gitconfig.local (signing config)"
GITCONFIG_LOCAL="$HOME/.gitconfig.local"
if [ "$DRY_RUN" -eq 1 ]; then
  echo "  [dry-run] would generate $GITCONFIG_LOCAL"
elif [ -x "/Applications/1Password.app/Contents/MacOS/op-ssh-sign" ]; then
  cat > "$GITCONFIG_LOCAL" <<'EOF'
[commit]
  gpgsign = true
[gpg]
  format = ssh
[gpg "ssh"]
  allowedSignersFile = ~/.config/git/allowed_signers
  program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign
[user]
  signingkey = ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINrEq8YlmAUVnpK/xXjnLclUTi/kxO5XA8iVPFIjEPac
EOF
  echo "  ✓ 1Password SSH signing enabled"
else
  cat > "$GITCONFIG_LOCAL" <<'EOF'
[commit]
  gpgsign = false
EOF
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
  [ "$DRY_RUN" -eq 0 ] && rm -rf "$HOME/.config/nvim/lua"
  link_file "$DOTFILES_DIR/nvim/lua" "$HOME/.config/nvim/lua"
  echo "  ✓ nvim/lua"
fi
if [ -d "$DOTFILES_DIR/nvim/after" ]; then
  [ "$DRY_RUN" -eq 0 ] && rm -rf "$HOME/.config/nvim/after"
  link_file "$DOTFILES_DIR/nvim/after" "$HOME/.config/nvim/after"
  echo "  ✓ nvim/after"
fi

# --- Bin scripts ---
fancy_echo "Linking bin scripts to ~/.local/bin"
mkdir -p "$HOME/.local/bin"
for f in "$DOTFILES_DIR/bin/"*; do
  [ -f "$f" ] && link_file "$f" "$HOME/.local/bin/$(basename "$f")"
done

# --- Kitty ---
if [ -d "$DOTFILES_DIR/kitty" ]; then
  fancy_echo "Linking Kitty config"
  mkdir -p "$HOME/.config/kitty/themes"
  link_file "$DOTFILES_DIR/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
  if [ -d "$DOTFILES_DIR/kitty/themes" ]; then
    for f in "$DOTFILES_DIR/kitty/themes/"*; do
      [ -f "$f" ] && link_file "$f" "$HOME/.config/kitty/themes/$(basename "$f")"
    done
  fi
fi

# --- Sesh ---
if [ -d "$DOTFILES_DIR/sesh" ]; then
  fancy_echo "Linking sesh config"
  mkdir -p "$HOME/.config/sesh"
  link_file "$DOTFILES_DIR/sesh/sesh.toml" "$HOME/.config/sesh/sesh.toml"
fi

# --- Television cable channels ---
if [ -d "$DOTFILES_DIR/television/cable" ]; then
  fancy_echo "Linking television cable channels"
  mkdir -p "$HOME/.config/television/cable"
  for f in "$DOTFILES_DIR/television/cable/"*.toml; do
    [ -f "$f" ] && link_file "$f" "$HOME/.config/television/cable/$(basename "$f")"
  done
fi

# --- Copilot CLI hooks ---
if [ -d "$DOTFILES_DIR/copilot/hooks" ]; then
  fancy_echo "Linking Copilot CLI hooks"
  mkdir -p "$HOME/.copilot/hooks"
  for hook_file in "$DOTFILES_DIR/copilot/hooks/"*; do
    [ -f "$hook_file" ] && link_file "$hook_file" "$HOME/.copilot/hooks/$(basename "$hook_file")"
  done
fi

# --- Pi coding agent customizations ---
if [ -x "$DOTFILES_DIR/pi/install.sh" ]; then
  fancy_echo "Linking Pi customizations"
  if [ "$DRY_RUN" -eq 1 ]; then
    "$DOTFILES_DIR/pi/install.sh" --dry-run
  else
    "$DOTFILES_DIR/pi/install.sh"
  fi
fi

# --- Codespace-specific extras ---
if [ "${CODESPACES:-}" = "true" ]; then
  fancy_echo "Codespace extras"

  # gh/gh vendors a modern Node; prefer it over the ancient system one
  if [ -x "/workspaces/github/vendor/node/node" ]; then
    export PATH="/workspaces/github/vendor/node:/workspaces/github/vendor/node/bin:$PATH"
  fi
  export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"

  link_file "$DOTFILES_DIR/codespaces.local" "$HOME/.codespaces.local"

  # Set zsh as default shell in codespaces
  if [ "$DRY_RUN" -eq 0 ] && command -v zsh >/dev/null 2>&1; then
    if [ "$(basename "$SHELL")" != "zsh" ]; then
      sudo chsh -s "$(which zsh)" "$(whoami)" 2>/dev/null || true
      echo "  ✓ default shell set to zsh"
    fi
  fi

  # Add /workspaces/github/bin to PATH via codespaces.local if needed
  if [ "$DRY_RUN" -eq 0 ] && [ -d "/workspaces/github/bin" ]; then
    grep -qF '/workspaces/github/bin' "$HOME/.codespaces.local" 2>/dev/null || \
      echo 'export PATH="$PATH:/workspaces/github/bin"' >> "$HOME/.codespaces.local"
  fi

  # Install gh CLI extensions (rdm, etc.)
  if [ "$DRY_RUN" -eq 0 ] && [ -f "$DOTFILES_DIR/install-gh-extensions.sh" ]; then
    fancy_echo "Installing gh CLI extensions"
    bash "$DOTFILES_DIR/install-gh-extensions.sh"
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
    # bat (syntax-highlighted cat)
    if ! command -v bat >/dev/null 2>&1; then
      BAT_VERSION=$(curl -s "https://api.github.com/repos/sharkdp/bat/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
      curl -sLo /tmp/bat.deb "https://github.com/sharkdp/bat/releases/latest/download/bat_${BAT_VERSION}_amd64.deb"
      sudo dpkg -i /tmp/bat.deb >/dev/null 2>&1 && echo "  ✓ bat installed"
      rm -f /tmp/bat.deb
    fi
    # fd (fast find)
    if ! command -v fd >/dev/null 2>&1; then
      FD_VERSION=$(curl -s "https://api.github.com/repos/sharkdp/fd/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
      curl -sLo /tmp/fd.deb "https://github.com/sharkdp/fd/releases/latest/download/fd_${FD_VERSION}_amd64.deb"
      sudo dpkg -i /tmp/fd.deb >/dev/null 2>&1 && echo "  ✓ fd installed"
      rm -f /tmp/fd.deb
    fi
    # eza (modern ls)
    if ! command -v eza >/dev/null 2>&1; then
      curl -sLo /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
      tar xzf /tmp/eza.tar.gz -C /tmp 2>/dev/null
      sudo install /tmp/eza /usr/local/bin/eza 2>/dev/null && echo "  ✓ eza installed"
      rm -f /tmp/eza /tmp/eza.tar.gz
    fi
    # nvim-treesitter requires tree-sitter-cli from a package manager, not npm.
    # Some gh/gh Codespaces expose a Node-installed binary that needs newer glibc.
    if is_broken_tree_sitter; then
      if command -v brew >/dev/null 2>&1; then
        brew install tree-sitter >/dev/null 2>&1 || true
      fi

      if is_broken_tree_sitter && command -v cargo >/dev/null 2>&1; then
        cargo install tree-sitter-cli --version 0.26.1 --locked >/dev/null 2>&1 || true
      fi

      if is_broken_tree_sitter; then
        echo "  ⚠ tree-sitter CLI still unavailable; nvim parser installs may fail"
      else
        echo "  ✓ tree-sitter installed"
      fi
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

  # Copilot CLI skills
  if [ -d "$DOTFILES_DIR/copilot/skills" ]; then
    fancy_echo "Linking Copilot CLI skills"
    mkdir -p "$HOME/.copilot/skills"
    for skill_dir in "$DOTFILES_DIR/copilot/skills"/*/; do
      [ -d "$skill_dir" ] || continue
      skill_name=$(basename "$skill_dir")
      target="$HOME/.copilot/skills/$skill_name"
      if [ "$DRY_RUN" -eq 0 ]; then
        rm -rf "$target"
        ln -sf "$skill_dir" "$target"
      fi
      fancy_echo "  $skill_name → $target"
    done
  fi

fi

fancy_echo "Done ✓"

# Signal that dotfiles install is complete (used by codespace shell wait loop)
touch "$HOME/.dotfiles_ready"
