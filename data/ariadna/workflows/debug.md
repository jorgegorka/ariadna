---
name: debug
description: Systematically diagnose UAT gaps by spawning parallel debug agents — one per gap — to find root causes before planning fixes.
---

## Goal
Turn UAT symptoms into diagnosed root causes. Parse gaps from a phase's UAT.md, spawn one debug agent per gap in parallel, collect root causes with evidence, then update UAT.md with `root_cause`, `artifacts`, `missing`, and `debug_session` fields so `plan-phase --gaps` can create targeted fixes.

## Context Loading
```bash
INIT=$(ariadna-tools init debug "$PHASE")
```
Read the phase UAT.md from `.ariadna_planning/phases/{phase-dir}/{phase}-UAT.md`. Extract the "Gaps" section (YAML) — each gap has `truth`, `severity`, `test`, `reason`. Also read the matching "Tests" entries for full context. If no UAT.md or no failed gaps exist, error and exit.

## Constraints
- Diagnose only — do NOT apply fixes; that is `plan-phase --gaps`'s job
- Spawn all debug agents in a single message (true parallel execution via `run_in_background=true`)
- Each agent writes its own `DEBUG-{slug}.md` to `.ariadna_planning/debug/`; orchestrator only receives root cause + file paths
- If an agent returns `## INVESTIGATION INCONCLUSIVE`, mark gap as "needs manual review" and continue with remaining gaps
- After all agents complete, update UAT.md gaps in place and commit with `docs({phase}): add root causes from diagnosis`

## Success Criteria
- Every failed gap in UAT.md has `root_cause`, `artifacts`, and `missing` fields populated
- UAT.md frontmatter `status` updated to `diagnosed` and committed
- Debug sessions saved to `.ariadna_planning/debug/` for reference

## On Completion
Display a root-cause table (gap truth → root cause → files involved). Return to the verify-work orchestrator automatically — do NOT offer manual next steps; verify-work routes to `plan-phase --gaps`.
