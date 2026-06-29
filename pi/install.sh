#!/usr/bin/env bash
#
# Install global Pi customizations from dotfiles.
# Idempotent and conservative: refuses to overwrite non-matching existing files.
#
# Usage:
#   ~/dotfiles/pi/install.sh
#   ~/dotfiles/pi/install.sh --dry-run

set -euo pipefail

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

PI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$PI_DIR/.." && pwd)"
GLOBAL_PI_DIR="$HOME/.pi/agent"

fancy_echo() {
  printf "\n%s\n" "$1"
}

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

ensure_dir() {
  local dir="$1"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  [dry-run] mkdir -p %s\n' "$dir"
  else
    mkdir -p "$dir"
  fi
}

link_exact() {
  local src="$1" dst="$2"

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
      printf '  ✓ %s already linked\n' "$dst"
      return 0
    fi

    printf '  ✗ refusing to overwrite existing target: %s\n' "$dst" >&2
    ls -ld "$dst" >&2 || true
    return 1
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  [dry-run] ln -s %s %s\n' "$src" "$dst"
  else
    ln -s "$src" "$dst"
    printf '  ✓ %s -> %s\n' "$dst" "$src"
  fi
}

fancy_echo "Creating Pi config directories"
ensure_dir "$GLOBAL_PI_DIR/extensions"
ensure_dir "$GLOBAL_PI_DIR/themes"
ensure_dir "$HOME/.agents"

if [ -d "$PI_DIR/extensions" ]; then
  fancy_echo "Linking global Pi extensions"
  for extension in "$PI_DIR/extensions"/*.ts; do
    [ -f "$extension" ] || continue
    link_exact "$extension" "$GLOBAL_PI_DIR/extensions/$(basename "$extension")"
  done
fi

if [ -d "$PI_DIR/themes" ]; then
  fancy_echo "Linking global Pi themes"
  for theme in "$PI_DIR/themes"/*.json; do
    [ -f "$theme" ] || continue
    link_exact "$theme" "$GLOBAL_PI_DIR/themes/$(basename "$theme")"
  done
fi

if [ -d "$DOTFILES_DIR/copilot/skills" ]; then
  fancy_echo "Linking Agent Skills"
  link_exact "$DOTFILES_DIR/copilot/skills" "$HOME/.agents/skills"
fi

fancy_echo "Pi global customization install complete ✓"
printf '  Theme: set "theme": "catppuccin-mocha" in %s/settings.json if needed.\n' "$GLOBAL_PI_DIR"
printf '  Reload open Pi sessions with /reload.\n'
