---
name: mikado
description: Guide the user through the Mikado Method for tackling complex refactors and changes. Helps define a goal, discover prerequisites by attempting changes, build a dependency graph, and work bottom-up from leaf nodes. Use when the user says "mikado", "help me break down this refactor", "dependency graph for this change", or wants a structured approach to a large or risky change.
---

Guide me through the Mikado Method to accomplish a goal. The method is an iterative cycle of: set goal → attempt naively → observe what breaks → record prerequisites → revert → repeat until you find leaf nodes → implement leaves bottom-up.

## Process

### 1. Define the Mikado Goal
Ask me to state the top-level change I want to make. Clarify it until it's concrete and testable. This is the root node of our graph.

### 2. The Naive Attempt
Help me attempt the goal directly (or reason through what would break). Run builds, tests, or linters to surface failures. If exploring the codebase can answer what would break, explore instead of guessing.

### 3. Record Prerequisites
For each failure or blocker discovered, create a prerequisite node in the dependency graph. Each prerequisite is itself a smaller goal. Use the session SQL database to track the graph:

```sql
CREATE TABLE IF NOT EXISTS mikado_nodes (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending',  -- pending, in_progress, done, reverted
  parent_id TEXT,                  -- the node this is a prerequisite FOR
  created_at TEXT DEFAULT (datetime('now'))
);
```

### 4. Revert
After recording prerequisites, revert all experimental changes. The working tree should be clean before moving on. Use `git checkout` or `git stash` as appropriate. Never leave broken code committed.

### 5. Find Leaf Nodes
Query the graph for nodes with no pending prerequisites — these are safe to implement now:

```sql
SELECT n.* FROM mikado_nodes n
WHERE n.status = 'pending'
AND NOT EXISTS (
  SELECT 1 FROM mikado_nodes child
  WHERE child.parent_id = n.id AND child.status != 'done'
)
ORDER BY n.created_at;
```

### 6. Implement Leaves
Work on one leaf node at a time. For each leaf:
- Attempt the change
- Run tests/builds to verify it works in isolation
- If it passes, commit it and mark the node `done`
- If it reveals new prerequisites, add them to the graph and revert

### 7. Work Up the Graph
After completing leaves, their parents may now be unblocked. Re-query for new leaf nodes and repeat. Continue until the root goal is achieved.

## During the Session

- After each step, **print the current graph** as an indented tree showing status (✅ done, 🔄 in progress, ⬜ pending).
- Proactively suggest what to attempt next based on the graph state.
- If I get stuck or a prerequisite keeps spawning more prerequisites, help me evaluate whether to restructure the graph or reconsider the approach.
- Keep commits small and green. Each committed change should pass all tests independently.

## Key Principles
- **Never commit broken code** — revert if an attempt fails.
- **Work bottom-up** — only attempt a node when all its children are done.
- **Small, verifiable steps** — each leaf should be a minimal, independently correct change.
- **The graph is the map** — always keep it visible and updated.
