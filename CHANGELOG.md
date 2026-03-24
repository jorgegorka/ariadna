# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-03-24

Ariadna 2.0 is a major rewrite focused on reducing complexity and improving composability. The system is smaller, faster to load, and easier to reason about.

### Breaking Changes

#### Memory System

- **Removed** `STATE.md` as the primary session memory store
- **Added** `memory/` directory (`.ariadna_planning/memory/`) with per-concern files:
  - `progress.md` — phase and milestone progress
  - `decisions.md` — key decisions log
  - `blockers.md` — current blockers
  - `metrics.md` — execution metrics
  - `session.md` — last session summary
  - `history.md` — history digest
- Workflows now update `memory/progress.md` instead of writing back to a monolithic `STATE.md`

#### Agents: 14 → 6

The agent roster was consolidated from 14 agents to 6:

| Kept | Consolidated from |
|------|------------------|
| `ariadna-executor` | `ariadna-backend-executor`, `ariadna-frontend-executor`, `ariadna-test-executor` — domain routing now handled via Skills |
| `ariadna-planner` | Absorbed `ariadna-plan-checker` (self-checking built in) and `ariadna-phase-researcher` (inline research) |
| `ariadna-verifier` | Absorbed `ariadna-integration-checker` (cross-phase and E2E checks built in) |
| `ariadna-debugger` | Unchanged |
| `ariadna-roadmapper` | Absorbed `ariadna-project-researcher` and `ariadna-research-synthesizer` |
| `ariadna-codebase-mapper` | Unchanged |

#### Workflows: ~30 → 10

| Workflow | Notes |
|----------|-------|
| `execute-phase` | Retained; simplified — no team execution mode |
| `plan-phase` | Retained; plan-checker and researcher merged in |
| `verify-work` | Retained; integration checker merged in |
| `new-project` | Retained |
| `new-milestone` | Retained |
| `map-codebase` | Retained |
| `debug` | Retained |
| `quick` | Retained |
| `progress` | Retained |
| `roadmap-ops` | Consolidates add-phase, insert-phase, remove-phase |

Removed workflows: `discuss-phase`, `research-phase`, `list-phase-assumptions`, `plan-milestone-gaps`, `audit-milestone`, `complete-milestone`, `pause-work`, `resume-work`, `reapply-patches`, `set-profile`, `settings`, and others.

#### Commands: 27 → 12

| Kept | Removed |
|------|---------|
| `new-project` | `discuss-phase` |
| `map-codebase` | `research-phase` |
| `plan-phase` | `list-phase-assumptions` |
| `execute-phase` | `audit-milestone` |
| `verify-work` | `plan-milestone-gaps` |
| `quick` | `complete-milestone` |
| `add-phase` | `pause-work` |
| `insert-phase` | `resume-work` |
| `remove-phase` | `set-profile` |
| `new-milestone` | `settings` |
| `progress` | `reapply-patches` |
| `debug` | `add-todo`, `check-todos`, `help`, `update` |

#### Guides Replaced by Skills

The `guides/` system (6 flat Markdown files) has been replaced by **Rails Skills** — self-contained, composable packages installed to `~/.claude/skills/`.

**Removed guides:**
- `backend.md`
- `frontend.md`
- `testing.md`
- `security.md`
- `performance.md`
- `style-guide.md`

**New Skills (5 packages):**

| Skill | Sub-files |
|-------|-----------|
| `rails-backend` | `SKILL.md`, `MODELS.md`, `CONTROLLERS.md`, `JOBS.md`, `API.md` |
| `rails-frontend` | `SKILL.md`, `VIEWS.md`, `COMPONENTS.md`, `ASSETS.md` |
| `rails-testing` | `SKILL.md`, `FIXTURES.md`, `SYSTEM-TESTS.md` |
| `rails-security` | `SKILL.md`, `AUDIT.md` |
| `rails-performance` | `SKILL.md`, `PROFILING.md` |

Skills have a `SKILL.md` entry point with YAML frontmatter (`name`, `description`) so Claude Code can discover and load them by name. Executors load the domain Skill automatically; the verifier loads the security and performance Skills for non-functional checks.

#### Configuration: Removed Settings

The following config keys were removed:

| Removed key | Reason |
|-------------|--------|
| `team_execution` | Team execution mode removed; wave-based parallelism is the only execution model |
| `execution_mode` | Replaced by `parallelization: true/false` |
| `research` | Research is now always inline (no separate toggle) |
| `plan_checker` | Plan checker absorbed into the planner agent |

**Remaining settings (8 flat keys):**

```json
{
  "model_profile": "balanced",
  "verifier": true,
  "branching_strategy": "none",
  "phase_branch_template": "ariadna/phase-{phase}-{slug}",
  "milestone_branch_template": "ariadna/{milestone}-{slug}",
  "commit_docs": true,
  "search_gitignored": false,
  "parallelization": true
}
```

#### Init: Returns Paths and Metadata Only

`ariadna-tools init` now returns structured metadata (paths, config values, model assignments) instead of loading and returning file contents. Agents are responsible for reading files themselves, keeping the orchestrator context lean.

#### Verification: Simplified

Verification is now strictly goal-backward:

1. **Goal achievement** — did the phase deliver its goal?
2. **Phase completeness** — do SUMMARY.md files exist and pass self-check markers?
3. **Artifacts** — do expected files exist on disk?

Removed: UAT session loop, integration-checker as a separate agent, post-verification approval gate.

### Added

- **Rails Skills system** — 5 standalone SKILL.md packages with domain conventions
- **`memory/` directory** — granular per-concern memory files replacing monolithic STATE.md
- **`ariadna-tools state`** subcommand — append to memory files (decisions, blockers, metrics, session, history)
- `parallelization` config key — explicit control over wave parallelism

### Changed

- `StateManager` rewritten to manage `memory/` directory files; retains history digest and metrics
- `Init` module rewritten to return paths and metadata only (not file contents)
- Model profiles updated for 6-agent system
- Planning directory no longer includes `CONTEXT.md`, `research/` (project-level), or `REQUIREMENTS.md` as required artifacts for quick/milestone workflows

## [1.3.1] - 2026-03-04

### Added

- `require "time"` dependency in core module

### Changed

- Version bump to 1.3.1

## [1.3.0] - 2026-02-27

### Changed

- Opinionated Rails defaults: Devise, Pundit, CanCanCan, and acts_as_tenant are no longer recommended as default choices for new projects
- New `Rails Defaults First` section in rails-conventions reference with comparison table and explicit rule
- Authentication defaults to `has_secure_password` + Rails 8 auth generator; Devise only if user explicitly requests it
- Authorization defaults to `before_action` + `Current` context; Pundit/CanCanCan only if user explicitly requests it
- Multi-tenancy defaults to `Current.account` scoping; acts_as_tenant only if user explicitly requests it
- Auth checkpoint reordered: `has_secure_password` is now the recommended first option
- Updated all research-project and codebase templates to lead with Rails built-in approaches
- Updated phase-researcher agent quality examples to reference Rails defaults

## [1.2.3] - 2026-02-21

### Added

- "Who This Serves" and "Product Vision" sections in PROJECT.md template
- "Why this matters" field for every phase in ROADMAP.md template
- Requirement motivation clauses (`— *why this matters*`) in requirements template
- User-focused and bigger-picture question types in questioning reference
- Purpose-connected phase validation in roadmapper agent quality checklist

### Changed

- Gem description updated to focus on Ruby on Rails application development
- Roadmapper agent derives phase purpose from PROJECT.md user/vision context
- Planner agent reads "Why this matters" from ROADMAP.md to prioritize tasks
- New-project workflow includes requirement motivation guidance and examples
- Context checklist expanded from 4 to 6 items (adds success criteria and bigger picture)
- Requirements template examples include motivation clauses throughout

## [1.2.2] - 2026-02-19

### Changed

- Renamed `.planning` directory to `.ariadna_planning` to avoid conflicts with other gems that use the same directory name (645 occurrences across 119 files)

## [1.2.1] - 2026-02-19

### Added

- Team execution auto-detection: `team_execution: "auto"` config activates team mode for phases with 3+ plans across 2+ domains
- `--no-team` flag for `execute-phase` to force wave-based execution
- `--skip-approval` flag for `plan-phase` to bypass user approval gate
- User plan approval gate in `plan-phase` workflow with requirements cross-referencing
- User acceptance gate in `execute-phase` after verification (reviewable before marking phase complete)
- Requirements traceability in summaries and plan execution (REQUIREMENTS.md cross-referencing)
- Progress reporting table during team execution
- Domain analysis in plan index (domain, dependencies, file ownership, task count)
- Comprehensive frontend guide: Turbo (Drive, Frames, Streams), Stimulus controllers, view templates & partials

### Changed

- Execute-phase workflow refactored: `decide_execution_mode` step replaces simple flag check
- Executor agents skip STATE.md updates in team mode; orchestrator aggregates state sequentially to prevent concurrent write corruption
- Plan-phase context categorization: Category A (infrastructure) auto-skips context, Category B recommends quick discussion first
- Plan index returns enriched data per plan (domain, depends_on, files_modified, autonomous, objective, task_count)
- Init outputs team execution config and domain-specific executor models
- Summary template includes `requirements_covered` frontmatter and markdown section

## [1.2.0] - 2026-02-17

### Added

- Rails conventions reference document (`rails-conventions.md`) with standard stack, architecture patterns, common pitfalls, testing patterns, and domain templates
- Rails-aware planning in ariadna-planner agent (domain templates, known domain detection, pitfall prevention)
- Inline context gathering in `plan-phase` workflow (replaces separate `discuss-phase` step)
- `--research` flag for `new-project` command to force domain research
- `--skip-context` flag for `plan-phase` command

### Changed

- Research disabled by default — Rails conventions are pre-loaded, use `--research` for non-standard integrations
- Streamlined `new-project` workflow: opinionated config defaults (single depth question instead of 8 questions across 2 rounds)
- `new-project` auto mode skips config questions entirely and skips research by default
- `plan-phase` checker issues handled inline (minor fixes by orchestrator, major issues presented to user) instead of revision loop (max 3 iterations)
- Default next step after project creation changed from `/ariadna:discuss-phase 1` to `/ariadna:plan-phase 1`
- Roadmapper agent now receives `rails-conventions.md` as context

### Fixed

- Frontmatter parser crash when encountering non-Hash objects during YAML key parsing
- Missing `require "fileutils"` in ConfigManager (carried from 1.1.4)

## [1.1.4] - 2026-02-16

### Added

- Research project templates (`ARCHITECTURE.md`, `PITFALLS.md`, `STACK.md`)

### Changed

- Updated README to emphasize Rails application focus
- Improved default codebase and research-project templates
- Removed UUID references from agents, templates, and guides (8 files)
- Added frontmatter require in PhaseManager

### Fixed

- Missing `require "fileutils"` in ConfigManager causing `NameError` on `config-ensure-section`
- Documentation typos in README (path references)

## [1.1.3] - 2026-02-15

### Changed

- Major README improvements (248 additions, 39 removals)

## [1.1.2] - 2026-02-15

### Added

- Specialized executor agents: backend (`ariadna-backend-executor.md`), frontend (`ariadna-frontend-executor.md`), test (`ariadna-test-executor.md`)
- Comprehensive guides: frontend, performance, security, testing
- Tests for config manager, frontmatter, model profiles, and installer

### Changed

- Renamed `patterns-and-best-practices.md` guide to `backend.md`
- Enhanced agents: debugger, integration checker, plan checker, planner, verifier
- Improved references: checkpoints, git integration, TDD, verification patterns
- Improved templates: research, verification report, phase prompt, summaries, UAT, user setup
- Improved workflows: execute-phase, diagnose-issues, plan-milestone-gaps, verify-phase
- Updated documentation across codebase and research-project templates

### Removed

- Removed `data/VERSION` file (version tracked only in `lib/ariadna/version.rb`)

## [1.1.1] - 2026-02-15

### Added

- Core CLI with two binaries: `ariadna` (user-facing) and `ariadna-tools` (internal)
- Manifest-based installer with SHA256 integrity and local patch backup
- 27 slash commands for Claude Code
- 11 agent definitions (orchestrators and subagents)
- 29 workflow instructions
- 26 templates for plans, state, reports
- 13 reference documents
- Hierarchical project model (Project → Milestones → Phases → Plans → Tasks)
- Tool modules: StateManager, PhaseManager, RoadmapAnalyzer, ConfigManager, Init, Commit
- Model profiles (quality/balanced/budget) mapping agent types to Claude models
- Wave-based plan execution with parallelism support
- Guides for backend, frontend, and testing workflows

[2.0.0]: https://github.com/jorgegorka/ariadna/releases/tag/v2.0.0
[1.3.1]: https://github.com/jorgegorka/ariadna/releases/tag/v1.3.1
[1.3.0]: https://github.com/jorgegorka/ariadna/releases/tag/v1.3.0
[1.2.3]: https://github.com/jorgegorka/ariadna/releases/tag/v1.2.3
[1.2.2]: https://github.com/jorgegorka/ariadna/releases/tag/v1.2.2
[1.2.1]: https://github.com/jorgegorka/ariadna/releases/tag/v1.2.1
[1.2.0]: https://github.com/jorgegorka/ariadna/releases/tag/v1.2.0
[1.1.4]: https://github.com/jorgegorka/ariadna/releases/tag/v1.1.4
[1.1.3]: https://github.com/jorgegorka/ariadna/releases/tag/v1.1.3
[1.1.2]: https://github.com/jorgegorka/ariadna/releases/tag/v1.1.2
[1.1.1]: https://github.com/jorgegorka/ariadna/releases/tag/v1.1.1
