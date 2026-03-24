---
name: ariadna:quick
description: Execute a quick task with Ariadna guarantees (atomic commits, state tracking) but skip optional agents
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Task
  - AskUserQuestion
---
<objective>
Execute small, ad-hoc tasks with Ariadna guarantees (atomic commits, STATE.md tracking) while skipping optional agents (research, plan-checker, verifier).

- Spawns `ariadna-planner` (quick mode) + `ariadna-executor`
- Quick tasks live in `.ariadna_planning/quick/` separate from planned phases
- Updates STATE.md "Quick Tasks Completed" table (NOT ROADMAP.md)

Use when: You know exactly what to do and the task is small enough to not need research or verification.
</objective>

<context>
Follow the workflow in `~/.claude/ariadna/workflows/quick.md` end-to-end.
</context>

<process>
1. Prompt user for task description via AskUserQuestion.
2. Run `ariadna-tools init quick "$DESCRIPTION"` — validates ROADMAP.md exists; returns slug, next_num, paths.
3. Create `.ariadna_planning/quick/{NNN}-{slug}/` directory.
4. Spawn `ariadna-planner` (quick mode) → produces single PLAN.md with 1-3 focused tasks.
5. Spawn `ariadna-executor` → executes plan, commits atomically, writes SUMMARY.md.
6. Update STATE.md "Quick Tasks Completed" table with row + last activity.
7. Commit STATE.md + plan + summary; display completion with commit hash.
</process>
