# Ariadna

A meta-prompting and context engineering system for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

It's a fork of [Get Shit Done](https://github.com/gsd-build/get-shit-done/tree/main) focused on creating Ruby on Rails applications.

[![Gem Version](https://badge.fury.io/rb/ariadna.svg)](https://rubygems.org/gems/ariadna)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Ariadna provides structured planning, multi-agent orchestration, and verification workflows via Claude Code slash commands. It turns Claude Code into a disciplined project execution engine for Ruby on Rails that plans before it builds, verifies after it ships, and tracks state across sessions.

## Hierarchy Model

```
Project → Milestones → Phases → Plans → Tasks
```

- **Project** — the thing you're building
- **Milestones** — major release boundaries (v1.0, v2.0)
- **Phases** — logical chunks of work within a milestone
- **Plans** — concrete execution steps within a phase, with wave-based parallelism
- **Tasks** — individual items within a plan

## Quick Start

```bash
gem install ariadna
ariadna install --global
```

Then in Claude Code:

```
/ariadna:new-project       # Define vision, research domain, create roadmap
/clear
/ariadna:plan-phase 1      # Create detailed plan for first phase
/clear
/ariadna:execute-phase 1   # Execute it
```

Repeat `plan-phase` / `execute-phase` for each phase. Use `/ariadna:progress` to see where you are.

## How It Works

1. You invoke a slash command (e.g., `/ariadna:execute-phase 1`)
2. The command loads a workflow definition and gathers context via `ariadna-tools`
3. An orchestrator spawns specialised agents (planner, executor, verifier) in parallel
4. Agents execute tasks, make atomic commits, and produce summaries
5. Project state is updated in `.planning/STATE.md`

## Commands

### Project Initialization

| Command | Description |
|---|---|
| `/ariadna:new-project` | Initialise project: questioning, research, requirements, roadmap |
| `/ariadna:map-codebase` | Analyse existing codebase before starting (brownfield projects) |

### Phase Planning

| Command | Description |
|---|---|
| `/ariadna:discuss-phase <n>` | Capture your vision for a phase before planning |
| `/ariadna:research-phase <n>` | Deep ecosystem research for specialised domains |
| `/ariadna:list-phase-assumptions <n>` | See Claude's intended approach before it plans |
| `/ariadna:plan-phase <n>` | Create detailed execution plan |

### Execution

| Command | Description |
|---|---|
| `/ariadna:execute-phase <n>` | Execute all plans in a phase (wave-based parallelism) |
| `/ariadna:quick` | Small ad-hoc tasks with Ariadna guarantees |
| `/ariadna:verify-work <n>` | Conversational UAT for built features |

### Roadmap & Milestones

| Command | Description |
|---|---|
| `/ariadna:add-phase <desc>` | Add phase to end of milestone |
| `/ariadna:insert-phase <after> <desc>` | Insert urgent work as decimal phase (e.g., 7.1) |
| `/ariadna:remove-phase <n>` | Remove future phase and renumber |
| `/ariadna:new-milestone <name>` | Start a new milestone |
| `/ariadna:complete-milestone <ver>` | Archive milestone and tag release |
| `/ariadna:audit-milestone` | Audit completion against original intent |
| `/ariadna:plan-milestone-gaps` | Create phases to close audit gaps |

### Session & Progress

| Command | Description |
|---|---|
| `/ariadna:progress` | Status overview and next-action routing |
| `/ariadna:resume-work` | Restore context from previous session |
| `/ariadna:pause-work` | Create handoff for mid-phase breaks |

### Debugging & Todos

| Command | Description |
|---|---|
| `/ariadna:debug [desc]` | Systematic debugging with persistent state (survives `/clear`) |
| `/ariadna:add-todo [desc]` | Capture ideas/tasks |
| `/ariadna:check-todos [area]` | Review and work on pending todos |

### Configuration

| Command | Description |
|---|---|
| `/ariadna:settings` | Configure workflow toggles and model profile |
| `/ariadna:set-profile <profile>` | Switch model profile |
| `/ariadna:help` | Show full command reference |
| `/ariadna:update` | Update gem with changelog preview |

## Planning Directory

```
.planning/
├── PROJECT.md              # Project vision and requirements
├── ROADMAP.md              # Phase breakdown with status
├── STATE.md                # Project memory across sessions
├── config.json             # Workflow mode and agent toggles
├── todos/
│   ├── pending/
│   └── done/
├── debug/
│   └── resolved/
├── codebase/               # Brownfield project analysis
└── phases/
    ├── 01-foundation/
    │   ├── 01-01-PLAN.md
    │   └── 01-01-SUMMARY.md
    └── 02-core-features/
        ├── 02-01-PLAN.md
        └── 02-01-SUMMARY.md
```

## Model Profiles

Control which Claude models agents use via `/ariadna:set-profile`:

| Profile | Planning | Execution | Research/Verification |
|---|---|---|---|
| **quality** | Opus | Opus | Opus |
| **balanced** (default) | Opus | Sonnet | Sonnet |
| **budget** | Sonnet | Sonnet | Haiku |

## Default settings

With Ariadna you can create Ruby on Rails applications or add features to existing ones. By default, Ariadna is configured to generate Ruby on Rails applications taht follow the rails philosophy and best practices, but you can customise it to fit your needs.

The default settings are heavily influenced by our experience building Ruby on Rails applications, and are designed to produce high-quality code that follows best practices. However, we understand that every project is different, and we encourage you to experiment with the settings to find what works best for you.

We are firmly belivers in the [Rails is plenty](https://world.hey.com/jorge/a-vanilla-rails-stack-is-plenty-567a4708) philosophy, so our default settings are optimised for vanilla Ruby on Rails applications.

## Requirements

- Ruby >= 3.1.0
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)

## Contributors

- [Mario Alvarez](https://github.com/marioalna)
- [Jorge Alvarez](https://github.com/jorgegorka)

## Acknowledgements

 - [GSD](https://gsd.build/) for inspiring the project and providing a solid foundation to build upon.

## License

[MIT](LICENSE)
