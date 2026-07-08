# Global Pi agent instructions

## GitHub URL handling

When the user pastes a GitHub URL, prefer the authenticated `gh` CLI over unauthenticated web fetches. This applies to issues, PRs, discussions, commits, checks, and specific issue/PR/discussion comments.

- Use `gh issue view`, `gh pr view`, `gh discussion view`, `gh api`, or `gh search` as appropriate so private GitHub and enterprise resources work.
- For direct comment anchors such as `#issuecomment-123`, fetch the specific comment with `gh api repos/OWNER/REPO/issues/comments/123` when the standard view command does not include it.
- Respect the URL hostname. Use the matching `gh --hostname ...` / `GH_HOST` path for enterprise hosts when needed.
- Treat pasted GitHub links as read-only context by default. Do not post comments, update issues/PRs, change labels, merge, close, approve, or otherwise mutate GitHub state unless the user explicitly asks.
- If `gh` cannot access the resource, report the authenticated CLI failure and ask for pasted content rather than falling back to assuming the resource is public.
