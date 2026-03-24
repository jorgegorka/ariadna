---
name: quick
description: Execute a small ad-hoc task with Ariadna guarantees — atomic commits and STATE.md tracking — without the full phase workflow.
---

## Goal
Run a focused, self-contained task outside the planned phase cycle. Spawns a planner (quick mode, 1-3 tasks) and an executor, commits artifacts, and records the task in STATE.md's "Quick Tasks Completed" table.

## Context Loading
```bash
INIT=$(ariadna-tools init quick "$DESCRIPTION")
```
Ask the user for `$DESCRIPTION` first via AskUserQuestion if not provided. Parse: `planner_model`, `executor_model`, `next_num`, `slug`, `task_dir`, `roadmap_exists`. If `roadmap_exists` is false, error — run `/ariadna:new-project` first.

## Constraints
- One plan per quick task (1-3 focused tasks inside the plan); no research, no plan-checker, no verifier
- Executor must NOT update ROADMAP.md — quick tasks are separate from planned phases
- Task directory: `.ariadna_planning/quick/{NNN}-{slug}/`; numbered sequentially (001, 002…)
- Both `{NNN}-PLAN.md` and `{NNN}-SUMMARY.md` must exist before STATE.md update
- If executor returns `classifyHandoffIfNeeded` error, check for summary file + git log before treating as failure

## Success Criteria
- `{NNN}-PLAN.md` and `{NNN}-SUMMARY.md` exist in the task directory
- STATE.md "Quick Tasks Completed" table updated with task row and "Last activity" line
- All artifacts committed atomically

## On Completion
Display task number, description, summary path, and commit hash. Offer `/ariadna:quick` for the next ad-hoc task.
