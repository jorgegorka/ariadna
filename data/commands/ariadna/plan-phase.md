---
name: ariadna:plan-phase
description: Create detailed execution plan for a phase (PLAN.md) with verification loop
argument-hint: "[phase] [--research] [--skip-research] [--gaps] [--skip-verify] [--skip-context]"
agent: ariadna-planner
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - Task
  - WebFetch
  - mcp__context7__*
---
<objective>
Create executable phase prompts (PLAN.md files) for a roadmap phase. Research skipped by default (Rails conventions pre-loaded). Includes optional inline context gathering (replaces separate discuss-phase step).

**Default flow:** Context (inline if needed) → Plan → Verify → Done

**Orchestrator role:** Parse arguments, validate phase, offer inline context gathering, spawn ariadna-planner (with Rails conventions), verify with ariadna-plan-checker (single pass, inline fixes for minor issues), present results.
</objective>

<execution_context>
@~/.claude/ariadna/workflows/plan-phase.md
@~/.claude/ariadna/references/ui-brand.md
@~/.claude/ariadna/references/rails-conventions.md
</execution_context>

<context>
Phase number: $ARGUMENTS (optional — auto-detects next unplanned phase if omitted)

**Flags:**
- `--research` — Force research even if not enabled in config (for non-standard integrations)
- `--skip-research` — Skip research, go straight to planning (default behavior)
- `--gaps` — Gap closure mode (reads VERIFICATION.md, skips research)
- `--skip-verify` — Skip plan verification
- `--skip-context` — Skip inline context gathering, plan directly

Normalize phase input in step 2 before any directory lookups.
</context>

<process>
Execute the plan-phase workflow from @~/.claude/ariadna/workflows/plan-phase.md end-to-end.
Preserve all workflow gates (validation, research, planning, verification loop, routing).
</process>
