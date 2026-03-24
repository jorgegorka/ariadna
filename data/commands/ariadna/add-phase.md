---
name: ariadna:add-phase
description: Add phase to end of current milestone in roadmap
argument-hint: <description>
allowed-tools:
  - Read
  - Write
  - Bash
---
<objective>
Add a new integer phase to the end of the current milestone in the roadmap.

Handles: next phase number calculation, directory creation, roadmap entry insertion, STATE.md roadmap evolution tracking.
</objective>

<context>
Description: $ARGUMENTS

Follow the workflow in `~/.claude/ariadna/workflows/add-phase.md` end-to-end.
</context>

<process>
1. Validate $ARGUMENTS provided; error with usage if missing.
2. Run `ariadna-tools init phase-op "0"` — check `roadmap_exists`.
3. Run `ariadna-tools phase add "$ARGUMENTS"` — calculates next number, creates directory, updates ROADMAP.md.
4. Update STATE.md "Roadmap Evolution" section with entry.
5. Display new phase number, directory, and next step: `/ariadna:plan-phase {N}`.
</process>
