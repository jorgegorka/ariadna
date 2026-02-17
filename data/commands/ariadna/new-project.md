---
name: ariadna:new-project
description: Initialize a new project with deep context gathering and PROJECT.md
argument-hint: "[--auto] [--research]"
allowed-tools:
  - Read
  - Bash
  - Write
  - Task
  - AskUserQuestion
---
<context>
**Flags:**
- `--auto` — Automatic mode. Skips config questions, runs requirements → roadmap without further interaction. Expects idea document via @ reference.
- `--research` — Force domain research (4 parallel researchers + synthesizer). By default, research is skipped and Rails conventions are pre-loaded.
</context>

<objective>
Initialize a new project through streamlined flow: questioning → requirements → roadmap. Research skipped by default (Rails conventions pre-loaded); use --research for non-standard domains.

**Creates:**
- `.planning/PROJECT.md` — project context
- `.planning/config.json` — workflow preferences (opinionated defaults)
- `.planning/research/` — domain research (only with --research flag)
- `.planning/REQUIREMENTS.md` — scoped requirements
- `.planning/ROADMAP.md` — phase structure
- `.planning/STATE.md` — project memory

**After this command:** Run `/ariadna:plan-phase 1` to start planning.
</objective>

<execution_context>
@~/.claude/ariadna/workflows/new-project.md
@~/.claude/ariadna/references/questioning.md
@~/.claude/ariadna/references/ui-brand.md
@~/.claude/ariadna/references/rails-conventions.md
@~/.claude/ariadna/templates/project.md
@~/.claude/ariadna/templates/requirements.md
</execution_context>

<process>
Execute the new-project workflow from @~/.claude/ariadna/workflows/new-project.md end-to-end.
Preserve all workflow gates (validation, approvals, commits, routing).
</process>
