---
name: ariadna:debug
description: Systematic debugging with persistent state across context resets
argument-hint: "[issue description]"
allowed-tools:
  - Read
  - Bash
  - Task
  - AskUserQuestion
---
<objective>
Debug issues using scientific method with subagent isolation.

Spawns `ariadna-debugger` with a fresh 200k context per investigation. Orchestrator stays lean: gather symptoms, spawn agent, handle checkpoints and continuations.
</objective>

<context>
Issue: $ARGUMENTS
</context>

<process>
1. Run `ariadna-tools state load` and `ariadna-tools resolve-model ariadna-debugger --raw`.
2. Check for active debug sessions: `ls .ariadna_planning/debug/*.md 2>/dev/null | grep -v resolved`.
3. If active sessions and no $ARGUMENTS: list sessions, let user pick to resume or start new.
4. If new issue: gather 5 symptoms via AskUserQuestion (expected, actual, errors, timeline, reproduction).
5. Spawn `ariadna-debugger` with symptoms; agent creates `.ariadna_planning/debug/{slug}.md`.
6. On `## ROOT CAUSE FOUND`: present cause, offer fix-now / plan-fix / manual.
7. On `## CHECKPOINT REACHED`: collect user response, spawn continuation agent with debug file + response.
8. On `## INVESTIGATION INCONCLUSIVE`: show what was eliminated, offer continue / manual / add context.
</process>
