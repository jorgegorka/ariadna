# Plan: Make Codebase Templates Rails-Focused

## Context

The templates in `data/ariadna/templates/codebase/` are used by Ariadna's codebase mapping agents to generate `.ariadna_planning/codebase/` documents when analyzing a Rails project. Currently, all templates except `architecture.md` are generic/framework-agnostic with JavaScript/TypeScript examples (Next.js, Vitest, npm, etc.). Since Ariadna is targeting Ruby on Rails applications, these templates should use Rails-specific terminology, examples, tools, and patterns.

`architecture.md` has already been updated and serves as the reference for style and approach.

## Approach

Launch **6 parallel agents** (one per file), each tasked with rewriting a single template to be Rails-focused. Each agent will:
1. Read `data/guides/backend.md` and `data/guides/testing.md` for Rails patterns context
2. Read the already-updated `architecture.md` as a style reference
3. Read its assigned template file
4. Rewrite the template with Rails-specific content

## Files to Update

### 1. `concerns.md` — Codebase Concerns
- Replace JS/Next.js examples with Rails examples:
  - **Tech Debt**: N+1 queries, raw SQL instead of scopes, business logic in controllers, missing concern extraction
  - **Known Bugs**: ActiveRecord callback ordering, race conditions in background jobs, stale Current context
  - **Security**: Mass assignment, missing authorization checks, unscoped queries leaking tenant data
  - **Performance**: N+1 queries, missing database indexes, heavy callbacks, unoptimized eager loading
  - **Fragile Areas**: Complex concern chains, callback ordering, multi-tenancy scoping
  - **Dependencies at Risk**: Outdated gems, deprecated Rails APIs
  - **Test Coverage Gaps**: Missing model concern tests, controller integration tests
- Update guidelines to reference Rails file paths (`app/models/`, `app/controllers/`, etc.)

### 2. `conventions.md` — Coding Conventions
- Replace JS/TS conventions with Ruby/Rails conventions:
  - **Naming**: snake_case methods/variables, PascalCase classes/modules, SCREAMING_SNAKE constants, `?` for booleans, `!` for bang methods
  - **Code Style**: RuboCop config, `frozen_string_literal: true`, double quotes, 120 char line length, 2-space indentation
  - **Require/Include Organization**: Ruby require patterns, concern includes, module nesting
  - **Error Handling**: `rescue` patterns, custom error classes, `rescue_from` in controllers
  - **Logging**: `Rails.logger`, tagged logging
  - **Comments**: `# frozen_string_literal: true`, YARD docs (if used), TODO patterns
  - **Method Design**: Ruby method conventions, keyword arguments, method visibility (public/private)
  - **Module Design**: Concern patterns, module nesting, `ActiveSupport::Concern`
- Reference patterns from the Fizzy guide (intention-revealing APIs, imperative verbs for actions, boolean pairs)

### 3. `integrations.md` — External Integrations
- Replace JS/Supabase/Vercel examples with Rails ecosystem:
  - **Payment**: Stripe via `stripe` gem
  - **Email**: ActionMailer with SMTP/Postmark/SendGrid
  - **Databases**: SQLite (Rails default) or PostgreSQL via ActiveRecord, `database.yml`
  - **File Storage**: ActiveStorage with S3/GCS/local disk
  - **Caching**: Solid Cache/Redis via `Rails.cache`
  - **Auth**: Rails authentication generator, OmniAuth
  - **Monitoring**: Sentry/Honeybadger via gems
  - **CI/CD**: GitHub Actions, Kamal/Docker deployment
  - **Background Jobs**: Solid Queue/Sidekiq/GoodJob
  - **Webhooks**: Rails controller endpoints with signature verification

### 4. `stack.md` — Technology Stack
- Replace Node.js/TypeScript/npm examples with:
  - **Languages**: Ruby (version from `.ruby-version`), JavaScript/CSS for assets
  - **Runtime**: Ruby + Bundler, `.ruby-version`
  - **Frameworks**: Rails (version), Minitest (recommended)/RSpec, Hotwire/Turbo/Stimulus
  - **Key Dependencies**: Key gems (solid_queue, solid_cache, etc.)
  - **Configuration**: `database.yml`, `credentials.yml.enc`, `config/environments/`
  - **Build**: Asset pipeline (Propshaft/Sprockets), importmap/esbuild/vite
  - **Platform**: Kamal, Docker, Heroku, etc.

### 5. `structure.md` — Codebase Structure
- Replace JS project structure with Rails directory layout:
  - Standard Rails directories: `app/`, `config/`, `db/`, `lib/`, `test/`, `public/`, `bin/`
  - `app/` subdirectories: `models/`, `controllers/`, `views/`, `jobs/`, `mailers/`, `helpers/`
  - Model-specific concern directories: `app/models/card/`, `app/models/board/`
  - Config files: `routes.rb`, `database.yml`, `application.rb`, initializers
  - Where to add new code: new model → `app/models/`, new concern → `app/models/concerns/` or `app/models/{model}/`, new controller → `app/controllers/`, etc.
  - Special directories: `db/migrate/`, `tmp/`, `log/`, `storage/`
  - Naming: snake_case for everything, `_test.rb` suffix, `_controller.rb` suffix

### 6. `testing.md` — Testing Patterns
- Remove the JS/Vitest primary example entirely, keep only Rails content
- Make Rails/Minitest the primary template (not a secondary example):
  - **Framework**: Minitest (Rails default), `test_helper.rb`
  - **Organization**: `test/` mirroring `app/`, fixtures in `test/fixtures/`
  - **Structure**: `ActiveSupport::TestCase`, `setup` blocks, `test "description"` blocks
  - **Mocking**: `Minitest::Mock`, `stub`, `travel_to` for time
  - **Fixtures**: YAML fixtures (Rails default), fixture accessor methods
  - **Test Types**: Model tests, controller tests, integration tests, system tests (Capybara)
  - **Patterns**: `assert_difference`, `assert_changes`, `assert_no_difference`, Current context setup
  - **Coverage**: SimpleCov
- Reference patterns from Fizzy guide (fixture-based testing, Current.session setup, event assertion patterns)

## Verification

After all 6 agents complete:
1. Read each updated file to confirm Rails-specific content
2. Verify no JS/TS/Node.js references remain in templates or examples
3. Verify consistency with the already-updated `architecture.md` style
4. Run `bundle exec rubocop` to verify no gem code was affected
