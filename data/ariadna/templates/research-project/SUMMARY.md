# Research Summary Template

Template for `.planning/research/SUMMARY.md` — executive summary of project research with roadmap implications for Ruby on Rails applications.

<template>

```markdown
# Project Research Summary

**Project:** [name from PROJECT.md]
**Domain:** [inferred domain type] — Ruby on Rails application
**Researched:** [date]
**Confidence:** [HIGH/MEDIUM/LOW]

## Executive Summary

[2-3 paragraph overview of research findings]

- What type of Rails application this is and how experienced Rails teams build it
- The recommended approach based on research (conventions, gems, architectural patterns)
- Key risks specific to this kind of Rails project and how to mitigate them

## Key Findings

### Recommended Stack

[Summary from STACK.md — 1-2 paragraphs on why this combination of Rails technologies fits the project]

**Ruby & Rails version:**
- [Ruby version]: [why this version — e.g., YJIT support, performance, compatibility]
- [Rails version]: [why this version — e.g., latest stable, Solid Queue/Cache built-in, Turbo maturity]

**Database:**
- [Database]: [purpose] — [why recommended — e.g., PostgreSQL for full-text search, jsonb, advisory locks]

**Background jobs:**
- [Job backend]: [purpose] — [why recommended — e.g., Solid Queue for simplicity, Sidekiq for throughput]

**Caching & key-value:**
- [Cache backend]: [purpose] — [why recommended — e.g., Solid Cache for DB-backed, Redis for shared state]

**Real-time:**
- [Approach]: [purpose] — [why recommended — e.g., Turbo Streams over WebSocket, Action Cable for custom channels]

**Frontend approach:**
- [Frontend stack]: [purpose] — [why recommended — e.g., Hotwire/Turbo + Stimulus for server-rendered, React/Inertia for SPA-like]
- [CSS framework]: [purpose] — [why recommended — e.g., Tailwind CSS, Bootstrap]
- [Asset pipeline]: [purpose] — [why recommended — e.g., Propshaft + importmap, esbuild for bundling]

**Testing framework:**
- [Test framework]: [purpose] — [why recommended — e.g., Minitest for convention, RSpec for expressiveness]
- [Additional test tools]: [purpose] — [e.g., Capybara for system tests, FactoryBot for fixtures]

**Authentication & authorization:**
- [Auth solution]: [purpose] — [why recommended — e.g., Rails built-in authentication generator, Devise for full-featured]
- [Authorization]: [purpose] — [why recommended — e.g., Pundit for policies, Action Policy for scalable rules]

**Additional gems:**
- [Gem]: [purpose] — [why recommended]
- [Gem]: [purpose] — [why recommended]

### Expected Features

[Summary from FEATURES.md]

**Must have (table stakes):**
- [Feature] — users expect this
- [Feature] — users expect this

**Should have (competitive):**
- [Feature] — differentiator
- [Feature] — differentiator

**Defer (v2+):**
- [Feature] — not essential for launch

### Architecture Approach

[Summary from ARCHITECTURE.md — 1 paragraph covering the Rails MVC structure, domain model organization, and any patterns beyond vanilla Rails]

**Application structure:**
1. [Models & domain layer] — [approach — e.g., core models, concerns for shared behavior, STI vs. polymorphism decisions, value objects]
2. [Controllers & routing] — [approach — e.g., RESTful resources, namespace organization, API vs. HTML responses]
3. [Views & UI layer] — [approach — e.g., partials, ViewComponents, Turbo Frames for partial page updates]
4. [Service layer] — [approach — e.g., service objects/interactors for complex operations, form objects for multi-model forms]
5. [Background layer] — [approach — e.g., Active Job with queue backend, mailers, recurring tasks]
6. [Data access patterns] — [approach — e.g., scopes, query objects, eager loading strategy]

**Multi-tenancy approach (if applicable):**
- [Strategy] — [e.g., acts_as_tenant scoping, PostgreSQL schemas, separate databases]

**Engine extraction (if applicable):**
- [Engine/mountable concern] — [e.g., admin engine, API engine, shared authentication engine]

### Critical Pitfalls

[Top 5-7 from PITFALLS.md — Rails-specific risks identified through research]

1. **[N+1 query risk]** — [where it applies and how to avoid — e.g., strict_loading, bullet gem, includes/preload strategy]
2. **[Migration safety]** — [how to avoid — e.g., strong_migrations gem, zero-downtime deployment considerations, backfill strategies]
3. **[Callback complexity]** — [how to avoid — e.g., limit callback chains, prefer explicit service objects for side effects]
4. **[Fat model/controller risk]** — [how to avoid — e.g., extract concerns, service objects, form objects early]
5. **[Turbo/Hotwire integration pitfall]** — [how to avoid — e.g., Turbo Frame vs. Stream decisions, morphing gotchas, progressive enhancement]
6. **[Asset pipeline / frontend build issue]** — [how to avoid — e.g., importmap limitations, JavaScript bundler configuration]
7. **[Testing bottleneck]** — [how to avoid — e.g., slow system tests, fixture vs. factory strategy, parallel test execution]

## Implications for Roadmap

Based on research, suggested phase structure for this Rails application:

### Phase 1: Foundation — Data Model, Authentication & Core Models
**Rationale:** [why this comes first — e.g., Rails apps are built on a solid data model; authentication gates all other features; core models define the domain language]
**Delivers:** [what this phase produces — e.g., migrations, core models with validations and associations, authentication flow, basic authorization, seed data, model-level tests]
**Addresses:** [features from FEATURES.md — e.g., user registration, core domain entities]
**Avoids:** [pitfall from PITFALLS.md — e.g., migration rework by designing schema upfront, N+1 prevention with eager loading strategy from day one]
**Stack elements:** [from STACK.md — e.g., Rails generators, PostgreSQL, chosen auth gem, model concerns]

### Phase 2: Core Features — Controllers, Views & Turbo Interactions
**Rationale:** [why this order — e.g., with models stable, build the user-facing CRUD and interactions; Turbo Frames/Streams add interactivity without JavaScript complexity]
**Delivers:** [what this phase produces — e.g., RESTful controllers, views with partials/components, Turbo Frame navigation, form handling, flash messages, system tests]
**Addresses:** [features from FEATURES.md — e.g., primary user workflows, admin interface]
**Uses:** [stack elements from STACK.md — e.g., Hotwire/Turbo, Stimulus, CSS framework, ViewComponents]
**Implements:** [architecture component — e.g., controller layer, view layer, service objects for complex actions]

### Phase 3: Background Processing — Jobs, Mailers & Scheduled Tasks
**Rationale:** [why this order — e.g., core features surface the need for async work; emails, notifications, data processing should not block web requests]
**Delivers:** [what this phase produces — e.g., Active Job classes, mailer templates, recurring job schedule, webhook processing, error handling/retry strategy]
**Addresses:** [features from FEATURES.md — e.g., email notifications, data imports/exports, scheduled reports]
**Uses:** [stack elements from STACK.md — e.g., Solid Queue/Sidekiq, Action Mailer, Active Storage for file processing]
**Avoids:** [pitfall from PITFALLS.md — e.g., long-running requests, timeout issues, job idempotency problems]

### Phase 4: Polish — Caching, Performance, Search & Real-Time
**Rationale:** [why this order — e.g., optimize after features are stable; caching and real-time add complexity best deferred until core is solid]
**Delivers:** [what this phase produces — e.g., fragment caching, Russian doll caching, counter caches, database indexes, full-text search, Action Cable channels, Turbo Stream broadcasts, performance monitoring]
**Addresses:** [features from FEATURES.md — e.g., search, live updates, dashboard performance]
**Uses:** [stack elements from STACK.md — e.g., Solid Cache/Redis, pg_search/Meilisearch, Action Cable]
**Avoids:** [pitfall from PITFALLS.md — e.g., premature optimization, cache invalidation bugs, N+1 regressions under load]

[Continue for additional phases if needed...]

### Phase Ordering Rationale

- [Why data model and auth come first — e.g., Rails convention-over-configuration rewards upfront schema design; all features depend on authentication]
- [Why controllers/views before background jobs — e.g., user-facing flows reveal the async work needed; avoids building jobs for features that change]
- [Why caching and real-time are last — e.g., caching strategies depend on stable views and queries; premature caching causes invalidation bugs]
- [How this avoids pitfalls from research — e.g., early attention to eager loading prevents N+1 debt; strong_migrations from phase 1 prevents deployment issues]

### Research Flags

Phases likely needing deeper research during planning:
- **Phase [X]:** [reason — e.g., "multi-tenancy approach needs benchmarking against data volume projections"]
- **Phase [Y]:** [reason — e.g., "Turbo Stream vs. Action Cable decision depends on real-time requirements complexity"]
- **Phase [Z]:** [reason — e.g., "search gem selection depends on hosting constraints and query patterns"]

Phases with standard Rails patterns (skip research-phase):
- **Phase [X]:** [reason — e.g., "standard RESTful CRUD, well-documented Rails conventions"]
- **Phase [Y]:** [reason — e.g., "Active Job + mailers follow established Rails patterns"]

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | [HIGH/MEDIUM/LOW] | [reason — e.g., "well-established Rails gems with strong community support"] |
| Features | [HIGH/MEDIUM/LOW] | [reason — e.g., "domain-specific features need validation with stakeholders"] |
| Architecture | [HIGH/MEDIUM/LOW] | [reason — e.g., "standard Rails MVC, but multi-tenancy approach needs validation"] |
| Pitfalls | [HIGH/MEDIUM/LOW] | [reason — e.g., "common Rails pitfalls well-documented, project-specific risks less certain"] |

**Overall confidence:** [HIGH/MEDIUM/LOW]

### Gaps to Address

[Any areas where research was inconclusive or needs validation during implementation]

- [Gap]: [how to handle during planning/execution — e.g., "hosting environment unknown, affects cache backend and job queue selection"]
- [Gap]: [how to handle during planning/execution — e.g., "expected data volume unclear, affects database indexing and pagination strategy"]
- [Gap]: [how to handle during planning/execution — e.g., "third-party API integration details pending, affects service object design"]

## Sources

### Primary (HIGH confidence)
- [Rails Guides / API docs] — [topics covered]
- [Context7 library ID] — [topics]
- [Official gem documentation] — [what was checked]

### Secondary (MEDIUM confidence)
- [Community blog / conference talk] — [finding]
- [Source] — [finding]

### Tertiary (LOW confidence)
- [Source] — [finding, needs validation]

---
*Research completed: [date]*
*Ready for roadmap: yes*
```

</template>

<guidelines>

**Executive Summary:**
- Write for someone who will only read this section
- Include the key Rails architectural recommendation and main risk
- Reference the Rails conventions that apply and where the project diverges from convention
- 2-3 paragraphs maximum

**Key Findings:**
- Summarize, don't duplicate full documents
- Link to detailed docs (STACK.md, FEATURES.md, etc.)
- Focus on what matters for roadmap decisions
- For the stack section, emphasize Rails-native solutions first (Solid Queue, Solid Cache, built-in authentication) before third-party alternatives
- Note where the project follows Rails conventions and where it needs custom patterns

**Architecture Approach:**
- Start from Rails MVC conventions and note deviations
- Be explicit about concern organization and service object boundaries
- Address data access patterns — eager loading, scopes, query objects
- Note multi-tenancy and engine extraction only if applicable

**Critical Pitfalls:**
- Prioritize Rails-specific pitfalls: N+1 queries, migration safety, callback chains, fat models
- Include Turbo/Hotwire integration gotchas if the frontend uses Hotwire
- Note deployment-specific risks (zero-downtime migrations, asset compilation)
- Reference specific gems that mitigate pitfalls (bullet, strong_migrations, strict_loading)

**Implications for Roadmap:**
- This is the most important section
- Directly informs roadmap creation
- Follow the Rails-typical build order: data model first, then controllers/views, then async, then optimization
- Be explicit about phase suggestions and rationale
- Include research flags for each suggested phase
- Note where phases can leverage Rails generators and conventions to move faster

**Confidence Assessment:**
- Be honest about uncertainty
- Note gaps that need resolution during planning
- HIGH = verified with official Rails guides or gem documentation
- MEDIUM = community consensus, multiple sources agree, established patterns
- LOW = single source, inference, or project-specific assumption

**Integration with roadmap creation:**
- This file is loaded as context during roadmap creation
- Phase suggestions here become starting point for roadmap
- Research flags inform phase planning
- Rails convention alignment should be noted to speed up estimation

</guidelines>
