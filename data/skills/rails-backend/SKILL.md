---
name: rails-backend
description: Ruby on Rails backend conventions — models, controllers, jobs, API design. Use when implementing Rails backend code, creating models, writing controllers, or designing APIs.
---

# Rails Backend Skill

Opinionated conventions for Rails backend code. Architecture is built on a single principle: **place the domain model at the center.** Controllers, jobs, and the console are all boundaries that orchestrate domain logic — they contain no business logic themselves.

**Sub-files:**
- [MODELS.md](MODELS.md) — Concern architecture, associations, scoping, callbacks
- [CONTROLLERS.md](CONTROLLERS.md) — REST conventions, strong params, concerns
- [JOBS.md](JOBS.md) — _now/_later pattern, multi-tenancy context
- [API.md](API.md) — JSON responses, serialization, versioning

---

## Core Philosophy

### Domain Model at the Center

```
Controller ──┐
             ▼
Console ──► Domain Model ◄── Job
             ▲
Script  ─────┘
```

`card.close` works identically whether called from a controller, job, console, or test. The domain model is the single source of truth for business behavior.

### No New Architectural Artifacts

No service objects, form objects, interactors, or command pattern libraries. Building blocks:

- **Models** — domain entities and operations (ActiveRecord and plain Ruby)
- **Concerns** — organize model behavior into cohesive modules
- **Controllers** — HTTP boundary only
- **Jobs** — async boundary; delegate to model methods
- **Views** — render domain state (templates, not view components)

When something doesn't fit in an entity, create a plain Ruby object with a semantic name — not a new architectural pattern. A `Signup` class, not a `SignupService`. A `Notifier`, not a `NotificationInteractor`.

### Preference for Rails Defaults

Minitest over RSpec · view templates over view components · ActiveRecord callbacks over observer patterns · `Current` over dependency injection · concerns over decorator libraries.

---

## Domain Model Overview

```
Account (tenant/organization)
  └── Users (members with roles)
  └── Boards (project spaces)
       └── Columns (workflow stages)
       └── Cards (tasks/issues)
            └── Comments, Assignments, Tags
```

---

## Multi-Tenancy

URL path-based tenancy — account ID extracted from path by middleware, sets `Current.account`.

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :identity, :account

  def session=(value)
    super(value)
    self.identity = session.identity if value.present?
  end

  def identity=(identity)
    super(identity)
    self.user = identity.users.find_by(account: account) if identity.present?
  end
end
```

Setting `Current.session` cascades: resolves `identity`, then resolves `user` for the current account.

- Always use `Current.user` instead of passing `@user` as a parameter
- Always use `Current.account` for tenant scoping
- In tests: `Current.session = sessions(:david)` sets up the full chain

---

## No Service Objects

Controllers already fulfill the application service role from DDD — they sit at the boundary and orchestrate domain entities. Adding service objects creates a redundant layer.

**The real danger: anemic domain models.** When business logic lives in service objects instead of domain entities, models become empty data holders and logic scatters across a flat list of service classes with no object-oriented structure.

```ruby
# Bad: service object drains logic from the model
class CloseCardService
  def call = @card.update!(status: "closed") && EventService.new(@card).call

# Good: logic belongs in the domain entity
module Card::Closeable
  def close(user: Current.user)
    transaction { create_closure!(user:); track_event :closed, creator: user }
  end
end
```

**Decision tree: where does logic belong?**

- Acts on one entity's state → put in model/concern
- Coordinates 2-3 entities, triggered by HTTP → controller handles it
- Coordinates 2-3 entities, domain concept → plain Ruby object (`Signup`, not `SignupService`)
- Runs async → job delegates to model method

---

## Code Style Conventions

### Conditional Returns

Prefer expanded conditionals over guard clauses in the middle of methods. Guard clauses are acceptable at the very start when the method body is non-trivial.

```ruby
# Avoid mid-method returns
def process
  return [] unless ids
  find(ids)
end

# Prefer
def process
  if ids then find(ids) else [] end
end
```

### Method Ordering

1. Class methods (top)
2. Public methods (`initialize` first)
3. Private methods — indented under `private`, no blank line after `private`

```ruby
private
  def method_one; end
  def method_two; end
```

Private methods are ordered by invocation — top-to-bottom following execution flow.

### Bang Methods

Only use `!` for methods that have a non-bang counterpart (`save`/`save!`). Do not use `!` to flag destructive actions with no non-bang version.

---

## Common Gotchas

1. **Business logic in controllers** — move it to models
2. **Custom route actions** — use `resource :closure` not `post :close`
3. **Logic in jobs** — jobs are thin wrappers; logic lives in model methods
4. **Association declaration order** — declare `belongs_to :board` before `belongs_to :account, default: -> { board.account }`
5. **Finding cards by `:id`** — cards use `:number`: `accessible_cards.find_by!(number: params[:card_id])`
6. **Multi-step operations without transactions** — always wrap in `transaction do`

---

See [MODELS.md](MODELS.md) for ActiveRecord patterns, [CONTROLLERS.md](CONTROLLERS.md) for HTTP conventions, [JOBS.md](JOBS.md) for background job patterns, and [API.md](API.md) for API design.
