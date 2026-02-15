# Architecture Research Template

Template for `.planning/research/ARCHITECTURE.md` — Rails application architecture discovery for the project.

<template>

```markdown
# Architecture Research

**Application:** [app name]
**Rails Version:** [version]
**Ruby Version:** [version]
**Researched:** [date]
**Confidence:** [HIGH/MEDIUM/LOW]

## Application Overview

### MVC + Domain Model Structure

```
┌─────────────────────────────────────────────────────────────┐
│                      Request Layer                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Routes   │  │Middleware │  │ Rack App │  │ Channels │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘   │
│       │              │             │              │         │
├───────┴──────────────┴─────────────┴──────────────┴─────────┤
│                     Controller Layer                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │Controllers│  │ Concerns │  │ Filters  │  │ Params   │   │
│  └────┬─────┘  └──────────┘  └──────────┘  └──────────┘   │
│       │                                                     │
├───────┴─────────────────────────────────────────────────────┤
│                      Domain Layer                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Models   │  │ Concerns │  │ Callbacks│  │ Validators│  │
│  └────┬─────┘  └──────────┘  └──────────┘  └──────────┘   │
│       │                                                     │
├───────┴─────────────────────────────────────────────────────┤
│                    Presentation Layer                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Views   │  │ Partials │  │  Helpers │  │Components │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
├─────────────────────────────────────────────────────────────┤
│                    Background Layer                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │   Jobs   │  │ Mailers  │  │ Channels │                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

| Layer | Responsibility | Discovered Implementation |
|-------|----------------|---------------------------|
| Routes | [URL mapping, constraints, namespacing] | [what this project does] |
| Controllers | [request handling, params, response] | [what this project does] |
| Models | [domain logic, validations, associations] | [what this project does] |
| Views | [presentation, templates, components] | [what this project does] |
| Jobs | [background processing] | [what this project does] |
| Mailers | [email delivery] | [what this project does] |
| Channels | [WebSocket/real-time] | [what this project does] |

## Project Structure

```
app/
├── models/                # Domain models and business logic
│   └── concerns/          # [shared model concerns discovered]
├── controllers/           # Request handling
│   └── concerns/          # [shared controller concerns discovered]
├── views/                 # Templates and partials
│   ├── layouts/           # [layout structure discovered]
│   └── shared/            # [shared partials discovered]
├── helpers/               # [view helper organization discovered]
├── jobs/                  # [background job organization discovered]
├── mailers/               # [mailer organization discovered]
├── channels/              # [Action Cable channels discovered]
├── components/            # [ViewComponent usage if present]
├── javascript/            # [JS approach: importmaps/jsbundling/etc.]
├── assets/                # [asset pipeline approach discovered]
│   └── stylesheets/       # [CSS approach: custom CSS/Tailwind/cssbundling]
config/
├── routes.rb              # [routing organization discovered]
├── initializers/          # [key initializers discovered]
├── environments/          # [environment-specific config]
├── locales/               # [I18n usage discovered]
db/
├── migrate/               # [migration conventions discovered]
├── schema.rb              # [schema state]
├── seeds.rb               # [seeding approach discovered]
lib/
├── tasks/                 # [rake task organization discovered]
├── [custom modules]/      # [lib/ usage discovered]
test/                      # [test framework: Minitest (default) or spec/ if RSpec]
├── models/                # [model test patterns discovered]
├── controllers/           # [controller test patterns discovered]
├── system/                # [system test approach discovered]
├── fixtures/ or factories/# [test data approach discovered]
```

### Structure Notes

- **Namespacing:** [how app/ subdirectories are namespaced, if at all]
- **Engines:** [any Rails engines mounted or extracted]
- **lib/ usage:** [what lives in lib/ vs app/]
- **Autoload paths:** [any custom autoload paths configured]

## Architectural Patterns Discovered

### Domain Logic Placement

**Observed approach:** [rich models / service objects / interactors / form objects / other]
**Where business logic lives:** [description of what was found]

**Example from codebase:**
```ruby
# [Brief code example showing the project's actual pattern]
```

### Concern Organization

**Observed approach:** [how concerns are organized]
**Shared concerns:** [concerns used across multiple models/controllers]
**Model-specific concerns:** [concerns scoped to single models]

**Example from codebase:**
```ruby
# [Brief code example showing concern usage]
```

### Multi-Tenancy (if applicable)

**Approach:** [URL path-based / subdomain / database-level / schema-level / none]
**Scoping mechanism:** [how tenant scoping is applied — default_scope, Current attributes, controller filter, etc.]

**Example from codebase:**
```ruby
# [Brief code example showing tenant scoping]
```

### Inheritance and Polymorphism

**STI usage:** [where Single Table Inheritance is used, if at all]
**Polymorphic associations:** [where polymorphic belongs_to is used]
**Delegated types:** [where delegated_type is used, if at all]

### Current Attributes

**Usage:** [how Current attributes are set and used, if at all]
**Attributes tracked:** [user, account, request_id, etc.]

**Example from codebase:**
```ruby
# [Brief code example showing Current usage]
```

### Callback Conventions

**Observed approach:** [heavy callback usage / minimal / specific patterns]
**Common callbacks:** [which lifecycle hooks are used and for what]
**Avoidance patterns:** [any evidence of avoiding callbacks in favor of other approaches]

### Authentication and Authorization

**Authentication:** [Rails authentication generator / has_secure_password / custom / other]
**Authorization:** [Custom / Pundit / CanCanCan / Action Policy / other]

## Data Flow

### Standard Request Cycle

```
Browser Request
    ↓
Router (config/routes.rb) → [routing patterns: resources, nested, concerns]
    ↓
Controller#action → [before_action filters, params handling]
    ↓
Model (ActiveRecord) → [validations, callbacks, scopes, queries]
    ↓
View (ERB/Haml/Slim) → [template rendering, partials, helpers]
    ↓
Response (HTML/JSON/Turbo Stream)
```

### Turbo / Hotwire Flow (if applicable)

```
Turbo Frame Request
    ↓
Controller#action → [responds_to format]
    ↓
turbo_stream.update/replace/append
    ↓
Partial render → DOM update (no full page reload)
```

### Action Cable Flow (if applicable)

```
WebSocket Connection
    ↓
Channel#subscribed → [stream_for / stream_from]
    ↓
Model change → [broadcast_to / Turbo::StreamsChannel]
    ↓
Client receives → DOM update
```

### Key Data Flows

1. **[Flow name]:** [description of how data moves through the app]
2. **[Flow name]:** [description of how data moves through the app]

## State and Context Management

### Server-Side State

| Mechanism | Usage Discovered |
|-----------|------------------|
| Session | [what is stored in session, session store backend] |
| Current attributes | [what context is threaded via Current] |
| Flash messages | [how flash is used for notifications] |
| Instance variables | [controller → view data passing patterns] |
| Caching | [what is cached and where — fragment, low-level, etc.] |

### Client-Side State

| Mechanism | Usage Discovered |
|-----------|------------------|
| Turbo Frames | [how Turbo Frames scope page updates] |
| Stimulus controllers | [how Stimulus manages UI state] |
| Data attributes | [how data-* attributes pass server state to JS] |
| Local storage / cookies | [any direct browser storage usage] |

## Scaling Considerations

| Area | Current Approach | Scaling Path |
|------|------------------|--------------|
| Database queries | [indexes, eager loading, query optimization discovered] | [read replicas, sharding, etc.] |
| Caching | [fragment / Russian doll / low-level / HTTP caching discovered] | [Solid Cache, Redis, CDN, cache layers] |
| Background jobs | [job queue backend, job patterns discovered] | [worker scaling, queue prioritization] |
| Connection pooling | [database pool size, Puma threads discovered] | [PgBouncer for PostgreSQL, or SQLite WAL mode for better concurrent reads] |
| Asset delivery | [CDN, asset pipeline, fingerprinting discovered] | [edge caching, compression] |

### Database Optimization Patterns

- **Counter caches:** [where used, if at all]
- **Database indexes:** [indexing strategy discovered]
- **Eager loading:** [includes/preload/eager_load patterns]
- **Query objects or scopes:** [how complex queries are organized]
- **Batch processing:** [find_each, in_batches usage]

### Caching Strategy

- **Fragment caching:** [where and how fragment caching is used]
- **Russian doll caching:** [nested cache keys with touch: true]
- **Low-level caching:** [Rails.cache.fetch usage]
- **HTTP caching:** [stale?, fresh_when, ETags]
- **Cache store:** [Solid Cache, Redis, Memcached, file store, etc.]

## Anti-Patterns to Watch For

### Anti-Pattern 1: Fat Controllers

**What it looks like:** [business logic in controller actions]
**Why it is a problem:** [hard to test, violates SRP, logic not reusable]
**This project's approach:** [what was discovered about controller size]

### Anti-Pattern 2: N+1 Queries

**What it looks like:** [loading associations in loops without eager loading]
**Why it is a problem:** [performance degrades linearly with record count]
**This project's approach:** [bullet gem, strict_loading, eager loading conventions]

### Anti-Pattern 3: Callback Complexity

**What it looks like:** [long callback chains, callbacks with side effects]
**Why it is a problem:** [hard to reason about, implicit execution order, test difficulty]
**This project's approach:** [what was discovered about callback usage]

### Anti-Pattern 4: God Models

**What it looks like:** [models with hundreds of methods, too many concerns]
**Why it is a problem:** [hard to maintain, test, and understand]
**This project's approach:** [how large models are structured — concerns, delegation, etc.]

### Anti-Pattern 5: Skipping Migrations

**What it looks like:** [manual DB changes, schema.rb conflicts, missing migrations]
**Why it is a problem:** [irreproducible environments, deployment failures]
**This project's approach:** [migration conventions discovered]

## Integration Points

### Rails Framework Integrations

| Integration | Usage Discovered | Notes |
|-------------|------------------|-------|
| Active Storage | [file upload handling] | [service backend: local/S3/GCS/etc.] |
| Action Mailer | [email sending patterns] | [delivery method, previews] |
| Action Cable | [real-time features] | [adapter: Solid Cable (default)/Redis/PostgreSQL/async] |
| Action Text | [rich text editing] | [if Trix editor is used] |
| Active Job | [background job framework] | [queue backend: Solid Queue/Sidekiq/GoodJob/etc.] |

### External Service Integrations

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| [service] | [HTTP client, gem, API wrapper] | [error handling, retries, timeouts] |
| [service] | [HTTP client, gem, API wrapper] | [error handling, retries, timeouts] |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| [Engine / module A ↔ module B] | [API / events / direct calls] | [coupling considerations] |

## Sources

- [Architecture references discovered in codebase]
- [Rails guides or documentation relevant to patterns used]
- [Gems or libraries that shape the architecture]

---
*Architecture research for: [app name]*
*Rails: [version] / Ruby: [version]*
*Researched: [date]*
```

</template>

<guidelines>

**Application Overview:**
- Use ASCII box-drawing diagrams to show Rails layers and their relationships
- Discover which layers the project actively uses — not every app uses Channels or Components
- Map the actual MVC responsibilities as implemented, not the textbook version

**Project Structure:**
- Start with standard Rails conventions, then note deviations
- Pay attention to how `app/models/concerns/` vs `app/controllers/concerns/` are organized
- Check for engines, custom autoload paths, and non-standard directories under `app/`
- Note the JavaScript approach (importmaps, jsbundling-rails, webpacker legacy, etc.)

**Architectural Patterns:**
- Discover, do not prescribe — the project may use service objects, interactors, or keep logic in models
- Check for Current attributes usage in `app/models/current.rb`
- Look at concern files to understand how shared behavior is organized
- Note multi-tenancy patterns if the app serves multiple accounts/organizations
- Check for STI (type column), polymorphic associations, and delegated types

**Data Flow:**
- Trace the full request cycle including middleware and before_action filters
- Document Turbo/Hotwire patterns if present — frame requests, stream broadcasts
- Note Action Cable usage and how real-time updates flow

**State and Context:**
- Focus on server-side state mechanisms: session, Current, flash, caching
- For client-side, focus on Stimulus controllers and Turbo Frames, not SPA state stores
- Note the session store backend (cookie, Redis, ActiveRecord, etc.)

**Scaling:**
- Focus on Rails-specific bottlenecks: N+1 queries, missing indexes, cache misses
- Document the caching strategy at each level (HTTP, fragment, low-level)
- Note background job infrastructure and queue backend
- Check connection pool configuration relative to Puma thread count

**Anti-Patterns:**
- Focus on Rails-specific anti-patterns discovered in the codebase
- Fat controllers, N+1 queries, callback complexity, god models, migration issues
- Note what protective measures exist (bullet gem, strict_loading, rubocop-rails, etc.)

**Integration Points:**
- Document which Rails framework integrations are active (Active Storage, Action Cable, etc.)
- Note external API integration patterns and HTTP client choices
- Look for engine boundaries and module interfaces

</guidelines>
