# Architecture Template

Template for `.planning/codebase/ARCHITECTURE.md` - captures conceptual code organization.

**Purpose:** Document how the code is organized at a conceptual level. Complements STRUCTURE.md (which shows physical file locations).

---

## File Template

```markdown
# Architecture

**Analysis Date:** [YYYY-MM-DD]

## Pattern Overview

**Overall:** [Pattern name: e.g., "Rails Monolith", "Rails API-only", "Rails + Hotwire", "Rails Engine-based"]

**Multi-Tenancy:** [e.g., "Path-based with CurrentAttributes", "Subdomain-based", "session based", "Single-tenant", "None"]

**Key Characteristics:**
- [Characteristic 1: e.g., "Server-rendered with Turbo"]
- [Characteristic 2: e.g., "RESTful resource routing with nested sub-resources"]
- [Characteristic 3: e.g., "Concern-composed models with rich domain APIs"]

## Layers

[Describe the conceptual layers and their responsibilities]

**Routing:** `config/routes.rb` — Map HTTP requests to controller actions. Resource routes, namespace scoping, constraints, member/collection routes.

**Controllers:** `app/controllers/` — Handle HTTP requests, enforce auth, orchestrate responses. Shared filters, strong params, response rendering.

**Models:** `app/models/` — Domain logic, data persistence, associations, validations, scopes, callbacks. Concern-composed behavior.

**Views:** `app/views/` — Render responses. [ERB/ViewComponents/Turbo Streams], partials, layouts, helpers.

**Services/POROs:** `app/services/` (or `app/models/` subdirectories) — [Service objects, form objects, query objects, presenters — list what's present and where they live]

**Jobs:** `app/jobs/` — Asynchronous and background processing. ActiveJob classes [backed by Solid Queue / Sidekiq / GoodJob].

**Mailers:** `app/mailers/` — Transactional and notification emails via ActionMailer.

## Model Architecture

[How the model layer is designed — this is often where an app's distinctive patterns live]

**Design Philosophy:** [e.g., "Thin controllers, rich models — business logic lives in models and model concerns, not in controllers or service objects"]

**Concern Architecture:**
- **Shared concerns** (`app/models/concerns/`): [List key shared concerns and naming convention, e.g., "Adjective names — `Eventable`, `Searchable`, `Notifiable`"]
- **Model-specific concerns** ([e.g., `app/models/card/`, `app/models/board/`]): [List directories and naming convention, e.g., "Namespaced — `Card::Closeable`, `Board::Accessible`"]
- **Composition pattern**: [How are concerns combined? e.g., "Models include 10-20 concerns via `include` — each adds a distinct capability"]
- **Layering/Template method**: [Do concerns override each other? e.g., "Base `Eventable` provides `track_event` with override points; `Card::Eventable` customizes behavior via `should_track_event?` and `event_was_created`"]

**Association Defaults:**
- [e.g., "Lambda defaults on `belongs_to` propagate context: `belongs_to :account, default: -> { board.account }`"]
- [e.g., "Creator tracking via `belongs_to :creator, default: -> { Current.user }`"]

**Key Domain Models:**
- [Model 1: role and key relationships]
- [Model 2: role and key relationships]
- [Model 3: role and key relationships]

**Scoping Patterns:** [How are scopes named? e.g., "Business names not SQL names — `closed` not `with_closures`, `open` not `without_closures`. Composable: `Card.open.golden.latest`"]

**Callback Philosophy:** [e.g., "Minimal callbacks — `before_create` for required data, `after_create_commit` for async jobs, `after_save` for cache invalidation. Business logic uses explicit methods, not callbacks"]

## Controller Patterns

[How controllers are structured beyond basic MVC]

**Philosophy:** [e.g., "Thin controllers — setup, call one model method, respond. No business logic in controllers"]

**Resource Nesting:** [e.g., "Actions modeled as sub-resources: `resource :closure` (create=close, destroy=reopen) instead of `post :close`"]

**Controller Concerns:** [e.g., "`CardScoped` sets `@card` and `@board` via before_action — shared across all nested card controllers. `BoardScoped` handles board loading and permission checks. `FilterScoped` instantiates presenter objects"]

**Response Formats:** [e.g., "Multi-format via `respond_to` — Turbo Stream for live updates, HTML for full pages, JSON for API"]

## Data Flow

[Describe the typical request/execution lifecycle]

**HTTP Request (standard Rails cycle):**

1. Request hits `config/routes.rb`, matched to controller#action
2. Rack middleware stack runs (session, cookies, CSRF protection, auth)
3. Controller `before_action` filters execute (authentication, authorization, parameter setup)
4. Controller action runs — calls models/services for business logic
5. Model layer handles data access, validations, associations
6. View renders response (ERB/ViewComponent/Turbo Stream/JSON)
7. Response returned to client

**Turbo/Hotwire Flow (if applicable):**

1. User interaction triggers Turbo Frame or Turbo Stream request
2. Controller responds with `turbo_stream` format or frame-scoped HTML
3. Turbo replaces/appends/removes DOM elements without full page reload

**Background Job Flow:**

1. Controller or model enqueues job via `perform_later`
2. Job backend [Solid Queue/Sidekiq/GoodJob] picks up job
3. Job executes with access to full Rails environment
4. Results persisted to database or notifications sent

**State Management:**
- [How state is handled: e.g., "SQLite via ActiveRecord (Rails default)", "Solid Cache for caching (database-backed)", "Redis for sessions or shared state", "Kredis for structured Redis data"]

## Background Job Patterns

[How background work is organized — thin jobs, naming conventions, tenant context]

**Job Philosophy:** [e.g., "Ultra-thin jobs — 3-6 lines. All logic lives in model methods. Jobs are just async wrappers"]

**_now/_later Pattern:** [e.g., "Every async operation has three parts: (1) synchronous method `notify_recipients`, (2) async wrapper `notify_recipients_later` that enqueues, (3) thin job class that calls the sync method. Testable at model level, callable from console/jobs/controllers"]

**Multi-Tenancy in Jobs:** [e.g., "Tenant context captured automatically on job creation via `Current.account`, serialized into job payload, restored on execution. No manual account passing needed"]

**Queue Organization:** [e.g., "Queues: `default`, `backend` (exports, heavy processing), `webhooks` (external deliveries). Configured in config/queue.yml (Solid Queue) / Sidekiq / GoodJob"]

**Retry Strategy:** [e.g., "`retry_on` for transient failures (network, timeouts), `discard_on` for permanent failures (record not found). Configured per-job"]

## Key Abstractions

[Core concepts/patterns used throughout the codebase]

**ActiveRecord Models:**
- Purpose: Domain entities with persistence, associations, and business rules
- Examples: [e.g., `User`, `Board`, `Card`, `Event`]
- Pattern: Active Record — each model wraps a database table

**Concerns:**
- Purpose: Compose model behavior from focused modules
- **Shared** (`app/models/concerns/`): Cross-cutting behavior for multiple models [e.g., `Eventable`, `Searchable`]
- **Model-specific** ([e.g., `app/models/card/`]): Domain behavior scoped to one model [e.g., `Card::Closeable`, `Card::Postponable`]
- Pattern: `ActiveSupport::Concern` with `included do` block for associations/scopes, instance methods for API, template method pattern for customization points

**Presenters/View Models (if present):**
- Purpose: [e.g., "Plain Ruby classes that package data and display logic for views"]
- Location: [e.g., "`app/models/` subdirectories (not a separate `app/presenters/`)" or "`app/presenters/`"]
- Examples: [e.g., `User::Filtering` (filter UI state), `Event::Description` (event → human-readable text)]
- Pattern: [e.g., "Constructor injection, memoized collections, boolean methods for conditional display, cache keys for fragment caching"]

**Service Objects (if present):**
- Purpose: Encapsulate multi-step operations that don't belong in a single model
- Examples: [e.g., `Projects::Creator`, `Invitations::Acceptor`]
- Pattern: [e.g., "Class with `.call` method returning a result"]

**[Additional Abstraction — e.g., Policies, Form Objects, Query Objects]:**
- Purpose: [What it represents]
- Examples: [Concrete examples]
- Pattern: [Pattern used]

## Multi-Tenancy & Current Context

[How tenant isolation works — omit this section if the app is single-tenant]

**Approach:** [e.g., "Path-based with CurrentAttributes — account ID extracted from URL by middleware, sets `Current.account` for the request"]

**Current Context:** [e.g., "`Current` holds `session`, `user`, `identity`, `account`. Cascade: setting `session` → resolves `identity` → resolves `user` for current account"]

**Scoping:** [e.g., "Lambda defaults on `belongs_to :account` ensure all records created within a request are scoped to the tenant. Queries scope through `Current.user.boards`, `Current.user.accessible_cards`"]

**Async Context:** [e.g., "Jobs automatically capture/restore `Current.account` via ApplicationJob extensions — no manual passing needed"]

## Entry Points

[Where execution begins]

**Web Requests:**
- Location: `config/routes.rb` → `app/controllers/`
- Triggers: HTTP requests from browser or API clients
- Responsibilities: Route matching, middleware execution, controller dispatch

**Background Jobs:**
- Location: `app/jobs/`
- Triggers: Enqueued from application code, scheduled via cron/clockwork
- Responsibilities: Async processing — emails, imports, cleanup, notifications

**Rake Tasks:**
- Location: `lib/tasks/*.rake`
- Triggers: Manual invocation (`rails db:migrate`, custom tasks)
- Responsibilities: Data migrations, maintenance, one-off operations

**Configuration & Boot:**
- Location: `config/application.rb`, `config/environments/`, `config/initializers/`
- Triggers: Application startup
- Responsibilities: Framework configuration, gem initialization, middleware setup

## Error Handling

**Strategy:** [How errors are handled: e.g., "`rescue_from` in ApplicationController", "Custom error pages in `app/views/errors/`", "Exception tracking via Sentry/Honeybadger"]

**Patterns:**
- [Pattern: e.g., "`rescue_from ActiveRecord::RecordNotFound` renders 404"]
- [Pattern: e.g., "Model validation errors re-render form with error messages"]
- [Pattern: e.g., "Service objects return Result/Response objects instead of raising"]
- [Pattern: e.g., "Background jobs use `retry_on` / `discard_on` for failure handling"]

## Cross-Cutting Concerns

[Aspects that affect multiple layers]

**Logging:**
- [Approach: e.g., "`Rails.logger` with tagged logging", "Lograge for structured request logs"]

**Validation:**
- [Approach: e.g., "ActiveModel validations in models", "Strong parameters in controllers", "Form objects for complex input"]

**Authentication:**
- [Approach: e.g., "Rails authentication generator with `Authentication` concern", "has_secure_password with custom auth", "OmniAuth for OAuth"]

**Authorization:**
- [Approach: e.g., "Pundit policies", "CanCanCan abilities", "Custom `before_action` checks"]

**Caching:**
- [Approach: e.g., "Fragment caching in views", "Russian doll caching", "Rails.cache with Solid Cache/Redis"]

---

*Architecture analysis: [date]*
*Update when major patterns change*
```

<good_examples>
```markdown
# Architecture

**Analysis Date:** 2025-01-20

## Pattern Overview

**Overall:** Rails Monolith with Hotwire

**Multi-Tenancy:** Path-based with CurrentAttributes

**Key Characteristics:**
- Server-rendered HTML with Turbo for SPA-like interactions
- RESTful resource routing with actions modeled as sub-resources
- Concern-composed models with rich domain APIs
- Thin controllers, thin jobs — business logic lives in models

## Layers

**Routing:** `config/routes.rb` — RESTful resource routes with nested singular resources for state changes (`resource :closure`, `resource :goldness`). Namespace scoping for admin. Constraints for account slug extraction.

**Controllers:** `app/controllers/` — Thin controllers using shared concerns (`CardScoped`, `BoardScoped`, `FilterScoped`). `before_action` for auth and resource loading. Multi-format responses (Turbo Stream, HTML, JSON).

**Models:** `app/models/` — Rich domain models composed of 10-20 concerns each. Business logic, associations, scopes, validations. Model-specific concerns in subdirectories (`app/models/card/`, `app/models/board/`).

**Views:** `app/views/` — ERB templates with Turbo Frame tags and Turbo Stream actions. Partials for reusable components. Layouts with Stimulus controller integration (`app/javascript/controllers/`).

**Presenters:** `app/models/` subdirectories — Plain Ruby classes for complex view logic (`User::Filtering`, `Event::Description`, `User::DayTimeline`). No separate `app/presenters/` directory.

**Jobs:** `app/jobs/` — Ultra-thin ActiveJob classes backed by Solid Queue. 3-6 lines each — delegate to model methods via `_now/_later` pattern.

**Mailers:** `app/mailers/` — ActionMailer classes for invitations, notifications, digests.

## Model Architecture

**Design Philosophy:** Thin controllers, rich models. All business logic lives in models and model concerns. Controllers do setup → call one model method → respond. Service objects are rare — behavior composes via concerns.

**Concern Architecture:**
- **Shared concerns** (`app/models/concerns/`): Adjective names for cross-cutting behavior — `Eventable` (audit trail), `Notifiable` (notifications), `Searchable` (full-text search), `Attachments` (file uploads), `Mentions` (@-mentions), `Storage::Tracked` (storage accounting)
- **Model-specific concerns** (`app/models/card/`, `app/models/board/`): Namespaced names for domain behavior — `Card::Closeable` (close/reopen), `Card::Golden` (mark as important), `Card::Postponable` (defer to "not now"), `Card::Entropic` (auto-decay stale cards), `Board::Accessible` (access control)
- **Composition pattern**: Card model includes 20+ concerns via `include Assignable, Closeable, Eventable, Golden, Postponable, ...`. Each adds associations, scopes, and instance methods
- **Layering/Template method**: Base `Eventable` provides `track_event` with override points (`should_track_event?`, `event_was_created`, `eventable_prefix`). `Card::Eventable` includes `::Eventable` and overrides: only tracks events for published cards, creates system comments on event creation

**Association Defaults:**
- Multi-tenancy: `belongs_to :account, default: -> { board.account }` — account derived from parent
- Creator tracking: `belongs_to :creator, class_name: "User", default: -> { Current.user }`
- Declaration order matters: declare `belongs_to :board` before using `board` in a default lambda

**Key Domain Models:**
- `Account` — Tenant root. All data scoped to an account
- `Board` — Project workspace containing cards, columns, and access rules
- `Card` — Primary work item. Most concern-composed model (20+ concerns).
- `Event` — Audit trail record. Polymorphic `eventable`, JSON `particulars` for action-specific data
- `User` — Account member with role-based permissions. Resolved from `Current.session` → `identity` → `user`

**Scoping Patterns:** Business names, not SQL names. `closed` (not `with_closures`), `open` (not `without_closures`), `golden`, `postponed`. Composable: `Card.open.golden.latest`. Conditional UI scopes: `indexed_by("stalled")`, `sorted_by("newest")`. Preloading scopes: `Card.preloaded` eager-loads all associations.

**Callback Philosophy:** Minimal. `before_create` for required data (sequential numbers). `after_create_commit` for async jobs (notifications, storage tracking). `after_save` with lambda for simple one-liners (`-> { board.touch }`). Conditional via `if: :saved_change_to_board_id?`. Business logic uses explicit methods (`close`, `gild`), not callbacks.

## Controller Patterns

**Philosophy:** Thin controllers — setup, call one model method, respond. A typical action is 3-5 lines. `Cards::GoldnessesController#create` is just `@card.gild` + respond.

**Resource Nesting:** Actions modeled as singular sub-resources under the parent. `resource :closure` (create=close, destroy=reopen), `resource :goldness` (create=gild, destroy=ungild), `resource :pin`, `resource :watch`. Scoped via `scope module: :cards`. Standard CRUD verbs, no custom actions.

**Controller Concerns:** `CardScoped` — sets `@card` (found by number) and `@board` via before_action, provides `render_card_replacement` for Turbo Stream responses. Used by all nested card controllers. `BoardScoped` — sets `@board`, provides permission checks. `FilterScoped` — instantiates `User::Filtering` presenter.

**Response Formats:** `respond_to` blocks with Turbo Stream (partial replacement via morph), HTML (full page), JSON (`head :no_content` for API). Turbo Stream responses use `turbo_stream.replace` with morphing.

## Data Flow

**HTTP Request (standard Rails cycle):**

1. Request hits `config/routes.rb`, account slug extracted by middleware → `Current.account`
2. Rack middleware runs (session, CSRF, auth)
3. `before_action :authenticate_user!` verifies session → `Current.session` → cascade to `Current.user`
4. Controller concern sets resource (`CardScoped` loads `@card` by number)
5. Action calls single model method (`@card.close`)
6. Model method runs in transaction — state change + event tracking
7. Turbo Stream response replaces partial in-place

**Turbo Stream Flow (card state change):**

1. User clicks action button (Turbo-enabled form)
2. POST/DELETE to nested resource (e.g., `POST /cards/123/closure`)
3. Controller calls model method, responds with `turbo_stream.replace`
4. Turbo morphs DOM element — no full page reload

**Background Job Flow (notifications):**

1. Record created → `after_create_commit :notify_recipients_later`
2. `_later` method enqueues `NotifyRecipientsJob` (account captured automatically)
3. Solid Queue picks up job, restores `Current.account`
4. Job calls `record.notify_recipients` (synchronous model method)
5. Model method handles all logic — notification creation, delivery

**State Management:**
- SQLite for all persistent data via ActiveRecord (upgrade to PostgreSQL for high-concurrency production)
- Solid Cache (database-backed) for fragment caching and Rails.cache
- Turbo maintains UI state client-side (no server-side view state)

## Background Job Patterns

**Job Philosophy:** Ultra-thin jobs — 3-6 lines. All logic in model methods. Jobs are async wrappers, nothing more.

**_now/_later Pattern:** Every async operation has three parts: (1) synchronous method on model (`notify_recipients`), (2) `_later` wrapper that enqueues (`notify_recipients_later`), (3) thin job class that calls the sync method (`NotifyRecipientsJob#perform → notifiable.notify_recipients`). Logic tested via synchronous method. Callable from console, jobs, controllers.

**Multi-Tenancy in Jobs:** `ApplicationJob` extensions automatically capture `Current.account` on job creation, serialize it into the job payload via GlobalID, and restore it with `Current.with_account` on execution. No manual account passing. Queries in jobs "just work."

**Queue Organization:** `default` (general), `backend` (exports, heavy processing), `webhooks` (external deliveries). Configured via `queue_as :backend`.

**Retry Strategy:** `retry_on` for transient failures (network, timeouts). `discard_on ActiveRecord::RecordNotFound` for permanent failures. Configured per-job.

## Key Abstractions

**ActiveRecord Models:**
- Purpose: Domain entities with persistence, associations, and business rules
- Examples: `Account`, `Board`, `Card`, `Event`, `User`, `Closure`, `Goldness`
- Pattern: Active Record — each model wraps a database table. State-change models (`Closure`, `Goldness`) represent boolean states as presence/absence of a record

**Concerns:**
- Purpose: Compose model behavior from focused, testable modules
- **Shared** (`app/models/concerns/`): `Eventable`, `Notifiable`, `Searchable`, `Attachments`, `Mentions`, `Storage::Tracked`
- **Model-specific** (`app/models/card/`, `app/models/board/`): `Card::Closeable`, `Card::Golden`, `Card::Postponable`, `Card::Entropic`, `Board::Accessible`
- Pattern: `ActiveSupport::Concern` — `included do` block for associations/scopes/callbacks, public instance methods for API, template method pattern for customization points. Concerns can layer: `Card::Eventable` includes `::Eventable` and overrides hooks

**Presenters:**
- Purpose: Plain Ruby classes that package data and display logic for views
- Location: `app/models/` subdirectories — `User::Filtering`, `Event::Description`, `User::DayTimeline`
- Pattern: Constructor injection, memoized collections (`@boards ||= ...`), boolean methods for conditional display (`show_tags?`), cache keys for fragment caching. Some include `ActionView::Helpers::TagHelper` for HTML generation. Instantiated via controller concerns or factory methods on models (`event.description_for(user)`)

## Multi-Tenancy & Current Context

**Approach:** Path-based — account slug extracted from URL path by `AccountSlug::Extractor` middleware. Slug moves from `PATH_INFO` to `SCRIPT_NAME`. No subdomain configuration needed.

**Current Context:** `Current` (ActiveSupport::CurrentAttributes) holds `session`, `user`, `identity`, `account`, plus request metadata. Cascade: setting `Current.session` → extracts `identity` → finds `user` for current `account`. In tests: `Current.session = sessions(:david)` sets everything.

**Scoping:** Lambda defaults on `belongs_to :account, default: -> { board.account }` ensure all records are tenant-scoped at creation. Queries scope through user: `Current.user.boards`, `Current.user.accessible_cards.find_by!(number: params[:id])`.

**Async Context:** `ApplicationJob` extensions capture `Current.account` on creation, serialize via GlobalID, restore with `Current.with_account(account)` on execution. Transparent to job authors.

## Entry Points

**Web Requests:**
- Location: `config/routes.rb` → `app/controllers/`
- Triggers: Browser requests, Turbo navigations, API calls
- Responsibilities: Auth, routing, rendering

**Background Jobs:**
- Location: `app/jobs/`
- Triggers: `perform_later` from app code, recurring tasks via Solid Queue's config/recurring.yml
- Responsibilities: Emails, imports, cleanup, notifications

**Rake Tasks:**
- Location: `lib/tasks/`
- Triggers: Manual or cron (`rails projects:archive_stale`, `rails data:backfill_slugs`)
- Responsibilities: Data migrations, maintenance

**Configuration & Boot:**
- Location: `config/application.rb`, `config/initializers/`
- Triggers: Server start, console, job worker boot
- Responsibilities: Gem config, middleware, service connections

## Error Handling

**Strategy:** `rescue_from` in `ApplicationController`, custom error pages, Sentry for tracking

**Patterns:**
- `rescue_from ActiveRecord::RecordNotFound` → 404 page
- `rescue_from NotAuthorizedError` → 403 or redirect with flash
- Model validation errors re-render form with `@model.errors`
- Service objects return `Result` structs (success/failure) instead of raising
- Jobs use `retry_on` for transient failures, `discard_on` for permanent ones

## Cross-Cutting Concerns

**Logging:**
- `Rails.logger` with tagged logging (request ID, user ID)
- Lograge for single-line structured request logs

**Validation:**
- ActiveModel validations in models (presence, uniqueness, format)
- Strong parameters in controllers
- Custom validators in `app/validators/`

**Authentication:**
- Rails authentication generator with `Authentication` concern and database-tracked sessions
- `require_authentication` filter on all non-public controllers

**Authorization:**
- `authorize` calls in controller actions
- Scoped queries via `policy_scope`

**Caching:**
- Fragment caching on project dashboard partials
- Russian doll caching for nested task lists
- `Rails.cache` backed by Solid Cache for expensive queries

---

*Architecture analysis: 2025-01-20*
*Update when major patterns change*
```
</good_examples>

<guidelines>
**What belongs in ARCHITECTURE.md:**
- Overall Rails pattern (monolith, API-only, engine-based, modular monolith)
- Multi-tenancy approach (if any) and Current context setup
- Model design philosophy — where business logic lives (thin controller/rich model vs service-heavy)
- Concern architecture — shared vs model-specific, naming conventions, composition depth, template method pattern
- Controller patterns — resource nesting, controller concerns, response formats
- Association defaults and context propagation (lambda defaults)
- Background job patterns — _now/_later convention, thin jobs, tenant context in async
- Data flow including Turbo/Hotwire and background job lifecycle
- Presenter/view model patterns (if present) — where they live, how they're instantiated
- Entry points, error handling, and cross-cutting concerns

**What does NOT belong here:**
- Exhaustive file listings (that's STRUCTURE.md)
- Technology choices and gem versions (that's STACK.md)
- Line-by-line code walkthrough (defer to code reading)
- Database schema details (defer to `db/schema.rb`)
- Individual route listings (defer to `config/routes.rb`)

**File paths ARE welcome:**
Include file paths as concrete examples of abstractions. Use backtick formatting: `app/models/card/closeable.rb`. This makes the architecture document actionable for Claude when planning.

**When filling this template:**
- Read `config/routes.rb` to understand resource structure, nesting, and whether actions use sub-resources or custom routes
- Check `app/models/concerns/` for shared concerns — note naming conventions and how many exist
- Check for model-specific concern directories (`app/models/card/`, `app/models/board/`) — these reveal concern composition depth
- Read 2-3 model files to understand concern composition — count how many concerns a core model includes
- Read a model-specific concern to understand anatomy: `included do` block, public API, override points
- Read `app/controllers/application_controller.rb` and controller concerns (`app/controllers/concerns/`) for shared patterns
- Read a nested controller (e.g., `cards/closures_controller.rb`) to identify resource nesting vs custom actions
- Check if `Current` model exists (`app/models/current.rb`) and what attributes it holds
- Look for lambda defaults on `belongs_to` associations — these reveal context propagation patterns
- Read a job file to identify thin-job vs logic-in-job pattern, and check for `_now/_later` naming
- Check `config/initializers/` for ActiveJob extensions that capture tenant context
- Look for presenter/PORO classes in `app/models/` subdirectories or `app/presenters/`
- Trace a full request: route → controller concern → controller action → model method → view
- Keep descriptions conceptual, not mechanical

**Useful for phase planning when:**
- Adding new features (which layer handles it? controller + model concern + view + job?)
- Adding a new model capability (follow the concern pattern — concern + scopes + API methods + event tracking)
- Adding a new action (model it as a sub-resource? create concern + controller + route)
- Refactoring fat models or controllers (extract to concern? follow existing naming conventions)
- Understanding how multi-tenancy propagates through the stack (Current → lambda defaults → job serialization)
- Adding background processing (follow _now/_later pattern, tenant context is automatic)
- Debugging request flow (what middleware and filters run? what does Current hold?)
</guidelines>
