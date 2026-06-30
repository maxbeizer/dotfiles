---
description: Fetch and fix GitHub Copilot PR review suggestions
argument-hint: "<PR-URL-or-number> [instructions]"
---
Handle Copilot code review suggestions for this pull request: `$1`.

Additional instructions, if any: `${@:2}`

Workflow:

1. Identify the PR repository and number.
   - If `$1` is a full GitHub PR URL, parse owner, repo, and PR number from it.
   - If `$1` is only a number, use the current repository.
   - If no PR is provided, try `gh pr view --json number,url,headRefName,baseRefName` in the current repository.
2. Fetch PR metadata:
   - `gh pr view <PR> --repo <OWNER/REPO> --json title,url,state,author,headRefName,baseRefName,reviewDecision,reviews`
3. Fetch Copilot review comments, including file paths and diff context:
   - `gh api repos/<OWNER>/<REPO>/pulls/<PR>/comments --paginate`
   - Treat these author logins as Copilot: `Copilot`, `copilot`, `copilot-pull-request-reviewer`, `copilot-pull-request-reviewer[bot]`, `github-copilot[bot]`.
4. Summarize the Copilot suggestions before editing.
   - Group by file.
   - Include the comment text and affected location when available.
   - If there are no Copilot comments, say so and stop unless I gave additional instructions.
5. Get the PR branch locally.
   - Prefer a git worktree over switching branches in the current worktree.
   - If already in the correct repo/branch/worktree, use it.
   - Otherwise use `gh pr checkout <PR> --repo <OWNER/REPO>` only when it is safe, or create a sibling worktree for the PR branch.
6. Apply straightforward fixes for Copilot's comments.
   - Keep changes minimal and targeted.
   - Do not broaden the scope beyond Copilot's review unless explicitly instructed.
   - Preserve repository style and existing conventions.
7. Validate appropriately.
   - Run the smallest relevant formatter, linter, or test command you can identify.
   - If validation is unnecessary or unavailable, explain why.
8. Show the resulting diff and summarize what changed.
9. Ask before committing or pushing.
   - Do not commit or push unless I explicitly confirm.

Be careful with private/internal repository content. Do not paste large sensitive diffs into the final response; summarize and reference file paths instead.
