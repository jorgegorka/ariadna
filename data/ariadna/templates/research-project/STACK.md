# Stack Research Template

Template for `.planning/research/STACK.md` — discovered technology stack for the Rails project.

<template>

```markdown
# Stack Research

**Project:** [project name]
**Researched:** [date]
**Confidence:** [HIGH/MEDIUM/LOW]

## Core Platform

| Component | Discovered Value | Source |
|-----------|-----------------|--------|
| Ruby version | [version from .ruby-version or Gemfile] | [where found] |
| Rails version | [version from Gemfile.lock] | [where found] |
| Database | [PostgreSQL/MySQL/SQLite] | [config/database.yml] |
| Ruby version manager | [rbenv/asdf/chruby/rvm/none] | [where found] |

## Application Type

| Aspect | Discovered Value | Evidence |
|--------|-----------------|----------|
| API-only or full-stack | [rails new --api or full] | [ApplicationController inherits from API or Base] |
| Monolith or engines | [single app / modular engines] | [presence of engines/ or components/] |
| Multi-database | [yes/no] | [database.yml configuration] |
| Multi-tenancy | [none/schema-based/row-based] | [tenant isolation approach if any] |

## Frontend & Assets

| Category | Discovered Value | Evidence |
|----------|-----------------|----------|
| JS approach | [Importmap/esbuild/Vite/Webpacker/Shakapacker/none] | [config files, Gemfile] |
| CSS approach | [Custom CSS/Tailwind/Bootstrap/none] | [app/assets/stylesheets/, Gemfile] |
| Real-time | [Turbo Streams/Action Cable/AnyCable/none] | [Gemfile, channel files] |
| Hotwire/Turbo | [yes/no, version] | [Gemfile, stimulus controllers] |
| Stimulus | [yes/no, version] | [controllers directory, importmap pins] |
| View layer | [ERB/Haml/Slim/ViewComponent/Phlex] | [app/views file extensions, Gemfile] |

## Backend Services

| Category | Discovered Value | Evidence |
|----------|-----------------|----------|
| Background jobs | [Solid Queue/Sidekiq/GoodJob/DelayedJob/none] | [Gemfile, config/application.rb] |
| Caching backend | [Solid Cache/Redis/Memcached/file store] | [config/environments/, Gemfile] |
| Action Cable adapter | [Solid Cable/Redis/async/none] | [config/cable.yml] |
| Search | [pg_search/Elasticsearch/Meilisearch/none] | [Gemfile, model concerns] |
| File storage | [Active Storage/Shrine/CarrierWave/none] | [Gemfile, storage.yml] |
| File storage service | [local/S3/GCS/Azure/none] | [config/storage.yml] |
| Email | [Action Mailer/Postmark/SendGrid/none] | [Gemfile, mailer configs] |
| PDF generation | [Prawn/wicked_pdf/Grover/none] | [Gemfile] |

## Authentication & Authorization

| Category | Discovered Value | Evidence |
|----------|-----------------|----------|
| Authentication | [Rails authentication generator/Rodauth/Clearance/custom/none] | [Gemfile, user model] |
| Authorization | [Pundit/CanCanCan/Action Policy/custom/none] | [Gemfile, policy files] |
| OAuth/social login | [OmniAuth/Doorkeeper/none] | [Gemfile, initializers] |
| API authentication | [API tokens/JWT/OAuth2/none] | [Gemfile, controller concerns] |

## Testing

| Category | Discovered Value | Evidence |
|----------|-----------------|----------|
| Test framework | [Minitest/RSpec] | [test/ or spec/ directory, Gemfile] |
| Fixtures or factories | [fixtures/FactoryBot/Fabrication] | [test/fixtures or spec/factories] |
| System tests | [Capybara driver: Selenium/Cuprite/Playwright] | [Gemfile, test_helper or rails_helper] |
| Code coverage | [SimpleCov/none] | [Gemfile, test_helper] |
| Linting | [RuboCop/Standard/none] | [Gemfile, .rubocop.yml] |
| Static analysis | [Brakeman/Bundler Audit/none] | [Gemfile, CI config] |

## Infrastructure & Deployment

| Category | Discovered Value | Evidence |
|----------|-----------------|----------|
| Deployment | [Kamal/Capistrano/Heroku/Render/Fly.io/Docker/other] | [deploy configs, Dockerfile] |
| CI/CD | [GitHub Actions/CircleCI/GitLab CI/none] | [.github/workflows, .circleci] |
| Containerized | [yes/no] | [Dockerfile, docker-compose.yml] |
| Process manager | [Foreman/Overmind/Puma only] | [Procfile, Procfile.dev] |
| Credentials management | [Rails credentials/dotenv/Figaro] | [config/credentials, .env files] |

## Gem Inventory

### Core Gems (from Gemfile)

| Gem | Version Constraint | Group | Purpose |
|-----|-------------------|-------|---------|
| [gem name] | [~> X.Y] | [default/development/test/production] | [what it does in this project] |
| [gem name] | [~> X.Y] | [default/development/test/production] | [what it does in this project] |
| [gem name] | [~> X.Y] | [default/development/test/production] | [what it does in this project] |

### Development & Debugging Gems

| Gem | Purpose | Notes |
|-----|---------|-------|
| [gem name] | [what it does] | [configuration if relevant] |
| [gem name] | [what it does] | [configuration if relevant] |

## Project Setup

```bash
# System dependencies
[discovered system deps: postgresql, etc.]

# Ruby setup
[ruby version manager install command if applicable]

# Application setup
bundle install
bin/rails db:prepare

# Asset pipeline (if applicable)
[bin/rails assets:precompile / yarn build / none]

# Background jobs (if applicable)
[bin/jobs (Solid Queue) / bundle exec sidekiq / none]

# Development server
bin/dev
# or
bin/rails server
```

## Alternatives Considered

| In Use | Alternative | When to Consider Switching |
|--------|-------------|---------------------------|
| [current choice] | [other option] | [conditions where alternative fits better] |
| [current choice] | [other option] | [conditions where alternative fits better] |

## What to Avoid

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| [gem or pattern] | [specific problem: deprecated, unmaintained, security issue, incompatible] | [recommended alternative] |
| [gem or pattern] | [specific problem] | [recommended alternative] |

## Rails Variant Decisions

**If API-only app:**
- [relevant architectural notes]
- [serialization approach: jbuilder/Alba/Blueprinter/none]
- [API versioning strategy if any]

**If full-stack with Hotwire:**
- [Turbo Frame vs Turbo Stream usage patterns]
- [Stimulus controller conventions]
- [Broadcasting patterns if any]

**If full-stack with SPA frontend:**
- [Frontend framework: React/Vue/Svelte]
- [API layer: GraphQL/REST/Inertia.js]
- [CORS and authentication approach]

**If modular monolith with engines:**
- [Engine boundaries and responsibilities]
- [Shared dependencies across engines]
- [Inter-engine communication patterns]

## Version Compatibility

| Gem | Compatible With | Notes |
|-----|-----------------|-------|
| [gem @ version] | [Rails version / Ruby version] | [compatibility notes] |
| [gem @ version] | [other gem @ version] | [known constraints] |

## Configuration Files Discovered

| File | Purpose | Notable Settings |
|------|---------|-----------------|
| [config file path] | [what it configures] | [any non-default values worth noting] |
| [config file path] | [what it configures] | [any non-default values worth noting] |

## Sources

- [Gemfile and Gemfile.lock] — [primary source of gem versions]
- [config/ directory] — [Rails configuration files]
- [Official docs URL] — [what was verified]
- [Other source] — [confidence level]

---
*Stack research for: [project name]*
*Researched: [date]*
```

</template>

<guidelines>

**Discovery, Not Prescription:**
- This template is for discovering what the project ACTUALLY uses
- Fill in values by inspecting `Gemfile`, `Gemfile.lock`, `config/`, and project structure
- Do not assume or recommend — report what is found
- If a category has nothing discovered, mark it `[none found]` rather than suggesting additions

**Core Platform:**
- Always check `.ruby-version`, `Gemfile`, and `Gemfile.lock` for exact versions
- Check `config/database.yml` for the actual database adapter in use
- Check `config/application.rb` and environment files for framework defaults

**Application Type:**
- Determine if `ApplicationController` inherits from `ActionController::API` or `ActionController::Base`
- Look for `config.api_only = true` in `config/application.rb`
- Check for presence of `engines/`, `components/`, or `packages/` directories
- Look at `database.yml` for multiple database configurations

**Frontend & Assets:**
- Check for `config/importmap.rb` (Importmap), `package.json` (Node-based), or `vite.config.ts` (Vite)
- Look at `app/views/layouts/application.html.erb` for asset tags
- Check `app/javascript/` structure and `app/assets/` for CSS approach
- Look for `app/components/` (ViewComponent) or Phlex usage

**Backend Services:**
- Check `config/application.rb` for `active_job.queue_adapter` setting
- Check `config/environments/production.rb` for cache store configuration
- Look at `config/cable.yml` for Action Cable adapter
- Check `config/storage.yml` for Active Storage service

**Authentication & Authorization:**
- Look for `Authentication` concern generated by `rails generate authentication`
- Look for `app/policies/` (Pundit) or `app/models/ability.rb` (CanCanCan)
- Check `app/models/user.rb` for authentication modules

**Testing:**
- Determine framework by checking for `test/` (Minitest) vs `spec/` (RSpec)
- Check `test/test_helper.rb` or `spec/rails_helper.rb` for test configuration
- Look for `test/fixtures/` or `spec/factories/` to determine data strategy
- Check for system test configuration and browser driver

**What to Avoid:**
- Flag gems that are no longer maintained or have known security issues
- Note deprecated Rails patterns found in the codebase (e.g., `before_filter`, `attr_accessible`)
- Identify gems that duplicate Rails built-in functionality unnecessarily
- Flag any gems with known incompatibilities with the discovered Rails version

**Gem Inventory:**
- Record version constraints as written in the Gemfile, not resolved versions
- Note which Bundler group each gem belongs to
- For important gems, check if the version is current or significantly outdated

**Version Compatibility:**
- Note any gems that pin to specific Rails or Ruby versions
- Flag if the Ruby version is approaching end-of-life
- Check if major gem upgrades are available that would require migration work

</guidelines>
