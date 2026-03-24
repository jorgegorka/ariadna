---
name: ariadna:remove-phase
description: Remove a future phase from roadmap and renumber subsequent phases
argument-hint: <phase-number>
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
---
<objective>
Remove an unstarted future phase from the roadmap and renumber all subsequent phases to maintain a clean linear sequence. Git commit serves as the historical record.
</objective>

<context>
Phase: $ARGUMENTS

Follow the workflow in `~/.claude/ariadna/workflows/remove-phase.md` end-to-end.
</context>

<process>
1. Validate $ARGUMENTS provided; error with usage if missing.
2. Run `ariadna-tools init phase-op "$ARGUMENTS"` to load context; check `roadmap_exists`.
3. Verify target is a future (unstarted) phase vs current phase in STATE.md; error if not.
4. Present removal summary (what will be deleted/renumbered); confirm with user.
5. Run `ariadna-tools phase remove "$ARGUMENTS"` — deletes directory, renumbers subsequent phases, updates ROADMAP.md and STATE.md. Use `--force` only if user confirms for phases with summaries.
6. Commit: `ariadna-tools commit "chore: remove phase $ARGUMENTS ({name})" --files .ariadna_planning/`
7. Display changes made and offer `/ariadna:progress` to review updated roadmap.
</process>
