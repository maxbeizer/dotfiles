---
description: Review current git changes for correctness and risk
argument-hint: "[focus]"
---
Review the current repository changes.

Instructions:

1. Inspect `git status --short`.
2. Inspect unstaged and staged diffs (`git diff` and `git diff --cached`).
3. If there are many changes, summarize by file first.
4. Review for:
   - bugs and logic errors
   - edge cases
   - security/privacy concerns
   - performance risks
   - missing tests or docs
   - maintainability issues
5. If a focus was provided, prioritize it: `$ARGUMENTS`.

Do not modify files unless I explicitly ask. Return findings grouped by severity, with file paths and concrete suggestions.
