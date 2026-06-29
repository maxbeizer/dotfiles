#!/usr/bin/env bash
# Verify global Pi customizations are linked and configured.

set -euo pipefail

PI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$PI_DIR/.." && pwd)"
GLOBAL_PI_DIR="$HOME/.pi/agent"

failures=0

ok() {
  printf '✓ %s\n' "$1"
}

warn() {
  printf '⚠ %s\n' "$1"
}

fail() {
  printf '✗ %s\n' "$1"
  failures=$((failures + 1))
}

check_dir() {
  local dir="$1"
  if [ -d "$dir" ]; then
    ok "directory exists: $dir"
  else
    fail "missing directory: $dir"
  fi
}

check_link() {
  local src="$1" dst="$2"

  if [ ! -e "$src" ]; then
    fail "missing source: $src"
    return
  fi

  if [ ! -L "$dst" ]; then
    fail "not a symlink: $dst"
    return
  fi

  local actual
  actual="$(readlink "$dst")"
  if [ "$actual" = "$src" ]; then
    ok "$dst -> $src"
  else
    fail "$dst points to $actual, expected $src"
  fi
}

printf 'Pi doctor\n'
printf '=========%s' ""
printf '\n\n'

check_dir "$GLOBAL_PI_DIR"
check_dir "$GLOBAL_PI_DIR/extensions"
check_dir "$GLOBAL_PI_DIR/prompts"
check_dir "$GLOBAL_PI_DIR/themes"
check_dir "$HOME/.agents"

printf '\nExtensions\n'
printf '%s\n' '----------'
for extension in "$PI_DIR/extensions"/*.ts; do
  [ -f "$extension" ] || continue
  check_link "$extension" "$GLOBAL_PI_DIR/extensions/$(basename "$extension")"
done

printf '\nPrompt templates\n'
printf '%s\n' '----------------'
for prompt in "$PI_DIR/prompts"/*.md; do
  [ -f "$prompt" ] || continue
  check_link "$prompt" "$GLOBAL_PI_DIR/prompts/$(basename "$prompt")"
done

printf '\nThemes\n'
printf '%s\n' '------'
for theme in "$PI_DIR/themes"/*.json; do
  [ -f "$theme" ] || continue
  check_link "$theme" "$GLOBAL_PI_DIR/themes/$(basename "$theme")"
done

printf '\nSkills\n'
printf '%s\n' '------'
check_link "$DOTFILES_DIR/copilot/skills" "$HOME/.agents/skills"

printf '\nSettings\n'
printf '%s\n' '--------'
settings="$GLOBAL_PI_DIR/settings.json"
if [ -f "$settings" ]; then
  ok "settings file exists: $settings"
  if grep -q '"theme"[[:space:]]*:[[:space:]]*"catppuccin-mocha"' "$settings"; then
    ok 'theme is catppuccin-mocha'
  else
    warn 'theme is not set to catppuccin-mocha in ~/.pi/agent/settings.json'
  fi
else
  warn "missing settings file: $settings"
fi

printf '\nSummary\n'
printf '%s\n' '-------'
if [ "$failures" -eq 0 ]; then
  ok 'Pi customizations look good. Reload open sessions with /reload.'
else
  fail "$failures check(s) failed. Run ~/dotfiles/pi/install.sh and retry."
  exit 1
fi
