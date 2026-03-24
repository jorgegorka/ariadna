---
name: new-project
description: Initialize a new project from idea to roadmap — questioning, requirements, and phased execution plan.
---

## Goal
Guide the user from raw idea to a committed roadmap by running deep questioning, defining requirements, and spawning the roadmapper. One workflow takes you from "I want to build X" to "Phase 1: plan-phase 1".

## Context Loading
```bash
INIT=$(ariadna-tools init new-project)
```
Parse: `researcher_model`, `synthesizer_model`, `roadmapper_model`, `project_exists`, `needs_codebase_map`, `has_git`. If `project_exists` is true, error and exit — use `/ariadna:progress` instead. If `has_git` is false, run `git init`.

## Constraints
- Auto mode (`--auto @doc.md`): skip questioning, skip approval gates, synthesize PROJECT.md from provided document
- Brownfield: if `needs_codebase_map` is true, offer `/ariadna:map-codebase` first before proceeding
- Research is off by default — Rails conventions pre-loaded via `rails-conventions.md`; add `--research` to force 4 parallel researchers
- Commit each artifact immediately after creation: PROJECT.md, config.json, REQUIREMENTS.md, ROADMAP.md + STATE.md
- Requirements must be specific, testable, user-centric with REQ-IDs (`AUTH-01`, `CONT-02`)

## Success Criteria
- `.ariadna_planning/` created with PROJECT.md, config.json, REQUIREMENTS.md, ROADMAP.md, STATE.md — all committed
- Every v1 requirement is mapped to exactly one roadmap phase with observable success criteria
- User knows the next command: `/ariadna:plan-phase 1`

## On Completion
Present artifact table, phase count, and requirement count. Offer `/ariadna:plan-phase 1` as next step with a `/clear` reminder for fresh context.
