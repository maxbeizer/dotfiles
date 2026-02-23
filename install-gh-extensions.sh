#!/bin/bash
#
# Install gh CLI extensions.
# Idempotent: safe to run multiple times — already-installed extensions are skipped.
#

set -e

fancy_echo() {
  printf "\n%s\n" "$1"
}

extensions=(
  ebonsignori/gh-ask-docs
  github/gh-aw
  github/gh-bother
  kmcq/gh-combine-dependabot-prs
  maxbeizer/gh-contrib
  maxbeizer/gh-rdm
  github/gh-discussions
  zerowidth/gh-md
  github/gh-merge-queue
  github/gh-models
  andyfeller/gh-montage
  github/gh-projects
  vilmibm/gh-screensaver
  ebonsignori/gh-search-docs
  github/gh-shell
  github/gh-skills
  rneatherway/gh-slack
  github/gh-standardize
  github/gh-thehub
)

fancy_echo "Installing gh CLI extensions..."

for ext in "${extensions[@]}"; do
  name="${ext#*/}"
  if gh extension list 2>/dev/null | grep -q "$name"; then
    echo "  ✓ already installed: $name"
  else
    echo "  → installing: $ext"
    gh extension install "$ext"
  fi
done

fancy_echo "gh CLI extensions installed ✓"
