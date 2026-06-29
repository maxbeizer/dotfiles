# Pi Customizations

Global customizations for the [Pi coding agent](https://pi.dev), managed from dotfiles and linked into `~/.pi/agent/` by `pi/install.sh`.

## Install

```bash
~/dotfiles/pi/install.sh
~/dotfiles/pi/install.sh --dry-run
```

The main dotfiles installer also runs this:

```bash
~/dotfiles/install.sh
```

After changing extensions, prompts, themes, or skills, reload open Pi sessions:

```text
/reload
```

## Doctor

Check that global Pi symlinks and settings are in place:

```bash
~/dotfiles/pi/doctor.sh
```

## Global Extensions

Source: `~/dotfiles/pi/extensions/`

Linked to: `~/.pi/agent/extensions/`

| Extension | Commands | Purpose |
|-----------|----------|---------|
| `repo-status.ts` | `/repo-status` | Shows current git branch and dirty-file count in the footer/status area. |
| `safety.ts` | `/allow-repo`, `/allow-repo list`, `/allow-repo clear` | Confirms dangerous commands and sensitive edits; supports session-scoped mutation allowlists. |
| `vault-vibes.ts` | `/vibe`, `/vibe vault`, `/vibe quiet`, `/vibe default` | Catppuccin-friendly working indicator and message. |
| `prompt-hint.ts` | `/prompt-hint`, `/prompt-hint list`, `/prompt-hint clear`, `/prompts` | Shows prompt-template reminders and a picker for global prompts. |

## Global Prompt Templates

Source: `~/dotfiles/pi/prompts/`

Linked to: `~/.pi/agent/prompts/`

| Prompt | Purpose |
|--------|---------|
| `/review-changes [focus]` | Review current git changes for correctness, risk, security, and missing tests. |
| `/commit-changes [commit-message-or-focus]` | Inspect, group, validate, and commit current changes. |
| `/pr-body [base-branch]` | Draft a pull request body from the current branch diff. |
| `/explain-repo [focus]` | Explain repository structure, commands, and workflows. |
| `/find-tests [focus-or-path]` | Discover relevant test, lint, and typecheck commands. |
| `/run-tests [focus-or-command]` | Run the fastest relevant validation and summarize results. |

Use `/prompts` to pick from these without remembering the names.

## Theme

Source: `~/dotfiles/pi/themes/catppuccin-mocha.json`

Linked to: `~/.pi/agent/themes/catppuccin-mocha.json`

Selected globally in `~/.pi/agent/settings.json`:

```json
"theme": "catppuccin-mocha"
```

## Skills

Shared Agent Skills live in:

```text
~/dotfiles/copilot/skills/
```

`pi/install.sh` links them to:

```text
~/.agents/skills -> ~/dotfiles/copilot/skills
```

Currently useful skills:

- `/skill:agent-orchestration`
- `/skill:grill-me`
- `/skill:mikado`

## Adding a new prompt

1. Create `~/dotfiles/pi/prompts/name.md` with frontmatter:

   ```markdown
   ---
   description: Short autocomplete description
   argument-hint: "[optional-args]"
   ---
   Prompt body here.
   ```

2. Run:

   ```bash
   ~/dotfiles/pi/install.sh
   ```

3. Reload Pi:

   ```text
   /reload
   ```

## Adding a new extension

1. Create `~/dotfiles/pi/extensions/name.ts`.
2. Run `~/dotfiles/pi/install.sh`.
3. Reload Pi with `/reload`.
4. Update this README and `~/dotfiles/CHANGELOG.md` if the change is notable.

## Adding a new theme

1. Create `~/dotfiles/pi/themes/name.json`.
2. Run `~/dotfiles/pi/install.sh`.
3. Select it with `/settings` or update `~/.pi/agent/settings.json`.

Theme files hot-reload after selection.
