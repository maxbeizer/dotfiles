# Agent bootstrap guide

Use this guide when an agent is setting up a machine with this dotfiles-local overlay.

## Goal
Set up thoughtbot base dotfiles + local overrides, then verify shell ergonomics.

## One-command bootstrap (recommended)
```bash
~/dotfiles-local/bin/bootstrap-machine
```

Useful flags:
```bash
~/dotfiles-local/bin/bootstrap-machine --dry-run
~/dotfiles-local/bin/bootstrap-machine --skip-verify
```

## Manual fallback
```bash
git clone https://github.com/thoughtbot/dotfiles.git ~/dotfiles
git clone https://github.com/maxbeizer/dotfiles.git ~/dotfiles-local
brew install rcm
env RCRC="$HOME/dotfiles/rcrc" rcup
```

## Verification checklist
```bash
zsh -lic 'echo shell-ok'
rcup -v
vim --version | head -n 1
```

Expected: no startup errors and `rcup` exits cleanly.

## Rehearse setup in a fresh macOS VM
This is a good practice, not gauche.

1. Create a VM in UTM, VirtualBuddy, or Parallels.
2. Easiest path: let the VM app download macOS directly from Apple.
3. Optional manual installer on host:
   ```bash
   softwareupdate --list-full-installers
   softwareupdate --fetch-full-installer --full-installer-version <version>
   ```
4. In the fresh VM:
   ```bash
   git clone https://github.com/maxbeizer/dotfiles.git ~/dotfiles-local
   ~/dotfiles-local/bin/bootstrap-machine
   ```
5. Save a clean snapshot before each rehearsal run.
