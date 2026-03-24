---
name: ariadna:plan-phase
description: Create detailed execution plan for a phase (PLAN.md) with verification loop
argument-hint: "[phase] [--research] [--gaps] [--skip-verify]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
  - WebFetch
  - mcp__context7__*
---
<objective>
Produce PLAN.md files that `execute-phase` can run directly. Plans must have valid frontmatter (wave, domain, depends_on, files_modified) with tasks specific enough for autonomous execution.

Spawn `ariadna-planner` for planning and self-checking. Minor issues fixed inline; major issues presented to user.
</objective>

<context>
Phase: $ARGUMENTS (optional — auto-detects next unplanned phase if omitted)

- `--research` — Force research for non-standard integrations
- `--gaps` — Gap closure mode: reads VERIFICATION.md, creates `gap_closure: true` plans only
- `--skip-verify` — Skip plan self-check pass

Follow the workflow in `~/.claude/ariadna/workflows/plan-phase.md` end-to-end.
</context>

<process>
1. Run `ariadna-tools init plan-phase "$PHASE_ARG" --include state,roadmap,requirements,context,research,verification`.
2. Spawn `ariadna-planner` with rails-conventions reference; planner handles research and self-check inline.
3. Fix minor issues (wrong wave, missing tags, frontmatter typos) with Edit tool — no re-spawn.
4. Update `memory/progress.md`; display next step: `/ariadna:execute-phase {N}` with `/clear` reminder.
</process>
