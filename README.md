# Ariadna

A meta-prompting and context engineering system for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

[![Gem Version](https://badge.fury.io/rb/ariadna.svg)](https://rubygems.org/gems/ariadna)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Ariadna provides structured planning, multi-agent orchestration, and verification workflows via Claude Code slash commands. It turns Claude Code into a disciplined project execution engine that plans before it builds, verifies after it ships, and tracks state across sessions. Specialized executor agents handle backend, frontend, and testing domains with domain-specific guides.

A system of prompts, agents, and workflows that make Claude Code work like a disciplined engineering team.

## Why Ariadna

**Without Ariadna**, Claude Code sessions are stateless. There's no memory between sessions, no structure to large projects, no verification that what was built matches what was planned, and no way to coordinate parallel work streams.

**With Ariadna**, you get:

- **Persistent memory** — `STATE.md` tracks decisions, progress, and blockers across sessions
- **Structured planning** — roadmaps, phases, and plans with dependency-aware execution
- **Parallel agents** — wave-based execution spawns multiple agents working simultaneously
- **Domain-specific executors** — backend, frontend, and test agents load specialised guides
- **Verification** — automated goal checking plus conversational UAT after every phase
- **Session continuity** — pause mid-phase, resume later with full context restoration

## How It Works

1. You invoke a slash command (e.g., `/ariadna:execute-phase 1`)
2. The command loads a workflow definition and gathers context via `ariadna-tools`
3. An orchestrator spawns specialised agents (planner, executor, verifier) in parallel, routing to domain-specific executors based on plan metadata
4. Agents execute tasks, make atomic commits, and produce summaries
5. Project state is updated in `.planning/STATE.md`

## Quick Start

### Installation

```bash
gem install ariadna
```

Install commands and agents globally (recommended):

```bash
ariadna install --global    # Installs to ~/.claude/ — available in all projects
```

Or locally for a single project:

```bash
ariadna install --local     # Installs to ./.claude/ — project-specific
```

### New Project (Greenfield)

```
/ariadna:new-project           # Define vision, research domain, create roadmap
/clear
/ariadna:plan-phase 1          # Create detailed plan for first phase
/clear
/ariadna:execute-phase 1       # Execute it with parallel agents
/ariadna:verify-work 1         # Conversational UAT
```

Use `/clear` between commands to give each orchestrator a fresh context window. Each command loads only the context it needs.

### Existing Project (Brownfield)

```
/ariadna:map-codebase          # Analyse codebase → .planning/codebase/
/clear
/ariadna:new-project           # Define vision using codebase analysis
/clear
/ariadna:plan-phase 1          # Plan first phase
/clear
/ariadna:execute-phase 1       # Execute
```

For adding features to an existing project without a full roadmap, use `/ariadna:new-milestone` instead of `/ariadna:new-project`.

## Usage Guide

### The Core Loop: Plan, Execute, Verify

Every phase follows the same three-step cycle:

**Plan** (`/ariadna:plan-phase N`) — spawns a researcher, planner, and plan-checker working in sequence. The researcher investigates the ecosystem, the planner creates `PLAN.md` files with tasks, and the plan-checker validates the plan against the phase goal. Output: one or more `PLAN.md` files in `.planning/phases/`.

**Execute** (`/ariadna:execute-phase N`) — groups plans into waves based on dependency numbering. Plans in the same wave run in parallel via separate executor agents. Each agent reads its plan, executes tasks with atomic commits, and writes a `SUMMARY.md`. The orchestrator spot-checks results between waves.

**Verify** (`/ariadna:verify-work N`) — conversational UAT session. The verifier checks whether the phase goal was achieved (not just whether tasks were completed). If gaps are found, it creates a verification report and you can run `/ariadna:plan-phase N --gaps` to close them.

### Phase Preparation (Optional)

For complex phases, prepare before planning:

```
/ariadna:discuss-phase N              # Capture your vision and decisions → CONTEXT.md
/clear
/ariadna:research-phase N             # Deep ecosystem research → RESEARCH.md
/clear
/ariadna:list-phase-assumptions N     # See Claude's intended approach before committing
/clear
/ariadna:plan-phase N                 # Plan with full context
```

These commands are optional — `/ariadna:plan-phase` works standalone. But for phases involving unfamiliar libraries or architectural decisions, preparation pays off.

### Session Management

```
/ariadna:pause-work        # Creates .continue-here.md handoff document
/ariadna:resume-work       # Restores context and routes to next action
/ariadna:progress          # Status overview with next-action routing
```

Pause *before* hitting context limits. The handoff document captures current position, completed work, and what's next so the new session starts informed.

### Quick Tasks

```
/ariadna:quick             # Same guarantees, skips optional agents
```

For small, ad-hoc tasks that don't warrant a full phase cycle. Quick tasks live in `.planning/quick/`, get atomic commits, and update `STATE.md` — but skip the roadmap and don't create phase directories.

### Milestone Lifecycle

Milestones represent major release boundaries (v1.0, v2.0). The full lifecycle:

```
# After completing all phases in a milestone:
/ariadna:audit-milestone           # Check completion against original intent
/ariadna:plan-milestone-gaps       # Create phases to close any audit gaps
# Execute gap phases...
/ariadna:complete-milestone v1.0   # Archive milestone and tag release
/ariadna:new-milestone v2.0        # Start next milestone
```

Roadmap manipulation commands:

- `/ariadna:add-phase` — append a phase to the current milestone
- `/ariadna:insert-phase` — insert urgent work as a decimal phase (e.g., 3.1)
- `/ariadna:remove-phase` — remove a future phase and renumber

### Debugging

```
/ariadna:debug [description]    # Systematic debugging with persistent state
```

Uses the scientific method: observe, hypothesise, test, conclude. Debug state persists in `.planning/debug/` and survives `/clear`, so you can continue across sessions.

## Hierarchy Model

```
Project → Milestones → Phases → Plans → Tasks
```

- **Project** — the thing you're building
- **Milestones** — major release boundaries (v1.0, v2.0)
- **Phases** — logical chunks of work within a milestone
- **Plans** — concrete execution steps within a phase, with wave-based parallelism
- **Tasks** — individual items within a plan

Plans use wave-based numbering (e.g., `01-01`, `01-02`) to express parallelism. Plans sharing a wave number execute in parallel; higher waves wait for lower waves to complete.

## Agent System

### Orchestrators

Lightweight coordinators that spawn specialised agents. They stay lean (~10-15% context usage), passing file paths to subagents rather than content. Each subagent gets a fresh 200k context window.

### Specialised Executors

Plans include a `domain` field in their frontmatter. The execute-phase orchestrator routes each plan to the appropriate executor:

| Domain | Executor | Guide |
|--------|----------|-------|
| `backend` | `ariadna-backend-executor` | `guides/backend.md` |
| `frontend` | `ariadna-frontend-executor` | `guides/frontend.md` |
| `testing` | `ariadna-test-executor` | `guides/testing.md` |
| `general` (default) | `ariadna-executor` | (none) |

Each specialised executor loads its domain guide automatically, applying domain-specific patterns and best practices.

### Analysis & Research Agents

| Agent | Role |
|-------|------|
| `ariadna-planner` | Creates PLAN.md files from phase goals and research |
| `ariadna-plan-checker` | Validates plans against phase goals |
| `ariadna-verifier` | Checks goal achievement, not just task completion |
| `ariadna-integration-checker` | Verifies cross-phase integration and E2E flows |
| `ariadna-debugger` | Scientific method debugging with persistent state |
| `ariadna-phase-researcher` | Deep ecosystem research for a specific phase |
| `ariadna-project-researcher` | Domain research during project initialisation |
| `ariadna-research-synthesizer` | Synthesises parallel research outputs |
| `ariadna-codebase-mapper` | Analyses existing codebase structure |
| `ariadna-roadmapper` | Creates project roadmaps with phase breakdown |

## Guides

Guides provide domain-specific patterns, conventions, and best practices that executors follow during plan execution. Read below how to customise them for your project.

| Guide | Purpose |
|-------|---------|
| `backend.md` | Ruby on Rails patterns, API design, database conventions |
| `frontend.md` | Frontend architecture, component patterns, accessibility |
| `testing.md` | Test strategy, framework conventions, coverage expectations |
| `security.md` | Security patterns, authentication, authorisation, OWASP |
| `performance.md` | Performance optimisation, caching, database tuning |
| `style-guide.md` | Code style, naming conventions, formatting rules |

Executors load the relevant guide automatically based on plan domain. The security and performance guides are also used during verification.

### Customising Guides

Guides are installed to `~/.claude/guides/` (global) or `.claude/guides/` (local). Edit them to match your project's conventions. After updating Ariadna, use `/ariadna:reapply-patches` to restore your customisations.

## Commands

### Project Initialisation

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

### Configuration & Maintenance

| Command | Description |
|---|---|
| `/ariadna:settings` | Configure workflow toggles and model profile |
| `/ariadna:set-profile <profile>` | Switch model profile |
| `/ariadna:help` | Show full command reference |
| `/ariadna:update` | Update gem with changelog preview |
| `/ariadna:reapply-patches` | Restore local guide customisations after update |

## Planning Directory

```
.planning/
├── PROJECT.md                # Project vision and requirements
├── ROADMAP.md                # Phase breakdown with status
├── STATE.md                  # Project memory across sessions
├── REQUIREMENTS.md           # Detailed requirements
├── CONTEXT.md                # Phase discussion decisions
├── config.json               # Workflow mode and agent toggles
├── quick/                    # Quick task plans and summaries
├── todos/
│   ├── pending/
│   └── done/
├── debug/
│   └── resolved/
├── research/                 # Project-level research outputs
├── codebase/                 # Brownfield project analysis
│   ├── STACK.md              # Languages, frameworks, dependencies
│   ├── INTEGRATIONS.md       # External APIs, databases, auth
│   ├── ARCHITECTURE.md       # Patterns, layers, data flow
│   ├── STRUCTURE.md          # Directory layout, key locations
│   ├── CONVENTIONS.md        # Code style, naming, patterns
│   ├── TESTING.md            # Test framework, structure, coverage
│   └── CONCERNS.md           # Tech debt, security, performance
└── phases/
    ├── 01-foundation/
    │   ├── RESEARCH.md
    │   ├── 01-01-PLAN.md
    │   └── 01-01-SUMMARY.md
    └── 02-core-features/
        ├── 02-01-PLAN.md
        └── 02-01-SUMMARY.md
```

## Configuration

### Model Profiles

Control which Claude models agents use via `/ariadna:set-profile`:

| Profile | Planning | Execution | Research/Verification |
|---|---|---|---|
| **quality** | Opus | Opus | Opus |
| **balanced** (default) | Opus | Sonnet | Sonnet |
| **budget** | Sonnet | Sonnet | Haiku |

### Workflow Toggles

Configure via `/ariadna:settings`:

| Toggle | Default | Effect |
|---|---|---|
| Research | on | Phase researcher runs before planning |
| Plan check | on | Plan-checker validates plans against goals |
| Verifier | on | Verifier runs after phase execution |

Per-command overrides: `--research`, `--skip-research`, `--skip-verify`.

### Branching Strategies

| Strategy | When branch is created | Scope | Best for |
|---|---|---|---|
| `none` (default) | Never | N/A | Solo development, simple projects |
| `phase` | At `execute-phase` start | Single phase | Code review per phase, granular rollback |
| `milestone` | At first `execute-phase` | Entire milestone | Release branches, PR per version |

Configure via `/ariadna:settings` or directly in `.planning/config.json`.

## Updating

```
/ariadna:update              # Shows changelog, confirms before installing
```

Local modifications to guides and templates are backed up automatically during updates. After updating, use `/ariadna:reapply-patches` to restore your customisations.

## Default Settings

Ariadna is configured to generate Ruby on Rails applications following the Rails philosophy and conventions. We believe in the [Rails is plenty](https://world.hey.com/jorge/a-vanilla-rails-stack-is-plenty-567a4708) approach — vanilla Rails with minimal dependencies.

This project has taken inspiration from [Fizzy](https://www.fizzy.do/) and [Once Campfire](https://github.com/basecamp/once-campfire), both great resources for Ruby on Rails best practices. Remember that you can customise Ariadna by editing the guides installed to `~/.claude/guides/`.

## Requirements

- Ruby >= 3.1.0
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)

## Contributors

- [Mario Alvarez](https://github.com/marioalna)
- [Jorge Alvarez](https://github.com/jorgegorka)

## Acknowledgements

- [GSD](https://gsd.build/) for inspiring the project and providing a solid foundation to build upon.
- [37 Signals](https://37signals.com/) we stand on the shoulders of giants.
- The [Ruby on Rails](https://rubyonrails.org/) community.
- [Matz and the Ruby team](https://www.ruby-lang.org/en/people/) for creating such a wonderful language.

## License

[MIT](LICENSE)
