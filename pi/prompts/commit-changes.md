---
description: Inspect, group, and commit current changes
argument-hint: "[commit-message-or-focus]"
---
Help me commit the current changes.

Instructions:

1. Inspect `git status --short` and relevant diffs.
2. Identify logical commit groups. If there is more than one logical group, propose the groups before staging.
3. Run relevant lightweight validation if obvious from the repo.
4. Stage only the files for the approved logical group.
5. Write a concise commit message. If I provided text, use it as guidance: `$ARGUMENTS`.
6. Commit, then show the resulting commit hash and remaining status.

Ask before committing if the changes are sensitive, ambiguous, or span multiple logical groups.
