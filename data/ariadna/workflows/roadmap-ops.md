---
name: roadmap-ops
description: Modify the roadmap structure — add a phase at the end, insert a decimal phase between existing phases, or remove an unstarted phase with renumbering.
---

## Goal
Apply structural changes to ROADMAP.md cleanly and atomically. Delegates all heavy lifting (directory creation/deletion, renumbering, ROADMAP.md edits) to `ariadna-tools phase {op}` and records the change in STATE.md's "Roadmap Evolution" section.

## Context Loading
```bash
INIT=$(ariadna-tools init phase-op "${target_phase_or_0}")
```
Parse: `roadmap_exists`, `phase_found`, `phase_dir`. If `roadmap_exists` is false, error and exit. Determine operation from `$ARGUMENTS`: `add <description>`, `insert <after_phase> <description>`, or `remove <phase_number>`.

## Constraints
- **add**: appends a new integer phase (max + 1) at end of milestone; requires description; use for planned work
- **insert**: inserts a decimal phase (e.g., 72.1) immediately after an existing integer phase; requires `<after_phase>` and description; marks as `(INSERTED)` in ROADMAP.md; use for urgent mid-milestone work only
- **remove**: only future phases (target > current); requires user confirmation before executing; use `--force` only if user explicitly confirms removal of a phase with existing SUMMARY.md files; the git commit is the historical record — do NOT add redundant notes to STATE.md
- All three operations commit immediately after execution
- Do NOT create plans during these operations — that is `/ariadna:plan-phase`'s job

## Success Criteria
- `ariadna-tools phase {add|insert|remove}` exits successfully with no errors
- Phase directory created (add/insert) or deleted and subsequent phases renumbered (remove)
- ROADMAP.md and STATE.md updated; changes committed

## On Completion
Display a summary of what changed (new phase number/directory, or removed phase + renumber count). For add/insert, suggest `/ariadna:plan-phase {N}` as next step. For remove, suggest `/ariadna:progress` to see the updated roadmap.
