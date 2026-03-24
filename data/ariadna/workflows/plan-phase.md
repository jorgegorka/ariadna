---
name: plan-phase
description: Create detailed PLAN.md execution files for a roadmap phase, with inline research and self-checking
---

## Goal
Produce a set of PLAN.md files that `execute-phase` can run directly. Plans must have valid frontmatter (wave, domain, depends_on, files_modified) and tasks specific enough that an executor can work autonomously.

## Context Loading
```bash
INIT=$(ariadna-tools init plan-phase "${PHASE_ARG}" --include state,roadmap,requirements,context,research,verification)
```
Returns: `phase_dir`, `phase_number`, `phase_name`, `planner_model`, `checker_model`, `has_plans`, `plan_count`, `state_content`, `roadmap_content`, `requirements_content`, `context_content`, `research_content`, `verification_content`.

Also read: `@~/.claude/skills/rails-backend/SKILL.md` — loaded into every planner prompt for convention-aware decomposition.

## Constraints
- Spawn `ariadna-planner` agent; planner handles inline research AND self-checking (no separate research phase by default — Rails conventions cover standard work; use `--research` only for non-standard integrations)
- Load Rails Skills (`@~/.claude/skills/rails-backend/SKILL.md`) in every planner prompt so domain detection and task decomposition follow Rails patterns
- Planner must self-check: valid frontmatter on every plan, wave ordering consistent with `depends_on`, no scope creep from deferred items in `context_content`
- Minor checker issues (wrong wave number, missing `<verify>` tags, frontmatter typos) fixed inline by orchestrator with Edit tool — no re-spawn
- Major issues (contradicts user decisions, missing requirement coverage, wrong decomposition) presented to user before proceeding
- `--gaps` mode reads `verification_content` and creates `gap_closure: true` plans only; skip context gathering and research

## Success Criteria
- PLAN.md files exist in `phase_dir` with valid frontmatter: `phase`, `plan`, `wave`, `domain`, `depends_on`
- Each plan's `must_haves` derived from the phase goal in ROADMAP.md (not from task list)
- Requirements from `requirements_content` mapped to plans (or flagged as uncovered)

## On Completion
- Update `memory/progress.md` with plan count, waves, and any key decisions locked during context gathering
- Display next step: `/ariadna:execute-phase {N}` with a `/clear` reminder
