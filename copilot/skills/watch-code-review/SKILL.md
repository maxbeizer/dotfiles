---
name: watch-code-review
description: This skill should be used when the user asks to "watch for Copilot review", "wait for code review", "let me know when Copilot finishes reviewing", "monitor Copilot review", "watch code review", "alert when review is done", or needs to poll for Copilot pull request review completion.
version: 1.0.0
---

# Watch Code Review - Wait for Copilot Review Completion

Monitors pull requests for Copilot code review completion and notifies when the review (including inline comments) is done.

## When to Use This Skill

- User requested a Copilot code review and wants to know when it's done
- User sees "Copilot started reviewing" on a PR and wants an alert when finished
- Monitoring multiple PRs for Copilot review completion
- User wants to continue working while waiting for Copilot review

## Background: How Copilot Code Review Works

Copilot code review (`copilot-pull-request-reviewer`) typically posts in two phases:
1. **Initial overview comment** — a summary of the PR posted quickly (state: `COMMENTED`)
2. **Inline review comments** — detailed code-level feedback posted shortly after

The review is **not complete** until inline comments appear (or the overview explicitly says "no comments"). The skill must detect phase 2 completion.

## Core Functionality

### 1. Identify Target PR(s)

Determine which PR(s) to monitor:

**Priority order:**
1. Explicit PR number provided by user (`PR #123`)
2. Explicit repo + PR (`github/memex#24360`)
3. Current branch's associated PR
4. All open PRs by user in a given repo

**Detect current PR:**
```bash
gh pr view --json number,title,url -q '.number'
```

**List user's open PRs in a repo:**
```bash
gh pr list --repo OWNER/REPO --author @me --state open --json number,title
```

### 2. Check Review Status

Query reviews and review comments to determine if Copilot has finished:

**Get reviews from Copilot:**
```bash
gh pr view PR_NUMBER --repo OWNER/REPO --json reviews \
  --jq '[.reviews[] | select(.author.login == "copilot-pull-request-reviewer") | {state: .state, submittedAt: .submittedAt, bodyLength: (.body | length)}]'
```

**Get inline review comments from Copilot:**
```bash
gh api repos/OWNER/REPO/pulls/PR_NUMBER/comments \
  --jq '[.[] | select(.user.login == "copilot-pull-request-reviewer") | {path: .path, body: .body, created_at: .created_at}]'
```

### 3. Determine Completion

The Copilot review is **complete** when ANY of these are true:

1. **Inline comments exist** from `copilot-pull-request-reviewer` via the review comments API
2. **The overview review body** contains phrases like:
   - "Copilot reviewed X out of Y changed files"
   - "no comments" or "No concerns"
   - A "Reviewed changes" table
3. **A review with state `APPROVED` or `CHANGES_REQUESTED`** exists from `copilot-pull-request-reviewer`

The review is **still in progress** when:
- Only a brief overview comment exists with no inline comments
- The overview doesn't contain a "Reviewed changes" table or completion indicators

### 4. Poll Loop

**Polling strategy:**
- Initial interval: 15 seconds (Copilot reviews usually complete within 1-5 minutes)
- Max interval: 30 seconds
- Default timeout: 15 minutes
- Check both the reviews list AND the review comments endpoint each iteration

```bash
PR_NUMBER=123
REPO="owner/repo"
TIMEOUT=900  # 15 minutes
INTERVAL=15
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
  # Check for inline review comments from Copilot
  COMMENT_COUNT=$(gh api "repos/$REPO/pulls/$PR_NUMBER/comments" \
    --jq '[.[] | select(.user.login == "copilot-pull-request-reviewer")] | length')

  if [ "$COMMENT_COUNT" -gt 0 ]; then
    echo "✅ Copilot review complete — $COMMENT_COUNT inline comment(s)"
    break
  fi

  # Check if overview indicates completion with no inline comments
  REVIEW_BODY=$(gh pr view "$PR_NUMBER" --repo "$REPO" --json reviews \
    --jq '[.reviews[] | select(.author.login == "copilot-pull-request-reviewer")][0].body')

  if echo "$REVIEW_BODY" | grep -qi "Copilot reviewed.*changed files"; then
    echo "✅ Copilot review complete (with reviewed files summary)"
    break
  fi

  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
  echo "⏱️  Timed out after $((TIMEOUT/60)) minutes — review may still be in progress"
fi
```

### 5. Run as Background Task

**Important:** Always run as a background task so the user can keep working.

Use async bash with periodic reads to poll. Notify the user via the chat when complete.

### 6. Notify on Completion

**On review complete with comments:**
```
✅ Copilot finished reviewing PR #123 (owner/repo)

📝 3 inline comments posted
🔗 https://github.com/owner/repo/pull/123

Summary from Copilot:
> Copilot reviewed 5 out of 5 changed files and generated 3 comments.
```

**On review complete with no comments:**
```
✅ Copilot finished reviewing PR #456 (owner/repo)

👍 No inline comments — looks clean!
🔗 https://github.com/owner/repo/pull/456
```

**On timeout:**
```
⏱️  Copilot review for PR #789 hasn't completed after 15 minutes.

Current state: overview comment posted, no inline comments yet.
🔗 https://github.com/owner/repo/pull/789

The review may still complete — you can re-run this check or visit the PR.
```

## Multi-PR Monitoring

When watching multiple PRs:

```bash
# Check all user's open PRs in a repo for pending Copilot reviews
gh pr list --repo OWNER/REPO --author @me --state open --json number,title \
  --jq '.[] | "\(.number) \(.title)"'
```

Poll each PR independently. Report status as each completes:
```
🔍 Monitoring 3 PRs for Copilot review:

  PR #100 (Add feature)     — ✅ Review complete (2 comments)
  PR #101 (Fix bug)         — ✅ Review complete (no comments)
  PR #102 (Update docs)     — ⏳ Still waiting...
```

## Error Handling

### PR Not Found
```bash
if ! gh pr view PR_NUMBER --repo OWNER/REPO &>/dev/null; then
    echo "❌ PR #$PR_NUMBER not found in $REPO"
    echo "Available PRs:"
    gh pr list --repo OWNER/REPO --limit 10
fi
```

### No Copilot Review Requested
```bash
REVIEWS=$(gh pr view PR_NUMBER --repo OWNER/REPO --json reviews \
  --jq '[.reviews[] | select(.author.login == "copilot-pull-request-reviewer")] | length')

if [ "$REVIEWS" -eq 0 ]; then
    echo "⚠️  No Copilot review found on PR #$PR_NUMBER"
    echo "Copilot code review may not have been requested for this PR."
fi
```

### Authentication Issues
```bash
if ! gh auth status &>/dev/null; then
    echo "❌ Not authenticated with GitHub"
    echo "Run: gh auth login"
fi
```

## Boundaries

**Will:**
- Poll for Copilot code review completion on specified PRs
- Detect both inline comments and overview-only reviews
- Monitor multiple PRs simultaneously
- Notify with summary of review findings
- Run as background task by default

**Will Not:**
- Request Copilot reviews (only monitors existing ones)
- Modify PRs or respond to review comments
- Monitor non-Copilot reviewers (use watch-ci for CI checks)
- Continue monitoring beyond 15-minute timeout (configurable)
- Work with repos the user doesn't have access to

## Quick Reference

**Key commands:**
```bash
# Check if Copilot has reviewed
gh pr view 123 --repo owner/repo --json reviews \
  --jq '[.reviews[] | select(.author.login == "copilot-pull-request-reviewer")]'

# Check for inline comments
gh api repos/owner/repo/pulls/123/comments \
  --jq '[.[] | select(.user.login == "copilot-pull-request-reviewer")]'

# Get PR URL
gh pr view 123 --repo owner/repo --json url -q .url
```
