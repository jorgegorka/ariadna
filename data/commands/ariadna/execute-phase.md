---
name: ariadna:execute-phase
description: Execute all plans in a phase with wave-based parallelization
argument-hint: "<phase-number> [--gaps-only]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Task
  - TodoWrite
---
<objective>
Execute all plans in a phase using wave-based parallel execution.

Orchestrator stays lean: load context, group plans into waves, spawn `ariadna-executor` subagents, collect results. Each subagent loads its plan and handles its own work.

Context budget: ~10-15% orchestrator, 100% fresh per subagent.
</objective>

<context>
Phase: $ARGUMENTS

- `--gaps-only` — Execute only gap closure plans (`gap_closure: true` in frontmatter). Use after verify-work creates fix plans.

Follow the workflow in `~/.claude/ariadna/workflows/execute-phase.md` end-to-end.
</context>

<process>
1. Run `ariadna-tools init execute-phase "$PHASE_ARG"` to load phase context as JSON.
2. Read `.ariadna_planning/STATE.md` for current project position.
3. Group plans by wave; skip plans where `has_summary: true`.
4. For each wave: spawn `ariadna-executor` per plan in parallel via Task tool.
5. On completion: spawn `ariadna-verifier`, update STATE.md, commit.
6. If gaps found: offer `/ariadna:plan-phase {N} --gaps`.
</process>
