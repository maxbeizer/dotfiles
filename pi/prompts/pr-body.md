---
description: Draft a pull request body from the current branch diff
argument-hint: "[base-branch]"
---
Draft a pull request body for the current branch.

Use base branch `${1:-main}` unless the repo clearly uses a different default branch.

Instructions:

1. Inspect the branch name and compare against the base branch.
2. Review commits and diff summary.
3. Draft a PR body with:
   - Summary
   - Why / context
   - Changes
   - Testing / validation
   - Risks / rollout notes, if relevant
4. Include links to issues/PRs mentioned in commits or diffs when available.

Do not create or update the PR unless I ask.
