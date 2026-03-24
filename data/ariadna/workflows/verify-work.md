---
name: verify-work
description: Validate that a phase or milestone achieved its goals — goal-backward, not task-backward
---

## Goal
Confirm that what was built actually delivers the phase or milestone goal, not merely that tasks were completed. Produces a VERIFICATION.md with pass/fail/gap status and feeds gaps back into planning.

## Context Loading
```bash
INIT=$(ariadna-tools init verify-work "${PHASE_OR_MILESTONE_ARG}")
```
Returns: `summary_paths[]` (SUMMARY.md files to verify against), `phase_dir`, `memory_dir`, `verifier_model`, `phase_number`, `phase_name`, `has_verification`.

Also read: `@~/.claude/skills/rails-backend/SKILL.md` for expected Rails patterns, and load security + performance Skills in the verifier prompt for non-functional checks.

## Constraints
- Spawn `ariadna-verifier` agent; verifier checks goal achievement against the codebase, not just SUMMARY.md claims
- Load security Skills (`@~/.claude/skills/rails-security/SKILL.md`) and performance Skills (`@~/.claude/skills/rails-performance/SKILL.md`) in the verifier prompt
- Phase scope: verify one phase goal; milestone scope: verify all phases in the milestone — same workflow, different `--scope` argument
- Verifier must check `must_haves` from plan frontmatter against actual files on disk — no credit for "plan says done"
- If `has_verification: true`, offer to re-verify or show existing report

## Success Criteria
- VERIFICATION.md exists in `phase_dir` with `status: passed | human_needed | gaps_found`
- No critical gaps left unaddressed (minor gaps acceptable with notes)
- Human-needed items listed explicitly so the user knows what to test manually

## On Completion
- Update `memory/progress.md` with verification status and gap count
- If `gaps_found`: display gap summary and offer `/ariadna:plan-phase {N} --gaps` to create fix plans
- If `human_needed`: present items for manual testing; wait for user confirmation before marking verified
- If `passed`: mark phase/milestone verified in STATE.md and ROADMAP.md
