---
name: progress
description: Check project progress and route to the next action — absorbs resume-project and pause-work.
---

## Goal
Give instant situational awareness (recent work, current position, blockers) then route precisely to the next command — execute an existing plan, create the next one, fix UAT gaps, complete a milestone, or start the next milestone cycle. Also handles session pause (create `.continue-here.md`) and resume (restore from checkpoint).

## Context Loading
```bash
INIT=$(ariadna-tools init progress --include state,roadmap,project,config)
ROADMAP=$(ariadna-tools roadmap analyze)
```
Parse from init: `project_exists`, `roadmap_exists`, `paused_at`. If `project_exists` is false, suggest `/ariadna:new-project` and exit. If ROADMAP.md missing but PROJECT.md exists, route to **between milestones** (suggest `/ariadna:new-milestone`). Read 2-3 most recent SUMMARY.md files for recent-work context.

## Constraints
- Never take action automatically — always present status first, then route with a command suggestion
- Routing priority: UAT gaps → unexecuted plans → plan the current phase → complete milestone → new milestone
- Pause mode: if user says "pause" or "stop", write `.ariadna_planning/phases/{dir}/.continue-here.md` with full work state and commit as WIP
- Resume mode: detect `.continue-here.md` or incomplete PLAN (no matching SUMMARY) and surface as "Incomplete work detected" before routing
- Use `ariadna-tools progress bar --raw` for the visual progress bar

## Success Criteria
- Status report shows: progress bar, recent work, current position, decisions, blockers, pending todos
- Routing suggestion is unambiguous — one primary command with `/clear` reminder
- Pause/resume produces or consumes `.continue-here.md` with specific enough context for a fresh session

## On Completion
Present the "Next Up" block with the exact command to run. For pause, confirm handoff file location and show `/ariadna:progress` as the resume trigger.
