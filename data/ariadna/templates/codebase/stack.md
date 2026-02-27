# Technology Stack Template

Template for `.ariadna_planning/codebase/STACK.md` - captures the technology foundation.

**Purpose:** Document what technologies run this codebase. Focused on "what executes when you run the code."

---

## File Template

```markdown
# Technology Stack

**Analysis Date:** [YYYY-MM-DD]

## Languages

**Primary:**
- [Language] [Version] - [Where used: e.g., "all application code"]

**Secondary:**
- [Language] [Version] - [Where used: e.g., "Stimulus controllers, Turbo interactions"]

## Runtime

**Environment:**
- [Runtime] [Version] - [e.g., "Ruby 3.3 from `.ruby-version`"]
- [Additional requirements if any]

**Package Manager:**
- [Manager] [Version] - [e.g., "Bundler 2.x"]
- Lockfile: [e.g., "`Gemfile.lock` present"]

## Frameworks

**Core:**
- [Framework] [Version] - [Purpose: e.g., "full-stack web framework"]

**Testing:**
- [Framework] [Version] - [e.g., "Minitest for unit/integration/system tests"]
- [Framework] [Version] - [e.g., "Capybara for system tests"]

**Build/Dev:**
- [Tool] [Version] - [e.g., "Propshaft for asset pipeline"]
- [Tool] [Version] - [e.g., "importmap-rails for JavaScript module loading"]

## Key Dependencies

[Only include dependencies critical to understanding the stack - limit to 5-10 most important]

**Critical:**
- [Gem] [Version] - [Why it matters: e.g., "authentication", "background jobs"]
- [Gem] [Version] - [Why it matters]

**Infrastructure:**
- [Gem] [Version] - [e.g., "SQLite adapter" or "PostgreSQL adapter"]
- [Gem] [Version] - [e.g., "application server"]

## Configuration

**Environment:**
- [How configured: e.g., "`config/database.yml`, `config/credentials.yml.enc`"]
- [Key configs: e.g., "`config/environments/*.rb` per-environment settings"]

**Build:**
- [Build config files: e.g., "`config/importmap.rb`", "`Procfile.dev`"]

## Platform Requirements

**Development:**
- [OS requirements or "any platform"]
- [Additional tooling if any: e.g., "PostgreSQL" if not using SQLite]

**Production:**
- [Deployment target: e.g., "Kamal to VPS", "Docker container", "Heroku", "Fly.io"]
- [Application server: e.g., "Puma"]

---

*Stack analysis: [date]*
*Update after major dependency changes*
```

<good_examples>
```markdown
# Technology Stack

**Analysis Date:** 2025-01-20

## Languages

**Primary:**
- Ruby 3.3 — All application code

**Secondary:**
- JavaScript — Stimulus controllers, Turbo interactions
- CSS/SCSS — Styling

## Runtime

**Environment:**
- Ruby 3.3 (from `.ruby-version`)
- Bundler 2.x

**Package Manager:**
- Bundler 2.x
- Lockfile: `Gemfile.lock` present

## Frameworks

**Core:**
- Rails 8.x — Full-stack web framework

**Testing:**
- Minitest 5.x — Unit, integration, system tests
- Capybara — System tests with browser automation

**Build/Dev:**
- Propshaft — Asset pipeline
- importmap-rails — JavaScript module loading without bundler

## Key Dependencies

**Critical:**
- authentication (built-in) — Session-based auth
- authorization - custom implementation (before_action + Current) — Role-based access control
- solid_queue — Background jobs (Rails 8 default)

**Infrastructure:**
- sqlite3 — SQLite adapter (Rails default)
- solid_cache — Database-backed caching (Rails 8 default)
- puma — Application server

## Configuration

**Environment:**
- `config/database.yml`, `config/credentials.yml.enc`, `config/environments/*.rb`
- `SECRET_KEY_BASE` required in production

**Build:**
- `config/importmap.rb` — JavaScript module pins
- `Procfile.dev` — Development process manager

## Platform Requirements

**Development:**
- macOS/Linux
- No Docker or external database required for local development (SQLite is file-based)

**Production:**
- Kamal deployment to VPS, Docker container, Puma application server
- SQLite (or PostgreSQL for high-concurrency production)

---

*Stack analysis: 2025-01-20*
*Update after major dependency changes*
```
</good_examples>

<guidelines>
**What belongs in STACK.md:**
- Languages and versions
- Runtime requirements (Ruby version, Bundler)
- Package manager and lockfile
- Framework choices
- Critical dependencies (limit to 5-10 most important)
- Build tooling and asset pipeline
- Platform/deployment requirements

**What does NOT belong here:**
- File structure (that's STRUCTURE.md)
- Architectural patterns (that's ARCHITECTURE.md)
- Every gem in `Gemfile` (only critical ones)
- Implementation details (defer to code)

**When filling this template:**
- Check `Gemfile` for dependencies and framework versions
- Note Ruby version from `.ruby-version` or `Gemfile`
- Check `config/` directory for framework configuration and asset pipeline setup
- Include only dependencies that affect understanding (not every utility gem)
- Specify versions only when version matters (breaking changes, compatibility)

**Useful for phase planning when:**
- Adding new dependencies (check compatibility)
- Upgrading frameworks (know what's in use)
- Choosing implementation approach (must work with existing stack)
- Understanding build requirements
</guidelines>
