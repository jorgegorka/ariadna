---
name: ariadna:verify-work
description: Validate built features against phase goals — goal-backward, not task-backward
argument-hint: "[phase number, e.g., '4']"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Task
---
<objective>
Confirm that what was built delivers the phase goal, not merely that tasks were completed. Produces VERIFICATION.md with pass/fail/gap status and feeds gaps back into planning.

Spawn `ariadna-verifier` to check goal achievement against the actual codebase.
</objective>

<context>
Phase: $ARGUMENTS (optional — checks active session or prompts if omitted)

Follow the workflow in `~/.claude/ariadna/workflows/verify-work.md` end-to-end.
</context>

<process>
1. Run `ariadna-tools init verify-work "$PHASE_ARG"` to load context as JSON.
2. If `has_verification: true`, offer to re-verify or show existing report.
3. Spawn `ariadna-verifier`; verifier checks `must_haves` from plan frontmatter against files on disk.
4. On completion: update `memory/progress.md` and STATE.md.
5. If `gaps_found`: display gap summary and offer `/ariadna:plan-phase {N} --gaps`.
6. If `human_needed`: list items for manual testing; wait for confirmation before marking verified.
7. If `passed`: mark phase verified in STATE.md and ROADMAP.md.
</process>
