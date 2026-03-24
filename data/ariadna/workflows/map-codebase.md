---
name: map-codebase
description: Analyze an existing codebase with 4 parallel mapper agents and produce 7 structured documents in .ariadna_planning/codebase/.
---

## Goal
Produce a complete, reference-quality snapshot of the codebase — stack, architecture, conventions, and concerns — by running 4 specialized mapper agents in parallel. Each agent writes its documents directly; the orchestrator only collects confirmations and line counts.

## Context Loading
```bash
INIT=$(ariadna-tools init map-codebase)
```
Parse: `mapper_model`, `codebase_dir_exists`, `existing_maps`. If `codebase_dir_exists` is true, offer: Refresh (delete + remap), Update (remap specific documents), or Skip (use existing). Create `.ariadna_planning/codebase/` if it doesn't exist.

## Constraints
- Spawn all 4 agents in a single message with `run_in_background=true` (true parallel execution)
- Agents are `ariadna-codebase-mapper` — NOT general-purpose; they write documents directly and return only confirmation + line counts
- Required outputs: STACK.md, INTEGRATIONS.md (agent 1 — tech), ARCHITECTURE.md, STRUCTURE.md (agent 2 — arch), CONVENTIONS.md, TESTING.md (agent 3 — quality), CONCERNS.md (agent 4 — concerns)
- Run secret scan (`grep -E` for API key patterns) on all output files before committing; pause for user confirmation if secrets detected
- Documents must include actual file paths formatted in backticks — they are reference material for planners

## Success Criteria
- All 7 documents exist in `.ariadna_planning/codebase/` with >20 lines each
- Secret scan passes (no credentials leaked)
- Committed with `docs: map existing codebase`

## On Completion
Display document list with line counts. Offer `/ariadna:new-project` as the natural next step with a `/clear` reminder.
