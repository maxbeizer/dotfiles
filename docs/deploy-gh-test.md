# Deploying gh-test to a Codespace

The `gh-test` extension is a Go CLI tool. Since codespaces run Linux/amd64 and local dev is macOS/arm64, the binary must be cross-compiled before deploying.

## Prerequisites

- Go installed locally (check with `go version`)
- `gh` CLI authenticated
- The `gh-test` repo cloned at `~/code/github/gh-test` (or set `GH_TEST_DIR`)

## Automatic deploy with `gh new-cs`

The `gh new-cs` alias runs `deploy-gh-test` automatically after creating a new github/github codespace. No extra steps needed — `gh-test` is installed and shimmed as part of codespace creation.

## Manual deploy

```bash
# Deploy to the first available codespace
deploy-gh-test

# Deploy to a codespace by display name
deploy-gh-test primary

# Deploy to a codespace by full name
deploy-gh-test primary-xrpjgxqjv92v4r6
```

## What the script does

1. Resolves the codespace display name to the full codespace identifier
2. Creates the `gh` extension directory on the codespace (`~/.local/share/gh/extensions/gh-test/`)
3. Cross-compiles `gh-test` for `linux/amd64` via `make deploy`
4. Pipes the binary over SSH into the extension directory
5. Runs `gh test shim --rails` on the codespace to set up the test shim

## Manual steps (if not using the script)

```bash
# 1. Find your codespace name
gh cs list --json name,displayName,state

# 2. Create the extension directory
gh codespace ssh -c <CODESPACE_NAME> -- \
  'mkdir -p /home/vscode/.local/share/gh/extensions/gh-test'

# 3. Cross-compile and deploy
cd /path/to/gh-test
make deploy CODESPACE=<CODESPACE_NAME>
```

## Gotchas

- **macOS binary won't work on Linux** — you _must_ cross-compile. The Makefile's `build-linux` target handles this (`GOOS=linux GOARCH=amd64 CGO_ENABLED=0`).
- **`gh codespace cp` has quoting bugs** — the Makefile uses `cat | gh cs ssh` to pipe the binary instead, which is more reliable.
- **Extension directory must exist first** — `gh` won't create it automatically when deploying manually. The script handles this.
- **Display name ≠ codespace name** — `gh` commands need the full codespace name (e.g. `primary-xrpjgxqjv92v4r6`), not the display name (`primary`). The script resolves this for you.

## Overriding the gh-test repo location

If `gh-test` isn't at `~/code/github/gh-test`, set `GH_TEST_DIR`:

```bash
GH_TEST_DIR=~/code/gh-test bin/deploy-gh-test primary
```
