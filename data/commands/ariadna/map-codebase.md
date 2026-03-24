---
name: ariadna:map-codebase
description: Analyze codebase with parallel mapper agents to produce .ariadna_planning/codebase/ documents
argument-hint: "[optional: specific area to map, e.g., 'api' or 'auth']"
allowed-tools:
  - Read
  - Bash
  - Glob
  - Grep
  - Write
  - Task
---
<objective>
Analyze existing codebase using 4 parallel `ariadna-codebase-mapper` agents to produce structured documents in `.ariadna_planning/codebase/`. Each agent writes directly; orchestrator receives only confirmations.

**Output:** 7 documents — STACK.md, INTEGRATIONS.md, ARCHITECTURE.md, STRUCTURE.md, CONVENTIONS.md, TESTING.md, CONCERNS.md
</objective>

<context>
Focus area: $ARGUMENTS (optional — directs agents to focus on a specific subsystem)

Follow the workflow in `~/.claude/ariadna/workflows/map-codebase.md` end-to-end.
</context>

<process>
1. Run `ariadna-tools init map-codebase` to load context as JSON.
2. If `.ariadna_planning/codebase/` exists: offer Refresh / Update / Skip.
3. Create `.ariadna_planning/codebase/` directory.
4. Spawn 4 parallel `ariadna-codebase-mapper` agents (run_in_background=true):
   - Agent 1: tech → STACK.md, INTEGRATIONS.md
   - Agent 2: arch → ARCHITECTURE.md, STRUCTURE.md
   - Agent 3: quality → CONVENTIONS.md, TESTING.md
   - Agent 4: concerns → CONCERNS.md
5. Scan output files for accidentally leaked secrets before committing.
6. Verify all 7 documents exist with `wc -l`; note any failures.
7. Commit: `ariadna-tools commit "docs: map existing codebase" --files .ariadna_planning/codebase/*.md`
8. Display line counts and next step: `/ariadna:new-project`.
</process>
