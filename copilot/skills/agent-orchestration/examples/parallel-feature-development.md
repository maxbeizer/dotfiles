# Example: Parallel Feature Development

You're working on `github/agent-skills` and need to create two new skills and update the README — three independent tasks perfect for parallelization.

## The Ask

> "I need a docker-debugging skill, a datadog-monitor-setup skill, and the README updated to list them both. Do as much in parallel as possible."

## How the Agent Handles It

### Step 1: Analyze Independence

```
Task A: Create docker-debugging-skill/     → own directory, no conflicts
Task B: Create datadog-monitor-setup-skill/ → own directory, no conflicts
Task C: Update README.md                   → depends on A and B completing
```

**Decision:** A and B are fully parallel. C must wait (Pipeline pattern).

### Step 2: Parallel Implementation

The agent uses **Pattern 4 (Pipeline)** with **Pattern 1 (In-Session Parallel)** for the parallel stages:

```
Stage 1 (parallel):
  ├─ Sub-agent A: Create docker-debugging-skill/
  │   ├─ README.md
  │   ├─ SKILL.md
  │   └─ examples/
  └─ Sub-agent B: Create datadog-monitor-setup-skill/
      ├─ README.md
      ├─ SKILL.md
      └─ examples/

Stage 2 (serial, after both complete):
  └─ Update README.md to list both new skills
```

### Step 3: Integration

After both sub-agents complete, the main agent:
1. Reviews the created files for consistency
2. Updates README.md with both new skill listings
3. Commits all changes together
4. Creates a PR

## Multi-Terminal Variant

If these were bigger features requiring separate PRs:

```bash
# Terminal 1
git worktree add ../ws-docker-skill -b add-docker-skill
cd ../ws-docker-skill
# "Create docker-debugging-skill following watch-ci-skill patterns. Make a PR."

# Terminal 2
git worktree add ../ws-datadog-skill -b add-datadog-skill
cd ../ws-datadog-skill
# "Create datadog-monitor-setup-skill following watch-ci-skill patterns. Make a PR."

# Terminal 3 (main)
# "While those run, let's update the contributing guide..."
```

Then merge PRs one at a time, updating README after both land.

## Key Takeaway

The agent recognized that **directory-isolated work** (each skill in its own folder) is the ideal case for parallelization — no file conflicts, clear boundaries, independently reviewable.
