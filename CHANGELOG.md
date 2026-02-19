# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.2.2]: https://github.com/jorgegorka/ariadna/releases/tag/v1.2.2
[1.2.1]: https://github.com/jorgegorka/ariadna/releases/tag/v1.2.1
[1.2.0]: https://github.com/jorgegorka/ariadna/releases/tag/v1.2.0
[1.1.4]: https://github.com/jorgegorka/ariadna/releases/tag/v1.1.4
[1.1.3]: https://github.com/jorgegorka/ariadna/releases/tag/v1.1.3
[1.1.2]: https://github.com/jorgegorka/ariadna/releases/tag/v1.1.2
[1.1.1]: https://github.com/jorgegorka/ariadna/releases/tag/v1.1.1
