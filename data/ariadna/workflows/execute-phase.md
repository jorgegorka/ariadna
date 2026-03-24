---
name: execute-phase
description: Execute all plans in a phase using wave-based ordering, producing SUMMARY.md and atomic commits per task
---

## Goal
Execute every plan in a phase by spawning executor subagents, respecting wave dependencies, and producing committed deliverables. Orchestrator coordinates; subagents do the work.

## Context Loading
```bash
INIT=$(ariadna-tools init execute-phase "${PHASE_ARG}")
```
Returns: `phase_dir`, `phase_number`, `phase_name`, `plans[]` (each with `wave`, `domain`, `depends_on`, `has_summary`), `executor_model`, `verifier_model`, `parallelization`, `branching_strategy`, `branch_name`.

Also read: `.ariadna_planning/STATE.md` for current project position.

## Constraints
- Orchestrator stays lean (~10-15% context) — pass paths only, subagents read files themselves
- Wave ordering is strict: all wave N plans complete before wave N+1 begins
- Skip plans where `has_summary: true` (already done); resumption is automatic
- Route executor agent by `domain` frontmatter: `backend` → `ariadna-backend-executor`, `frontend` → `ariadna-frontend-executor`, `testing` → `ariadna-test-executor`, `general`/unset → `ariadna-executor`
- Load the matching Rails Skills (`@~/.claude/skills/rails-{domain}/SKILL.md`) in each executor prompt
- Each task must be committed atomically; executor creates SUMMARY.md in plan directory
- Plans with `autonomous: false` require a checkpoint pause before continuing
- If agent returns `classifyHandoffIfNeeded` error: spot-check SUMMARY.md + git commits — if present, treat as success

## Success Criteria
- Every plan in the phase has a SUMMARY.md
- `git log` shows at least one commit per plan
- No `## Self-Check: FAILED` markers in any SUMMARY.md

## On Completion
- Spawn `ariadna-verifier` to check phase goal achievement (not just task completion)
- Update `memory/progress.md` with phase status and any decisions made
- Record session summary: mark phase complete in ROADMAP.md, commit STATE.md
- If verifier finds gaps: offer `/ariadna:plan-phase {N} --gaps` for closure
