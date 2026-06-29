---
description: Run relevant tests for current changes
argument-hint: "[focus-or-command]"
---
Run relevant tests for the current changes.

Instructions:

1. Inspect project docs/build files and changed files.
2. Choose the fastest relevant validation first.
3. If I provided a focus or command, prioritize it: `$ARGUMENTS`.
4. Run tests/lint/typecheck as appropriate.
5. Summarize:
   - commands run
   - pass/fail result
   - key failures with file paths
   - suggested next fixes

Ask before running very expensive, destructive, network-heavy, or production-affecting commands.
