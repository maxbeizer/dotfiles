# Watch Code Review Skill

Wait for Copilot code review to complete on pull requests and notify when done.

## When to Use This Skill

- You've requested a Copilot code review and want to know when it finishes
- Monitoring multiple PRs waiting for Copilot review
- Want to be alerted when Copilot posts inline review comments

## Installation

Copy this directory to `~/.copilot/skills/watch-code-review/`.

## Usage Examples

```
"Watch for Copilot's review on this PR"
"Let me know when Copilot finishes reviewing PR #456"
"Monitor Copilot reviews on my open PRs in github/memex"
```

## How It Works

The skill polls the PR's reviews using `gh`, looking for reviews from `copilot-pull-request-reviewer`. Copilot code review typically posts an initial summary comment quickly, then follows up with inline review comments. The skill waits until the review includes inline comments (the actual code review), not just the overview.

## Prerequisites

- `gh` CLI authenticated with access to the target repository
