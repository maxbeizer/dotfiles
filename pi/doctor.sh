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
if [ -L "$GLOBAL_PI_DIR/extensions/repo-status.ts" ]; then
  fail "obsolete repo-status extension is still linked: $GLOBAL_PI_DIR/extensions/repo-status.ts"
fi
for extension in "$PI_DIR/extensions"/*.ts; do
  [ -f "$extension" ] || continue
  check_link "$extension" "$GLOBAL_PI_DIR/extensions/$(basename "$extension")"
done
for extension_dir in "$PI_DIR/extensions"/*; do
  [ -d "$extension_dir" ] || continue
  [ -f "$extension_dir/index.ts" ] || continue
  check_link "$extension_dir" "$GLOBAL_PI_DIR/extensions/$(basename "$extension_dir")"
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
  settings_report="$(SETTINGS_PATH="$settings" python3 <<'PY'
import json
import os
from pathlib import Path

data = json.loads(Path(os.environ["SETTINGS_PATH"]).read_text())
checks = [
    (data.get("theme") == "catppuccin-mocha", "theme is catppuccin-mocha", "theme is not set to catppuccin-mocha in ~/.pi/agent/settings.json"),
    (data.get("skills") == ["~/.agents/skills"], "skills are limited to ~/.agents/skills", "skills should be limited to ~/.agents/skills for faster startup"),
    (data.get("enableSkillCommands") is True, "skill commands are enabled", "enableSkillCommands is not true in ~/.pi/agent/settings.json"),
    (data.get("quietStartup") is True, "quiet startup is enabled", "quietStartup is not enabled in ~/.pi/agent/settings.json"),
]
for passed, good, bad in checks:
    print(("ok" if passed else "warn") + "\t" + (good if passed else bad))
PY
)"
  while IFS=$'\t' read -r level message; do
    [ -n "$level" ] || continue
    if [ "$level" = "ok" ]; then
      ok "$message"
    else
      warn "$message"
    fi
  done <<< "$settings_report"
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
