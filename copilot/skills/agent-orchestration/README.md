# Agent Orchestration Skill

A personal skill for maximizing throughput by running multiple agent workstreams in parallel.

## What It Does

When you say things like "do these in parallel", "multitask this", or "work on these simultaneously", this skill kicks in with:

- **Pattern selection** — picks the right parallelism approach for your tasks
- **Work splitting** — identifies what can safely run concurrently vs. what must be serial
- **Worktree setup** — creates isolated working directories for multi-branch work
- **Agent coordination** — manages background tasks and parallel sub-agents

## Quick Examples

### "Create 3 skills at once"
→ In-session parallel: launches 3 sub-agents simultaneously

### "Run tests while I work on docs"
→ Background task: tests run async, you keep coding

### "Build feature A and feature B as separate PRs"
→ Multi-terminal: worktrees + separate agent sessions

### "Research, plan, then implement in parallel"
→ Pipeline: parallel research → serial planning → parallel implementation
