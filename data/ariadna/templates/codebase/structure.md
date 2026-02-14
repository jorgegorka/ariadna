# Structure Template

Template for `.planning/codebase/STRUCTURE.md` - captures physical file organization.

**Purpose:** Document where things physically live in the codebase. Answers "where do I put X?"

---

## File Template

```markdown
# Codebase Structure

**Analysis Date:** [YYYY-MM-DD]

## Directory Layout

[ASCII box-drawing tree of top-level directories with purpose - use ├── └── │ characters for tree structure only]

```
[app-name]/
├── app/               # [Application code]
│   ├── assets/       # [Stylesheets, images]
│   ├── controllers/  # [Request handlers]
│   ├── helpers/      # [View helpers]
│   ├── javascript/   # [Stimulus controllers, JS]
│   ├── jobs/         # [Background jobs]
│   ├── mailers/      # [Email classes]
│   ├── models/       # [Domain models and concerns]
│   └── views/        # [Templates and layouts]
├── bin/               # [Rails executables]
├── config/            # [Configuration files]
├── db/                # [Database schema and migrations]
├── lib/               # [Non-Rails code, Rake tasks]
├── public/            # [Static files]
├── test/              # [Test files]
├── Gemfile            # [Ruby dependencies]
└── Rakefile           # [Rake task loader]
```

## Directory Purposes

**[Directory Name]:**
- Purpose: [What lives here]
- Contains: [Types of files: e.g., "`.rb` model files", "ERB templates"]
- Key files: [Important files in this directory]
- Subdirectories: [If nested, describe structure]

**[Directory Name]:**
- Purpose: [What lives here]
- Contains: [Types of files]
- Key files: [Important files]
- Subdirectories: [Structure]

## Key File Locations

**Entry Points:**
- [Path]: [Purpose: e.g., "`config/routes.rb` — route definitions"]
- [Path]: [Purpose: e.g., "`config/application.rb` — app configuration"]

**Configuration:**
- [Path]: [Purpose: e.g., "`config/database.yml` — database connection"]
- [Path]: [Purpose: e.g., "`config/credentials.yml.enc` — encrypted secrets"]
- [Path]: [Purpose: e.g., "`config/environments/production.rb` — production config"]

**Core Logic:**
- [Path]: [Purpose: e.g., "`app/models/` — domain models"]
- [Path]: [Purpose: e.g., "`app/controllers/` — request handlers"]
- [Path]: [Purpose: e.g., "`app/jobs/` — background processing"]

**Testing:**
- [Path]: [Purpose: e.g., "`test/models/` — model tests"]
- [Path]: [Purpose: e.g., "`test/fixtures/` — YAML test data"]

**Documentation:**
- [Path]: [Purpose: e.g., "User-facing docs"]
- [Path]: [Purpose: e.g., "Developer guide"]

## Naming Conventions

**Files:**
- [Pattern]: [Example: e.g., "`snake_case.rb` for all Ruby files"]
- [Pattern]: [Example: e.g., "`*_controller.rb` for controllers"]
- [Pattern]: [Example: e.g., "`*_test.rb` for test files"]

**Directories:**
- [Pattern]: [Example: e.g., "snake_case for all directories"]
- [Pattern]: [Example: e.g., "plural names for collections (`models/`, `controllers/`)"]

**Special Patterns:**
- [Pattern]: [Example: e.g., "`*_job.rb` suffix for background jobs"]
- [Pattern]: [Example: e.g., "`*_mailer.rb` suffix for mailer classes"]

## Where to Add New Code

**New Model:**
- Primary code: [Directory path]
- Tests: [Directory path]
- Migration: [Directory path]

**New Controller:**
- Implementation: [Directory path]
- Views: [Directory path]
- Tests: [Directory path]

**New Background Job:**
- Implementation: [Directory path]
- Tests: [Directory path]

**New Mailer:**
- Implementation: [Directory path]
- Views: [Directory path]
- Tests: [Directory path]

## Special Directories

[Any directories with special meaning or generation]

**[Directory]:**
- Purpose: [e.g., "Generated migration files"]
- Source: [e.g., "`rails generate migration`"]
- Committed: [Yes/No - in `.gitignore`?]

---

*Structure analysis: [date]*
*Update when directory structure changes*
```

<good_examples>
```markdown
# Codebase Structure

**Analysis Date:** 2025-01-20

## Directory Layout

```
myapp/
├── app/                # Application code
│   ├── assets/        # Stylesheets, images
│   ├── controllers/   # Request handlers
│   │   └── concerns/  # Shared controller behavior
│   ├── helpers/       # View helpers
│   ├── javascript/    # Stimulus controllers, JS
│   │   └── controllers/
│   ├── jobs/          # Background jobs
│   ├── mailers/       # Email classes
│   ├── models/        # Domain models
│   │   ├── concerns/  # Shared model concerns
│   │   ├── card/      # Card-specific concerns
│   │   └── board/     # Board-specific concerns
│   └── views/         # Templates (ERB)
│       └── layouts/   # Layout templates
├── bin/               # Rails executables (rails, rake, setup)
├── config/            # Configuration
│   ├── environments/  # Per-environment config
│   ├── initializers/  # Boot-time setup
│   └── locales/       # I18n translations
├── db/                # Database
│   ├── migrate/       # Migration files
│   └── schema.rb      # Current schema
├── lib/               # Non-Rails code, Rake tasks
│   └── tasks/         # Custom Rake tasks
├── log/               # Log files
├── public/            # Static files
├── storage/           # ActiveStorage files (dev)
├── test/              # Test files
│   ├── controllers/   # Controller tests
│   ├── fixtures/      # YAML test data
│   ├── models/        # Model tests
│   ├── system/        # System (browser) tests
│   └── test_helper.rb # Test configuration
├── tmp/               # Temporary files
├── Gemfile            # Ruby dependencies
├── Gemfile.lock       # Locked versions
├── Rakefile           # Rake task loader
└── config.ru          # Rack configuration
```

## Directory Purposes

**`app/models/`**
- Purpose: Domain models and business logic
- Contains: `*.rb` model files, one class per file
- Key files: `application_record.rb` (base class), `current.rb` (CurrentAttributes)
- Subdirectories: `concerns/` (shared concerns like `Eventable`, `Searchable`), model-specific directories (`card/`, `board/`) for namespaced concerns (`Card::Closeable`, `Board::Accessible`)

**`app/controllers/`**
- Purpose: Handle HTTP requests and render responses
- Contains: `*_controller.rb` files, one per resource
- Key files: `application_controller.rb` (base class with shared filters and error handling)
- Subdirectories: `concerns/` (shared behavior like `CardScoped`, `BoardScoped`), namespace directories for nested resources (`cards/`)

**`app/views/`**
- Purpose: Response templates
- Contains: ERB templates organized by controller name
- Key files: `layouts/application.html.erb` (main layout)
- Subdirectories: One directory per controller (`cards/`, `boards/`), `layouts/` for layout templates, `shared/` for cross-controller partials

**`app/jobs/`**
- Purpose: Background job classes
- Contains: `*_job.rb` files, one per job
- Key files: `application_job.rb` (base class with tenant context handling)
- Subdirectories: None (flat structure)

**`app/mailers/`**
- Purpose: Email delivery classes
- Contains: `*_mailer.rb` files, one per mailer
- Key files: `application_mailer.rb` (base class with default settings)
- Subdirectories: None (flat structure, views live in `app/views/` under mailer name)

**`app/javascript/`**
- Purpose: Client-side JavaScript
- Contains: Stimulus controllers, Turbo configuration
- Key files: `application.js` (JS entry point)
- Subdirectories: `controllers/` (Stimulus controllers)

**`config/`**
- Purpose: Application and framework configuration
- Contains: YAML config files, Ruby initializers, environment configs
- Key files: `routes.rb` (URL routing), `database.yml` (database connection), `application.rb` (app config), `credentials.yml.enc` (encrypted secrets)
- Subdirectories: `environments/` (per-environment overrides), `initializers/` (boot-time setup), `locales/` (I18n translation YAML)

**`db/`**
- Purpose: Database schema and migrations
- Contains: Migration files, schema definition, seed data
- Key files: `schema.rb` (current schema snapshot), `seeds.rb` (seed data)
- Subdirectories: `migrate/` (timestamped migration files)

**`test/`**
- Purpose: Automated tests
- Contains: `*_test.rb` files organized by type
- Key files: `test_helper.rb` (test configuration, shared setup)
- Subdirectories: `models/` (model tests), `controllers/` (controller tests), `system/` (browser-driven system tests), `fixtures/` (YAML test data), `integration/` (multi-request flow tests)

**`lib/`**
- Purpose: Non-Rails code and custom Rake tasks
- Contains: Standalone Ruby classes, Rake task definitions
- Key files: Depends on project
- Subdirectories: `tasks/` (custom `.rake` files)

**`bin/`**
- Purpose: Rails executable scripts
- Contains: Binstubs for project tools
- Key files: `rails` (Rails CLI), `rake` (Rake runner), `setup` (project setup script)
- Subdirectories: None

## Key File Locations

**Entry Points:**
- `config/routes.rb`: Route definitions — maps URLs to controller actions
- `config/application.rb`: Application class and framework configuration
- `config.ru`: Rack configuration — boots the Rails app for the web server

**Configuration:**
- `config/database.yml`: Database connection settings (per-environment)
- `config/credentials.yml.enc`: Encrypted secrets (API keys, service credentials)
- `config/environments/production.rb`: Production-specific settings
- `config/environments/development.rb`: Development-specific settings
- `config/initializers/`: Boot-time setup files (one per gem/concern)

**Core Logic:**
- `app/models/`: Domain models, associations, validations, business logic
- `app/controllers/`: Request handling, auth checks, response rendering
- `app/jobs/`: Background processing (email delivery, data imports, cleanup)
- `app/models/concerns/`: Shared model behavior (`Eventable`, `Searchable`)
- `app/controllers/concerns/`: Shared controller behavior (`CardScoped`, `BoardScoped`)

**Testing:**
- `test/test_helper.rb`: Test configuration, shared helpers, fixture loading
- `test/models/`: Model unit tests
- `test/controllers/`: Controller tests (request-level)
- `test/system/`: System tests (browser-driven via Capybara)
- `test/fixtures/`: YAML fixture data for test database

**Documentation:**
- `README.md`: Project overview and setup instructions
- `CLAUDE.md`: Instructions for Claude Code when working in this repo

## Naming Conventions

**Files:**
- `snake_case.rb`: All Ruby files (`user.rb`, `board.rb`, `event.rb`)
- `*_controller.rb`: Controller files (`users_controller.rb`, `boards_controller.rb`)
- `*_test.rb`: Test files (`user_test.rb`, `boards_controller_test.rb`)
- `*_job.rb`: Background job files (`notify_recipients_job.rb`)
- `*_mailer.rb`: Mailer files (`invitation_mailer.rb`)
- `*.html.erb`: View templates (`show.html.erb`, `_card.html.erb`)
- `_*.html.erb`: Partials (leading underscore: `_form.html.erb`, `_header.html.erb`)

**Directories:**
- `snake_case`: All directories (`active_storage/`, `action_mailbox/`)
- Plural for collections: `models/`, `controllers/`, `views/`, `helpers/`
- Singular for model-specific concern namespaces: `card/`, `board/`

**Special Patterns:**
- `application_*.rb`: Base classes (`application_record.rb`, `application_controller.rb`, `application_job.rb`, `application_mailer.rb`)
- `concerns/`: Shared behavior modules in both `models/` and `controllers/`
- `YYYYMMDDHHMMSS_*.rb`: Timestamped migration files (`20250120143052_create_cards.rb`)

## Where to Add New Code

**New Model:**
- Primary code: `app/models/thing.rb`
- Tests: `test/models/thing_test.rb`
- Migration: `db/migrate/YYYYMMDDHHMMSS_create_things.rb` (via `rails generate migration`)
- Fixtures: `test/fixtures/things.yml`

**New Shared Concern:**
- Implementation: `app/models/concerns/eventable.rb`
- Usage: `include Eventable` in model files

**New Model-Specific Concern:**
- Implementation: `app/models/card/closeable.rb` (defines `Card::Closeable`)
- Tests: Tested through the model that includes it (`test/models/card_test.rb`)

**New Controller:**
- Implementation: `app/controllers/things_controller.rb`
- Views: `app/views/things/` (one template per action)
- Tests: `test/controllers/things_controller_test.rb`
- Routes: Add `resources :things` to `config/routes.rb`

**New Background Job:**
- Implementation: `app/jobs/thing_job.rb`
- Tests: `test/jobs/thing_job_test.rb`

**New Mailer:**
- Implementation: `app/mailers/thing_mailer.rb`
- Views: `app/views/thing_mailer/` (one template per email action)
- Tests: `test/mailers/thing_mailer_test.rb`

**New Rake Task:**
- Implementation: `lib/tasks/thing.rake`

**New Initializer:**
- Implementation: `config/initializers/thing.rb`

## Special Directories

**`db/migrate/`:**
- Purpose: Generated migration files that alter database schema
- Source: `rails generate migration` or `rails generate model`
- Committed: Yes — migrations are shared across environments

**`tmp/`:**
- Purpose: Cache files, PID files, sockets
- Source: Generated at runtime by Rails and Puma
- Committed: No — in `.gitignore`

**`log/`:**
- Purpose: Development, test, and production log files
- Source: Written by Rails logger during execution
- Committed: No — in `.gitignore`

**`storage/`:**
- Purpose: ActiveStorage file uploads in development
- Source: Uploaded files stored locally via ActiveStorage
- Committed: No — in `.gitignore`

**`node_modules/`:**
- Purpose: JavaScript dependencies (if using Node-based bundler)
- Source: Installed by `yarn install` or `npm install`
- Committed: No — in `.gitignore`

**`public/`:**
- Purpose: Static files served directly by the web server
- Source: Manually placed or compiled assets
- Committed: Yes — static assets like `404.html`, `robots.txt`

---

*Structure analysis: 2025-01-20*
*Update when directory structure changes*
```
</good_examples>

<guidelines>
**What belongs in STRUCTURE.md:**
- Directory layout (ASCII box-drawing tree for structure visualization)
- Purpose of each directory
- Key file locations (entry points, configs, core logic)
- Naming conventions
- Where to add new code (by type)
- Special/generated directories

**What does NOT belong here:**
- Conceptual architecture (that's ARCHITECTURE.md)
- Technology stack (that's STACK.md)
- Code implementation details (defer to code reading)
- Every single file (focus on directories and key files)

**When filling this template:**
- Use `tree -L 2` or similar to visualize the Rails app structure
- Identify top-level directories and their purposes
- Note naming patterns by observing existing files (snake_case, suffixes)
- Locate entry points (`config/routes.rb`, `config/application.rb`), configs, and main logic areas
- Check for model-specific concern directories (`app/models/card/`, `app/models/board/`) — these indicate concern architecture depth
- Keep directory tree concise (max 2-3 levels)

**Tree format (ASCII box-drawing characters for structure only):**
```
myapp/
├── app/               # Purpose
│   ├── models/       # Purpose
│   └── controllers/  # Purpose
├── config/            # Purpose
└── Gemfile            # Purpose
```

**Useful for phase planning when:**
- Adding new models (create model + migration + test + fixture)
- Adding new controllers and views (where do templates go? what about routes?)
- Extracting shared behavior (which `concerns/` directory? shared or model-specific?)
- Adding background jobs or mailers (follow naming conventions and directory structure)
- Understanding where configuration lives (`config/initializers/` vs `config/environments/`)
- Following existing conventions for file naming and directory organization
</guidelines>
