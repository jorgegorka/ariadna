---
name: ariadna:quick
description: Execute a quick task with Ariadna guarantees (atomic commits, state tracking) but skip optional agents
argument-hint: ""
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

Quick mode is the same system with a shorter path:
- Spawns ariadna-planner (quick mode) + ariadna-executor(s)
- Skips ariadna-phase-researcher, ariadna-plan-checker, ariadna-verifier
- Quick tasks live in `.planning/quick/` separate from planned phases
- Updates STATE.md "Quick Tasks Completed" table (NOT ROADMAP.md)

Use when: You know exactly what to do and the task is small enough to not need research or verification.
</objective>

<execution_context>
@~/.claude/ariadna/workflows/quick.md
</execution_context>

<context>
@.planning/STATE.md
</context>

<process>
Execute the quick workflow from @~/.claude/ariadna/workflows/quick.md end-to-end.
Preserve all workflow gates (validation, task description, planning, execution, state updates, commits).
</process>
