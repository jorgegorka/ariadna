---
name: ariadna:execute-phase
description: Execute all plans in a phase with wave-based parallelization
argument-hint: "<phase-number> [--gaps-only] [--team] [--no-team]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Task
  - TodoWrite
  - AskUserQuestion
  - TeamCreate
  - SendMessage
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TeamDelete
---
<objective>
Execute all plans in a phase using wave-based parallel execution or team-based execution.

Orchestrator stays lean: discover plans, analyze dependencies, group into waves, spawn subagents, collect results. Each subagent loads the full execute-plan context and handles its own plan.

**Execution modes:**
- **Wave mode (default):** Sequential waves of parallel `Task()` spawns. Standard for most phases.
- **Team mode (`--team` flag, `team_execution: true` or `"auto"` in config):** Creates a team with domain-specialized executor agents that coordinate via shared task list. Better for large phases with domain-split plans. When `team_execution: "auto"`, team mode activates for phases with 3+ plans across 2+ non-general domains.

Context budget: ~15% orchestrator, 100% fresh per subagent.
</objective>

<execution_context>
@~/.claude/ariadna/workflows/execute-phase.md
@~/.claude/ariadna/references/ui-brand.md
</execution_context>

<context>
Phase: $ARGUMENTS

**Flags:**
- `--gaps-only` — Execute only gap closure plans (plans with `gap_closure: true` in frontmatter). Use after verify-work creates fix plans.
- `--team` — Use team-based execution with domain-specialized agents instead of wave-based execution.
- `--no-team` — Force wave-based execution even when auto-detection would choose team mode.

@.ariadna_planning/ROADMAP.md
@.ariadna_planning/STATE.md
</context>

<process>
Execute the execute-phase workflow from @~/.claude/ariadna/workflows/execute-phase.md end-to-end.
Preserve all workflow gates (wave/team execution, checkpoint handling, verification, state updates, routing).

**Mode selection:** Follow the `decide_execution_mode` step in the workflow to determine team vs wave execution based on flags, config, and plan analysis.
</process>
