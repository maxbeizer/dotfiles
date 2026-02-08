#!/bin/bash
#
# Symlink Copilot CLI configs from dotfiles-local into ~/.copilot/
# Idempotent: safe to run multiple times.
#

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
COPILOT_DIR="$HOME/.copilot"

fancy_echo() {
  printf "\n%s\n" "$1"
}

# Symlink a single file. If the target already exists and is not a symlink
# pointing to our source, back it up before replacing.
link_file() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ]; then
    local current_target
    current_target="$(readlink "$dest")"
    if [ "$current_target" = "$src" ]; then
      echo "  ✓ already linked: $dest"
      return
    fi
    echo "  ↻ updating symlink: $dest"
    rm "$dest"
  elif [ -e "$dest" ]; then
    echo "  ⚠ backing up: $dest → ${dest}.backup"
    mv "$dest" "${dest}.backup"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "  → linked: $dest"
}

fancy_echo "Setting up Copilot CLI configs..."

# Config files
link_file "$DOTFILES_DIR/copilot/config.json" "$COPILOT_DIR/config.json"
link_file "$DOTFILES_DIR/copilot/mcp-config.json" "$COPILOT_DIR/mcp-config.json"

# Skills — link the entire skill directory to keep it simple
for skill_dir in "$DOTFILES_DIR"/copilot/skills/*/; do
  skill_name="$(basename "$skill_dir")"
  link_file "$DOTFILES_DIR/copilot/skills/$skill_name" "$COPILOT_DIR/skills/$skill_name"
done

fancy_echo "Copilot CLI configs linked ✓"
