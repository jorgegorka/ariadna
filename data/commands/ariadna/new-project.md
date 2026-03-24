---
name: ariadna:new-project
description: Initialize a new project with deep context gathering and PROJECT.md
argument-hint: "[--auto] [--research]"
allowed-tools:
  - Read
  - Write
  - Bash
  - Task
  - AskUserQuestion
---
<objective>
Initialize a new project through streamlined flow: questioning → requirements → roadmap. Research skipped by default (Rails conventions pre-loaded); use `--research` for non-standard domains.

**Flags:**
- `--auto` — Automatic mode. Skips questions, runs requirements → roadmap without interaction. Requires idea document via @ reference.
- `--research` — Force parallel domain research before requirements.

**Creates:** `.ariadna_planning/PROJECT.md`, `config.json`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`

**After this command:** `/ariadna:plan-phase 1`
</objective>

<context>
Arguments: $ARGUMENTS

Follow the workflow in `~/.claude/ariadna/workflows/new-project.md` end-to-end.
</context>

<process>
1. Run `ariadna-tools init new-project` to load context as JSON.
2. Offer codebase mapping if existing code detected but no map present.
3. Gather project context through deep questioning (or extract from `--auto` document).
4. Write PROJECT.md, config.json; commit each atomically.
5. Optionally spawn research agents (4 parallel + synthesizer) if `--research` flag.
6. Define requirements by category (table stakes / differentiators / out of scope).
7. Spawn `ariadna-roadmapper` to create ROADMAP.md and STATE.md.
8. Present roadmap for approval; loop on revisions until approved.
9. Commit all artifacts; display next step: `/ariadna:plan-phase 1`.
</process>
