---
name: new-milestone
description: Start a new milestone cycle for an existing project — goals, requirements, and phased roadmap continuing from the last milestone.
---

## Goal
Pick up where the previous milestone left off: gather what to build next, optionally research new capabilities, define scoped requirements, and spawn the roadmapper to produce a phased plan with phase numbers continuing from the last milestone.

## Context Loading
```bash
INIT=$(ariadna-tools init new-milestone)
```
Also read: `.ariadna_planning/PROJECT.md`, `.ariadna_planning/MILESTONES.md` (last version + last phase number), `.ariadna_planning/STATE.md` (pending todos, blockers). If `MILESTONE-CONTEXT.md` exists (from `/ariadna:discuss-milestone`), use it instead of asking. Parse: `researcher_model`, `synthesizer_model`, `roadmapper_model`, `roadmap_exists`.

## Constraints
- Determine next version from MILESTONES.md (v1.0 → v1.1, or v2.0 for major); confirm with user
- Roadmap phase numbering must continue from the last milestone's final phase number
- Research is opt-in — ask once ("Research first?" / "Skip"); persist choice to `config.json`
- If research selected, spawn 4 parallel `ariadna-project-researcher` agents (subsequent-milestone context: only research NEW capabilities)
- Commit each artifact immediately: PROJECT.md + STATE.md update, REQUIREMENTS.md, ROADMAP.md + STATE.md

## Success Criteria
- PROJECT.md updated with `## Current Milestone` section and STATE.md reset for the new cycle — both committed
- REQUIREMENTS.md created with REQ-IDs; every requirement mapped to a roadmap phase
- User knows the first phase number and next command: `/ariadna:plan-phase N` or `/ariadna:discuss-phase N`

## On Completion
Present artifact table, new milestone version, phase range, and requirement count. Offer `/ariadna:discuss-phase N` (or `/ariadna:plan-phase N` to skip discussion) with a `/clear` reminder.
