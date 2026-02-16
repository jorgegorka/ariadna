# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.1.4]: https://github.com/jorgegorka/ariadna/releases/tag/v1.1.4
[1.1.3]: https://github.com/jorgegorka/ariadna/releases/tag/v1.1.3
[1.1.2]: https://github.com/jorgegorka/ariadna/releases/tag/v1.1.2
[1.1.1]: https://github.com/jorgegorka/ariadna/releases/tag/v1.1.1
