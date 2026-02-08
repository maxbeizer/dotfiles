# Example: Basic Copilot Review Monitoring

## Scenario 1: Watch a Single PR

**User:** "Watch for Copilot's review on github/memex#24360"

**Agent:**
```
🔍 Monitoring PR #24360 (github/memex) for Copilot code review...

Current state: overview comment posted at 18:46 UTC, waiting for inline comments.
I'll check every 15 seconds and let you know when it's done.
```

*[polls in background]*

```
✅ Copilot finished reviewing PR #24360 (github/memex)

📝 2 inline comments posted
🔗 https://github.com/github/memex/pull/24360

Summary from Copilot:
> Copilot reviewed 1 out of 1 changed files and generated 2 comments.
```

## Scenario 2: Monitor Multiple PRs

**User:** "Let me know when Copilot finishes reviewing my open PRs in agent-skills"

**Agent:**
```
🔍 Found 3 open PRs by @maxbeizer in github/agent-skills. Monitoring for Copilot review:

  PR #16 (Clean up README.md)          — checking...
  PR #15 (Add Datadog skills to README) — checking...
  PR #6  (Security scanning workflow)   — checking...
```

*[polls each]*

```
🔍 Copilot review status update:

  PR #16 — ✅ Review complete (no inline comments)
  PR #15 — ✅ Review complete (1 comment)
  PR #6  — ✅ Review complete (4 comments)

All reviews are in!
```

## Scenario 3: Review Still In Progress

**User:** "Is Copilot done reviewing PR #500?"

**Agent:**
```
🔍 Checking PR #500 (github/memex)...

⏳ Copilot review is still in progress.
   Overview comment posted at 19:02 UTC, but no inline comments yet.

Want me to keep monitoring and alert you when it's done?
```
