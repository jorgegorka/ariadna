# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.1.1]: https://github.com/jorgegorka/ariadna/releases/tag/v1.1.1
