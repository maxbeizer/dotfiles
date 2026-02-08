# Copilot CLI Configs

Version-controlled configs for [GitHub Copilot CLI](https://githubnext.com/projects/copilot-cli/).

## What's tracked

- `config.json` — Copilot CLI preferences (model, theme, log level, etc.)
- `mcp-config.json` — MCP server configurations
- `skills/` — Personal Copilot skills (e.g., agent-orchestration)

## Setup

Run from the dotfiles-local root:

```bash
./install-copilot.sh
```

This symlinks everything into `~/.copilot/`. It's idempotent — safe to run
multiple times. Existing files are backed up as `*.backup` before being replaced.

## Machine-specific notes

- `config.json` contains `trusted_folders` with absolute paths — update these
  per machine or let Copilot CLI manage them after linking.
- `mcp-config.json` may reference local paths for MCP servers (e.g.,
  `hubbers-mcp-server`). Update these to match your local checkout locations.
- Auth/login state in `config.json` is managed by `copilot auth login` and
  doesn't need manual setup.
