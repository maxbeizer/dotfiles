---
name: agent-orchestration
description: This skill should be used when the user asks to "do multiple things at once", "work in parallel", "multitask", "background this", "work on these simultaneously", "split this into parallel work", "orchestrate", or wants to maximize throughput by running multiple agent workstreams concurrently.
version: 1.0.0
---

# Agent Orchestration - Parallel Workstream Management

Maximize productivity by splitting work into independent streams, running tasks in parallel, and efficiently coordinating results.

## When to Use This Skill

- User has multiple independent tasks to complete
- Work can be split into non-conflicting streams
- User wants to keep working while something runs in the background
- Multiple PRs or features need to happen simultaneously
- User wants to minimize idle waiting time

## Core Principle

**Identify independence, then parallelize.** Two tasks can run in parallel if:
1. They don't modify the same files
2. Neither depends on the other's output
3. They can be reviewed/merged independently

If tasks share dependencies, serialize them or split carefully.

## Parallelism Patterns

### Pattern 1: In-Session Parallel (Same Agent)

Use for tasks that can happen simultaneously within one session.

**When:** Multiple independent searches, file reads, or sub-agent tasks.

**How:**
- Launch multiple sub-agents (explore, task) in parallel
- Use parallel tool calls for independent file operations
- Run background bash processes for long-running commands
- Read results as they complete

**Example scenarios:**
- "Search for X in these 3 repos" → 3 parallel explore agents
- "Run tests AND lint" → background bash for each
- "Read these 5 files" → 5 parallel file reads

**Best for:** Research, exploration, builds, tests, file operations

### Pattern 2: Background Task (Same Session)

Use for long-running operations while continuing other work.

**When:** CI monitoring, builds, test suites, installations.

**How:**
```bash
# Start long-running task in background
command &

# Continue working on other things
# Check back later
```

**Example scenarios:**
- "Watch CI and let me know" → background, keep coding
- "Run the full test suite" → background, work on docs
- "Build the project" → background, review other files

**Best for:** Anything that takes >30 seconds where you don't need to watch output

### Pattern 3: Multi-Terminal (Multiple Agents)

Use for truly independent workstreams that each need a full agent.

**When:** Different features, different repos, different PRs.

**Setup:**
```bash
# Terminal 1: Feature A
git worktree add ../ws-feature-a -b feature-a
cd ../ws-feature-a
# Start copilot session: "Build feature A..."

# Terminal 2: Feature B
git worktree add ../ws-feature-b -b feature-b
cd ../ws-feature-b
# Start copilot session: "Build feature B..."

# Terminal 3: Keep working on main
cd /path/to/main
# Start copilot session: "While those run, let's..."
```

**Cleanup:**
```bash
git worktree list              # See all worktrees
git worktree remove ../ws-*    # Clean up when done
```

**Best for:** Multiple PRs, cross-repo work, large independent features

### Pattern 4: Pipeline (Serial with Parallel Stages)

Use when work has stages, but within each stage things can parallelize.

**When:** Multi-step processes with independent sub-tasks per step.

**Example:**
```
Stage 1 (parallel): Research
  ├─ Agent A: Explore codebase for patterns
  ├─ Agent B: Read documentation
  └─ Agent C: Check existing tests

Stage 2 (serial): Plan
  └─ Synthesize findings into plan

Stage 3 (parallel): Implement
  ├─ Agent A: Write feature code
  └─ Agent B: Write tests

Stage 4 (serial): Integrate
  └─ Run tests, fix conflicts, create PR
```

**Best for:** Large features, refactors, migrations

## Decision Framework

Ask yourself:

```
Can these tasks run independently?
├─ YES: Do they need separate git branches?
│   ├─ YES → Pattern 3: Multi-Terminal
│   └─ NO → Pattern 1: In-Session Parallel
└─ NO: Can they be pipelined?
    ├─ YES → Pattern 4: Pipeline
    └─ NO → Just do them sequentially

Is there a long-running task?
├─ YES → Pattern 2: Background Task
└─ NO → Just do it inline
```

## Splitting Work Effectively

### Good Splits (Independent)

```
✅ "Create 3 new skills"
   → Each skill is in its own directory, no conflicts

✅ "Update README and fix bug in auth"
   → Different files, different concerns

✅ "Add tests for module A and refactor module B"
   → Different modules, no shared code

✅ "Work on frontend PR and backend PR"
   → Different repos or clear separation
```

### Bad Splits (Will Conflict)

```
❌ "Rename function X" + "Add calls to function X"
   → Second task depends on first completing

❌ "Refactor database layer" + "Add new database model"
   → Both touch same files/patterns

❌ "Update shared types" + "Use those types in new feature"
   → Dependency between tasks
```

### Tricky Splits (Need Care)

```
⚠️ "Add feature A and feature B to same service"
   → May share config files, routes, etc.
   → Split: Feature code parallel, integration serial

⚠️ "Multiple PRs to same repo"
   → Base branch may shift as PRs merge
   → Split: Use worktrees, merge one at a time
```

## Giving Instructions to Parallel Agents

When spinning up multiple terminals/agents, give each clear, complete context:

**Good instruction (self-contained):**
```
You're working in the agent-skills repository on branch 'add-docker-skill'.
Create a new skill called 'docker-debugging-skill' that helps
debug Docker containers. Follow the patterns in watch-ci-skill/
for structure. Create a PR when done.
```

**Bad instruction (depends on shared context):**
```
Add the next skill from the list.
```

**Key principles:**
- Each agent should have everything it needs in the prompt
- Specify the branch name explicitly
- Reference existing patterns for consistency
- Define "done" clearly (PR created, tests pass, etc.)

## Monitoring Parallel Work

### Check In Pattern

When running multiple streams:

1. Start all parallel work
2. Continue with your own tasks
3. Periodically check:
   - "What's the status of the background build?"
   - Switch terminals to check agent progress
   - Review PRs as they come in
4. Handle any failures
5. Clean up worktrees

### Merge Strategy

When parallel PRs are ready:

1. Review PRs independently
2. Merge one at a time (avoid merge conflicts)
3. Let CI run between merges
4. If conflict: rebase the remaining PR
5. Clean up branches and worktrees

## Boundaries

**Will:**
- Help identify parallelizable work
- Set up worktrees and branches
- Run background tasks
- Launch parallel sub-agents
- Coordinate results

**Will Not:**
- Guarantee conflict-free merges
- Run more agents than terminals available
- Parallelize inherently serial work
- Manage worktrees in other users' repos
