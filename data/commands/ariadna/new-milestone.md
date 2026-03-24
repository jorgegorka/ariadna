---
name: ariadna:new-milestone
description: Start a new milestone cycle — update PROJECT.md and route to requirements
argument-hint: "[milestone name, e.g., 'v1.1 Notifications']"
allowed-tools:
  - Read
  - Write
  - Bash
  - Task
  - AskUserQuestion
---
<objective>
Start a new milestone: questioning → research (optional) → requirements → roadmap.

Brownfield equivalent of new-project. Project exists, PROJECT.md has history. Gathers "what's next", updates PROJECT.md, then runs requirements → roadmap cycle.

**Creates/Updates:** `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`

**After:** `/ariadna:plan-phase [N]` to start execution.
</objective>

<context>
Milestone name: $ARGUMENTS (optional — will prompt if not provided)

Follow the workflow in `~/.claude/ariadna/workflows/new-milestone.md` end-to-end.
</context>

<process>
1. Run `ariadna-tools init new-milestone` to load context as JSON.
2. Load PROJECT.md, STATE.md, MILESTONES.md; check for MILESTONE-CONTEXT.md.
3. Gather milestone goals through conversation (or use existing MILESTONE-CONTEXT.md).
4. Determine milestone version; update PROJECT.md and STATE.md; commit.
5. Ask about research; optionally spawn 4 parallel researchers + synthesizer.
6. Define requirements by category; write REQUIREMENTS.md; commit.
7. Spawn `ariadna-roadmapper` with continuing phase numbering.
8. Present roadmap for approval; commit on approval.
9. Display next step: `/ariadna:plan-phase [N]`.
</process>
