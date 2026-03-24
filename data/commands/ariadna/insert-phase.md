---
name: ariadna:insert-phase
description: Insert urgent work as decimal phase (e.g., 72.1) between existing phases
argument-hint: <after> <description>
allowed-tools:
  - Read
  - Write
  - Bash
---
<objective>
Insert a decimal phase for urgent work discovered mid-milestone between existing integer phases. Uses decimal numbering (72.1, 72.2, etc.) to preserve logical sequence without renumbering the entire roadmap.
</objective>

<context>
Arguments: $ARGUMENTS (format: <after-phase-number> <description>)

Follow the workflow in `~/.claude/ariadna/workflows/insert-phase.md` end-to-end.
</context>

<process>
1. Parse $ARGUMENTS: first token = integer phase to insert after, rest = description. Error if missing.
2. Run `ariadna-tools init phase-op "$AFTER"` — check `roadmap_exists`.
3. Run `ariadna-tools phase insert "$AFTER" "$DESCRIPTION"` — calculates decimal number, creates directory, updates ROADMAP.md with (INSERTED) marker.
4. Update STATE.md "Roadmap Evolution" section with urgent insertion note.
5. Display decimal phase number, directory, and next step: `/ariadna:plan-phase {N.M}`.
</process>
