# Ariadna

A meta-prompting and context engineering system for building Ruby on Rails applications with [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

[![Gem Version](https://badge.fury.io/rb/ariadna.svg)](https://rubygems.org/gems/ariadna)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Ariadna turns Claude Code into a disciplined Rails project execution engine. It installs commands, agents, workflows, and Rails Skills into `~/.claude/` that give Claude Code structured planning, parallel multi-agent execution, goal-backward verification, and persistent memory across sessions. This is not a vibe-coding tool. You will get the best results when you review both the created plans and the outcomes of each phase.

## Why Ariadna

**Without Ariadna**, Claude Code sessions are stateless. There's no memory between sessions, no structure to large projects, no verification that what was built matches what was planned, and no way to coordinate parallel work streams.

**With Ariadna**, you get:

- **Persistent memory** -- a `memory/` directory tracks decisions, progress, blockers, and metrics across sessions
- **Structured planning** -- roadmaps with milestones, phases, and wave-based parallel execution plans
- **6 specialized agents** -- planner, executor, verifier, debugger, roadmapper, and codebase mapper, each spawned with a fresh context window
- **5 Rails Skills** -- domain knowledge packages (backend, frontend, testing, security, performance) that agents load automatically based on plan domain
- **Goal-backward verification** -- checks whether the phase *achieved its goal*, not just whether tasks were completed
- **Session continuity** -- pause mid-phase, resume later with full context restoration via `/ariadna:progress`

## How It Works

1. You invoke a slash command (e.g., `/ariadna:execute-phase 1`)
2. The command loads a workflow and calls `ariadna-tools init` to gather paths and metadata
3. An orchestrator spawns specialized agents in parallel, each with a fresh context window
4. Agents load their own context (plans, skills, memory files), execute tasks, and make atomic commits
5. Project memory is updated in `.ariadna_planning/memory/`

## Quick Start

### Installation

```bash
gem install ariadna
```

Install commands, agents, and skills globally (recommended):

```bash
ariadna install --global    # Installs to ~/.claude/ -- available in all projects
```

Or locally for a single project:

```bash
ariadna install --local     # Installs to ./.claude/ -- project-specific
```

### New Rails Project (Greenfield)

```
/ariadna:new-project           # Define vision, set preferences, create roadmap
/clear
/ariadna:plan-phase 1          # Create detailed plan for first phase
/clear
/ariadna:execute-phase 1       # Execute it with parallel agents
/ariadna:verify-work 1         # Verify phase goal achievement
```

Use `/clear` between commands to give each orchestrator a fresh context window. Each command loads only the context it needs.

### Existing Rails Project (Brownfield)

```
/ariadna:map-codebase          # Analyse codebase --> .ariadna_planning/codebase/
/clear
/ariadna:new-project           # Define vision using codebase analysis
/clear
/ariadna:plan-phase 1          # Plan first phase
/clear
/ariadna:execute-phase 1       # Execute
```

For adding features to an existing project without a full roadmap, use `/ariadna:new-milestone` instead of `/ariadna:new-project`.

## The Core Loop: Plan, Execute, Verify

Every phase follows the same three-step cycle:

**Plan** (`/ariadna:plan-phase N`) -- The planner gathers context inline, then creates `PLAN.md` files with wave-based dependency numbering and domain-specific tasks. Self-checking is built in. Output: one or more `PLAN.md` files in `.ariadna_planning/phases/`.

**Execute** (`/ariadna:execute-phase N`) -- Plans are grouped into waves based on dependency numbering. Plans sharing a wave run in parallel via separate executor agents. Each agent reads its plan, loads the matching Rails Skill, executes tasks with atomic commits, and writes a `SUMMARY.md`.

**Verify** (`/ariadna:verify-work N`) -- Goal-backward verification. The verifier checks whether the phase goal was achieved -- truths that must hold, artifacts that must exist, wiring that must connect -- not just whether tasks were completed. If gaps are found, run `/ariadna:plan-phase N --gaps` to close them.

## More Commands

### Quick Tasks

```
/ariadna:quick                 # Same guarantees, skips the full phase cycle
```

For small, ad-hoc tasks that don't warrant a full phase. Quick tasks live in `.ariadna_planning/quick/`, get atomic commits, and update memory -- but skip the roadmap.

### Debugging

```
/ariadna:debug [description]   # Systematic debugging with persistent state
```

Uses the scientific method: observe, hypothesise, test, conclude. Debug state persists in `.ariadna_planning/debug/` and survives `/clear`, so you can continue across sessions.

### Session Management

```
/ariadna:progress              # Status overview with next-action routing
```

Reads `.ariadna_planning/memory/` to restore your position and show what's next. This is the entry point when resuming work.

### Milestones

```
/ariadna:new-milestone v2.0    # Start a new milestone cycle
```

Milestones represent major release boundaries. Use this for adding major features to an existing project.

### Roadmap Management

- `/ariadna:add-phase` -- append a phase to the current milestone
- `/ariadna:insert-phase` -- insert urgent work as a decimal phase (e.g., 3.1)
- `/ariadna:remove-phase` -- remove a future phase and renumber

## Hierarchy Model

```
Project --> Milestones --> Phases --> Plans --> Tasks
```

- **Project** -- the thing you're building
- **Milestones** -- major release boundaries (v1.0, v2.0)
- **Phases** -- logical chunks of work within a milestone
- **Plans** -- concrete execution steps within a phase, with wave-based parallelism
- **Tasks** -- individual items within a plan

Plans use wave-based numbering (e.g., `01-01`, `01-02`) to express parallelism. Plans sharing a wave number execute in parallel; higher waves wait for lower waves to complete.

## Agent System

### Orchestrators

Lightweight coordinators that spawn specialized agents. They stay lean (~10-15% context usage), passing file paths to subagents rather than content. Each subagent gets a fresh 200k context window.

### Agents

| Agent | Role |
|-------|------|
| `ariadna-planner` | Creates PLAN.md files from phase goals; gathers context and self-checks inline |
| `ariadna-executor` | Implements plan tasks with atomic commits; loads the matching Rails Skill automatically |
| `ariadna-verifier` | Goal-backward phase verification; checks actual codebase and cross-phase integration |
| `ariadna-debugger` | Scientific method debugging with persistent state across sessions |
| `ariadna-roadmapper` | Creates ROADMAP.md from project context; handles research and synthesis inline |
| `ariadna-codebase-mapper` | Explores existing codebase and writes structured analysis documents |

## Rails Skills

Skills are standalone domain knowledge packages that agents load on demand. Each Skill is a directory of Markdown files installed to `~/.claude/skills/` (global) or `.claude/skills/` (local).

The executor loads the matching Skill automatically based on the plan's `domain` frontmatter field. The verifier loads the security and performance Skills for non-functional checks.

| Skill | Domain | Contents |
|-------|--------|----------|
| `rails-backend` | `backend` | Models, controllers, jobs, API design; domain model at the center |
| `rails-frontend` | `frontend` | Hotwire, Turbo, Stimulus, views, components, assets |
| `rails-testing` | `testing` | Minitest strategy, fixtures, system tests |
| `rails-security` | verification | Authentication, authorization, OWASP patterns, audit checklist |
| `rails-performance` | verification | N+1 prevention, caching, database tuning, profiling |

### Skill Structure

Each Skill has a `SKILL.md` entry point that describes conventions and links to detailed sub-files:

```
skills/
└── rails-backend/
    ├── SKILL.md        # Entry point: philosophy and sub-file index
    ├── MODELS.md       # Concern architecture, associations, scoping
    ├── CONTROLLERS.md  # REST conventions, strong params, concerns
    ├── JOBS.md         # _now/_later pattern, multi-tenancy context
    └── API.md          # JSON responses, serialization, versioning
```

### Customising Skills

Skills are installed as Markdown files. Edit them to match your project's conventions -- they live at `~/.claude/skills/` (global) or `.claude/skills/` (local).

## Commands

### Project Initialisation

| Command | Description |
|---|---|
| `/ariadna:new-project` | Initialise project: vision, requirements, roadmap |
| `/ariadna:map-codebase` | Analyse existing codebase (brownfield projects) |

### Phase Planning

| Command | Description |
|---|---|
| `/ariadna:plan-phase <n>` | Create detailed execution plan with inline context gathering |

### Execution

| Command | Description |
|---|---|
| `/ariadna:execute-phase <n>` | Execute all plans in a phase (wave-based parallelism) |
| `/ariadna:quick` | Small ad-hoc tasks with Ariadna guarantees |
| `/ariadna:verify-work <n>` | Goal-backward verification for built features |

### Roadmap & Milestones

| Command | Description |
|---|---|
| `/ariadna:add-phase <desc>` | Add phase to end of milestone |
| `/ariadna:insert-phase <after> <desc>` | Insert urgent work as decimal phase (e.g., 7.1) |
| `/ariadna:remove-phase <n>` | Remove future phase and renumber |
| `/ariadna:new-milestone <name>` | Start a new milestone |

### Session & Progress

| Command | Description |
|---|---|
| `/ariadna:progress` | Status overview and next-action routing |

### Debugging

| Command | Description |
|---|---|
| `/ariadna:debug [desc]` | Systematic debugging with persistent state (survives `/clear`) |

## Planning Directory

```
.ariadna_planning/
├── PROJECT.md                # Project vision and requirements
├── ROADMAP.md                # Phase breakdown with status
├── REQUIREMENTS.md           # Detailed requirements
├── config.json               # Model profile and workflow settings
├── memory/                   # Persistent memory across sessions
│   ├── progress.md           # Phase and milestone progress
│   ├── decisions.md          # Key decisions log
│   ├── blockers.md           # Current blockers
│   ├── metrics.md            # Execution metrics
│   ├── session.md            # Last session summary
│   └── history.md            # History digest
├── quick/                    # Quick task plans and summaries
├── debug/
│   └── resolved/
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
    │   ├── 01-01-PLAN.md
    │   ├── 01-01-SUMMARY.md
    │   └── VERIFICATION.md
    └── 02-core-features/
        ├── 02-01-PLAN.md
        └── 02-01-SUMMARY.md
```

## Configuration

Configuration lives in `.ariadna_planning/config.json` and can be viewed or changed via `/ariadna:progress`.

| Setting | Default | Description |
|---|---|---|
| `model_profile` | `"balanced"` | Model profile for agent routing |
| `verifier` | `true` | Run verifier after phase execution |
| `branching_strategy` | `"none"` | Git branching: `none`, `phase`, or `milestone` |
| `phase_branch_template` | `"ariadna/phase-{phase}-{slug}"` | Branch name template for phase strategy |
| `milestone_branch_template` | `"ariadna/{milestone}-{slug}"` | Branch name template for milestone strategy |
| `commit_docs` | `true` | Commit planning documents automatically |
| `search_gitignored` | `false` | Include gitignored files in searches |
| `parallelization` | `true` | Run plans in the same wave in parallel |

### Model Profiles

Control which Claude models agents use:

| Profile | Planner / Roadmapper | Executor / Debugger | Verifier / Mapper |
|---|---|---|---|
| **quality** | Opus | Opus | Sonnet |
| **balanced** (default) | Opus | Sonnet | Sonnet |
| **budget** | Sonnet | Sonnet | Haiku |

### Branching Strategies

| Strategy | When branch is created | Best for |
|---|---|---|
| `none` (default) | Never | Solo development, simple projects |
| `phase` | At `execute-phase` start | Code review per phase, granular rollback |
| `milestone` | At first `execute-phase` in milestone | Release branches, PR per version |

## Default Settings

Ariadna is configured to generate Ruby on Rails applications following the Rails philosophy and conventions. We believe in the [Rails is plenty](https://world.hey.com/jorge/a-vanilla-rails-stack-is-plenty-567a4708) approach -- vanilla Rails with minimal dependencies.

This project has taken inspiration from [Fizzy](https://www.fizzy.do/) and [Once Campfire](https://github.com/basecamp/once-campfire), both great resources for Ruby on Rails best practices. Remember that you can customise Ariadna by editing the Skills installed at `~/.claude/skills/`.

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
- [Matz and the Ruby team](https://www.ruby-lang.org/en/about/) for creating such a wonderful language.

## License

[MIT](LICENSE)
