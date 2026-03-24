---
name: ariadna:progress
description: Check project progress, show context, and route to next action (execute or plan)
allowed-tools:
  - Read
  - Bash
  - Grep
  - Glob
  - SlashCommand
---
<objective>
Check project progress, summarize recent work and what's ahead, then intelligently route to the next action — either executing an existing plan or creating the next one.

Provides situational awareness before continuing work.
</objective>

<context>
Follow the workflow in `~/.claude/ariadna/workflows/progress.md` end-to-end.
</context>

<process>
1. Run `ariadna-tools init progress --include state,roadmap,project,config` to load context as JSON.
2. Run `ariadna-tools roadmap analyze` for structured phase/plan status.
3. Find 2-3 recent SUMMARY.md files; extract one-liners with `ariadna-tools summary-extract`.
4. Generate progress bar: `ariadna-tools progress bar --raw`.
5. Present rich status report: recent work, current position, decisions, blockers, pending todos.
6. Route to next action based on verified plan/summary counts:
   - UAT gaps present → `/ariadna:plan-phase {N} --gaps`
   - Unexecuted plans → `/ariadna:execute-phase {N}`
   - Phase needs planning → `/ariadna:plan-phase {N}`
   - Phase complete, more remain → `/ariadna:discuss-phase {N+1}`
   - Milestone complete → `/ariadna:complete-milestone`
   - Between milestones → `/ariadna:new-milestone`
</process>
