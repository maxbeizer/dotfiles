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

remove_link_if_target() {
  local dst="$1" target="$2"

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$target" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      printf '  [dry-run] rm %s\n' "$dst"
    else
      rm "$dst"
      printf '  ✓ removed obsolete link: %s\n' "$dst"
    fi
  fi
}

configure_settings() {
  local settings="$GLOBAL_PI_DIR/settings.json"

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  [dry-run] merge Pi startup defaults into %s\n' "$settings"
    return 0
  fi

  SETTINGS_PATH="$settings" python3 <<'PY'
import json
import os
from pathlib import Path

settings = Path(os.environ["SETTINGS_PATH"])
if settings.exists():
    data = json.loads(settings.read_text())
else:
    data = {}

# Keep user model/provider/auth choices, but keep global Pi startup lightweight and curated.
data["theme"] = "catppuccin-mocha"
data["skills"] = ["~/.agents/skills"]
data["enableSkillCommands"] = True
data["quietStartup"] = True

settings.write_text(json.dumps(data, indent=2) + "\n")
PY
  printf '  ✓ configured Pi settings: %s\n' "$settings"
}

fancy_echo "Creating Pi config directories"
ensure_dir "$GLOBAL_PI_DIR/extensions"
ensure_dir "$GLOBAL_PI_DIR/prompts"
ensure_dir "$GLOBAL_PI_DIR/themes"
ensure_dir "$HOME/.agents"

if [ -d "$PI_DIR/extensions" ]; then
  fancy_echo "Linking global Pi extensions"
  remove_link_if_target "$GLOBAL_PI_DIR/extensions/repo-status.ts" "$PI_DIR/extensions/repo-status.ts"

  for extension in "$PI_DIR/extensions"/*.ts; do
    [ -f "$extension" ] || continue
    link_exact "$extension" "$GLOBAL_PI_DIR/extensions/$(basename "$extension")"
  done

  for extension_dir in "$PI_DIR/extensions"/*; do
    [ -d "$extension_dir" ] || continue
    [ -f "$extension_dir/index.ts" ] || continue
    link_exact "$extension_dir" "$GLOBAL_PI_DIR/extensions/$(basename "$extension_dir")"
  done
fi

if [ -d "$PI_DIR/prompts" ]; then
  fancy_echo "Linking global Pi prompt templates"
  for prompt in "$PI_DIR/prompts"/*.md; do
    [ -f "$prompt" ] || continue
    link_exact "$prompt" "$GLOBAL_PI_DIR/prompts/$(basename "$prompt")"
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

fancy_echo "Configuring Pi settings"
configure_settings

fancy_echo "Pi global customization install complete ✓"
printf '  Reload open Pi sessions with /reload.\n'
