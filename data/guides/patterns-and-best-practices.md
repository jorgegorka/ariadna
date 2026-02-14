# Rails Patterns and Best Practices

**A Comprehensive Guide for Rails Developers**

This documentation explains the patterns, conventions, and best practices used in Rails application. It's designed for developers who already know Ruby on Rails and need to understand how to structure and organize code.

It has been heavily inspired by the architecture and patterns of [Fizzy](https://www.fizzy.do/), a public-facing Trello clone built with Ruby on Rails. Fizzy is an excellent example of a well-architected Rails application, and this guide distills the key patterns and practices that make it successful.

We stand on the shoulders of giants.

## Table of Contents

- [Part 1: Foundation & Architecture](#part-1-foundation--architecture)
  - [1.0 The Vanilla Rails Philosophy](#10-the-vanilla-rails-philosophy)
  - [1.1 Understanding Architecture](#11-understanding-fizzys-architecture)
  - [1.2 UUID Primary Keys & Fixtures](#12-uuid-primary-keys--fixtures)
- [Part 2: Model Layer Patterns](#part-2-model-layer-patterns)
  - [2.1 Concern Architecture](#21-concern-architecture)
  - [2.2 Intention-Revealing APIs](#22-intention-revealing-apis)
  - [2.3 Smart Association Defaults](#23-smart-association-defaults)
  - [2.4 Scopes That Tell Stories](#24-scopes-that-tell-stories)
  - [2.5 Callbacks: When and How](#25-callbacks-when-and-how)
  - [2.6 Why Not Service Objects](#26-why-not-service-objects)
- [Part 3: Domain-Specific Patterns](#part-3-domain-specific-patterns)
  - [3.1 Event Tracking System](#31-event-tracking-system)
  - [3.2 Storage Tracking Pattern](#32-storage-tracking-pattern)
  - [3.3 Entropy System](#33-entropy-system)
  - [3.4 Presenter Pattern](#34-presenter-pattern)
- [Part 4: Controller & Job Patterns](#part-4-controller--job-patterns)
  - [4.1 Thin Controllers with Rich Models](#41-thin-controllers-with-rich-models)
  - [4.2 RESTful Resource Nesting](#42-restful-resource-nesting)
  - [4.3 Controller Concerns](#43-controller-concerns)
  - [4.4 Background Jobs: The _now/_later Pattern](#44-background-jobs-the-_now_later-pattern)
  - [4.5 Multi-Tenancy in Background Jobs](#45-multi-tenancy-in-background-jobs)
- [Part 5: Coding Style Guide](#part-5-coding-style-guide)
  - [5.1 Coding Conventions](#51-fizzy-coding-conventions)
- [Part 6: Common Tasks & Recipes](#part-6-common-tasks--recipes)
  - [6.1 Recipe: Adding a New State to Cards](#61-recipe-adding-a-new-state-to-cards)
  - [6.2 Recipe: Adding Event Tracking](#62-recipe-adding-event-tracking)
  - [6.3 Recipe: Creating Background Jobs](#63-recipe-creating-background-jobs)
- [Part 7: Quick Reference](#part-7-quick-reference)
  - [7.1 Concern Catalog](#71-concern-catalog)
  - [7.2 Decision Trees](#72-decision-trees)
  - [7.3 Common Gotchas](#73-common-gotchas)

---

# Part 1: Foundation & Architecture

Before diving into specific patterns, you need to understand the foundational architecture. These concepts underpin everything else in the application.

## 1.0 The Vanilla Rails Philosophy

Architecture is built on a single organizing principle: **place the domain model at the center of the application.** This idea comes from domain-driven design (Eric Evans, 2003) — the domain model is the heart of the system, and everything else exists to exercise it.

### Domain Model at the Center

Controllers, background jobs, and the Rails console are all boundaries — entry points that invoke domain model behavior. None of them contain business logic. They set up context and delegate:

```
                    ┌─────────────┐
                    │  Controller │──┐
                    └─────────────┘  │
                                     │
┌─────────────┐                      ▼
│   Console   │──────────────► ┌───────────┐
└─────────────┘                │  Domain   │
                               │   Model   │
┌─────────────┐                └───────────┘
│     Job     │──────────────►       ▲
└─────────────┘                      │
                                     │
                    ┌─────────────┐  │
                    │   Script    │──┘
                    └─────────────┘
```

This means `card.close` works the same whether called from a controller action, a background job, the Rails console, or a test. The domain model is the single source of truth for business behavior.

### No New Architectural Artifacts

It doesn't introduce architectural layers beyond what Rails and Ruby provide. No service objects, no form objects, no interactors, no command pattern libraries. The building blocks are:

- **Models** (ActiveRecord and plain Ruby classes) — domain entities and operations
- **Concerns** — organize model behavior into cohesive modules
- **Controllers** — HTTP boundary, orchestrate domain calls
- **Jobs** — async boundary, delegate to model methods
- **Views** — render domain state (templates, not view components)

When something doesn't fit in an entity, it becomes a plain Ruby object with a semantic name — not a new architectural pattern. A `Signup` class, not a `SignupService`. A `Notifier`, not a `NotificationInteractor`.

### Preference for Rails Defaults

It leans toward the tools Rails ships with rather than replacing them:

- **Minitest** over RSpec
- **View templates** over view components
- **ActiveRecord callbacks** over observer patterns
- **Concerns** over decorator libraries
- **`Current`** over dependency injection frameworks

This isn't about dogma — it's about reducing the number of concepts a developer needs to learn. When you open a controller, you see standard Rails. The patterns are Rails patterns. The only thing that's distinctive is how seriously the team takes the domain model.

## 1.1 Understanding Architecture

### Domain Model Overview

The domain model follows a clear hierarchy:

```
Account (tenant/organization)
  └── Users (members with roles)
  └── Boards (project spaces)
       └── Columns (workflow stages)
       └── Cards (tasks/issues)
            └── Comments
            └── Assignments
            └── Tags
```

**Key relationships:**
- **Account**: The tenant root. All data belongs to an account.
- **Board**: Primary organizational unit where cards live.
- **Card**: Main work item with a sequential number per account.
- **User**: Account membership with role-based permissions.

### Multi-Tenancy Pattern

It uses **URL path-based multi-tenancy** rather than subdomains or separate databases:

```
https://localhost:3006/{account_id}/boards/{board_id}
                             └─────────┘
                              7+ digit ID extracted by middleware
```

**How it works:**

1. **Middleware extraction**: `AccountSlug::Extractor` pulls the account ID from the URL path
2. **Path manipulation**: The slug moves from `PATH_INFO` to `SCRIPT_NAME`
3. **Current context**: Sets `Current.account` for the request
4. **Automatic scoping**: All queries automatically scoped to the account

**Why this matters:**
- No subdomain configuration needed
- Simpler local development (no DNS tricks)
- Single database with account_id scoping
- Testing doesn't require per-tenant setup

**Reference**: See middleware in `config/initializers/tenanting/account_slug.rb`

### The Current Context Pattern

It uses `ActiveSupport::CurrentAttributes` to maintain thread-safe request state:

**File**: `app/models/current.rb`

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :identity, :account
  attribute :http_method, :request_id, :user_agent, :ip_address, :referrer

  def session=(value)
    super(value)

    if value.present?
      self.identity = session.identity  # Cascade to identity
    end
  end

  def identity=(identity)
    super(identity)

    if identity.present?
      self.user = identity.users.find_by(account: account)  # Resolve user
    end
  end

  def with_account(value, &)
    with(account: value, &)
  end
end
```

**The cascade**: `session` → `identity` → `user`

When you set `Current.session`, it automatically:
1. Extracts the `identity` from the session
2. Finds the `user` for that identity in the current `account`

**In models, always use:**
- `Current.user` instead of passing `@user` everywhere
- `Current.account` for tenant scoping

**In tests, always set:**
```ruby
setup do
  Current.session = sessions(:david)  # Sets up user and account context
end
```

### UUID Primary Keys

It uses UUIDs (UUIDv7, base36-encoded to 25 characters) instead of auto-incrementing integers:

**Why UUIDs:**
- **Security**: No ID enumeration across tenants
- **Distributed systems**: Can generate IDs client-side
- **Merging**: No ID conflicts when combining data

**The Card exception**: Cards use `number` (integer) for user-facing IDs:
```ruby
# Card ID: "abc123def456..." (UUID, internal)
# Card number: 1234 (integer, user-facing)

# In routes and URLs
card_path(@card)  # => /cards/1234 (uses number, not ID)

# In controllers
@card = Current.user.accessible_cards.find_by!(number: params[:id])
```

**Fixture behavior:**
- Fixture UUIDs are deterministic and always "older" than test-created records
- `.first` and `.last` work predictably in tests

## 1.2 UUID Primary Keys & Fixtures

### Practical Implications

```ruby
# ✓ Good: Find cards by number
def set_card
  @card = Current.user.accessible_cards.find_by!(number: params[:id])
end

# ✗ Bad: Don't use regular find for cards
def set_card
  @card = Card.find(params[:id])  # Wrong! Cards use number for params
end

# ✓ Good: Everything else uses UUID find
def set_board
  @board = Current.user.boards.find(params[:board_id])
end
```

---

# Part 2: Model Layer Patterns

This is where distinctive style shines. Models contain business logic and use concerns heavily to organize behavior.

## 2.1 Concern Architecture

It uses concerns extensively to compose model behavior. This is the most distinctive pattern in the codebase.

### Two Types of Concerns

**1. Shared Concerns** (`app/models/concerns/`)
- Reusable across multiple models
- Use adjective naming (typically ending in `-able` or `-ed`)
- Examples: `Eventable`, `Notifiable`, `Searchable`, `Attachments`

**2. Model-Specific Concerns** (`app/models/card/`, `app/models/board/`)
- Tightly coupled to a single model
- Use namespaced naming: `ModelName::Feature`
- Examples: `Card::Closeable`, `Card::Golden`, `Board::Accessible`

### Concern Composition in Models

**File**: `app/models/card.rb`

```ruby
class Card < ApplicationRecord
  include Assignable, Attachments, Broadcastable, Closeable, Colored, Entropic, Eventable,
    Exportable, Golden, Mentions, Multistep, Pinnable, Postponable, Promptable,
    Readable, Searchable, Stallable, Statuses, Storage::Tracked, Taggable, Triageable, Watchable

  belongs_to :account, default: -> { board.account }
  belongs_to :board
  belongs_to :creator, class_name: "User", default: -> { Current.user }

  # ... rest of model
end
```

**How to read this**: Each concern adds a distinct capability. The Card model is composed of 18+ behavioral modules:

- `Closeable` → can be closed and reopened
- `Golden` → can be marked as golden (important)
- `Assignable` → can have assignees
- `Eventable` → tracks events
- `Postponable` → can be postponed to "not now"
- etc.

### Anatomy of a Concern

**File**: `app/models/card/closeable.rb`

```ruby
module Card::Closeable
  extend ActiveSupport::Concern  # Required for all concerns

  included do
    # Associations, scopes, callbacks added when concern is included
    has_one :closure, dependent: :destroy

    scope :closed, -> { joins(:closure) }
    scope :open, -> { where.missing(:closure) }

    scope :recently_closed_first, -> { closed.order(closures: { created_at: :desc }) }
    scope :closed_at_window, ->(window) { closed.where(closures: { created_at: window }) }
    scope :closed_by, ->(users) { closed.where(closures: { user_id: Array(users) }) }
  end

  # Instance methods (public)
  def closed?
    closure.present?
  end

  def open?
    !closed?
  end

  def closed_by
    closure&.user
  end

  def closed_at
    closure&.created_at
  end

  def close(user: Current.user)
    unless closed?
      transaction do
        create_closure! user: user
        track_event :closed, creator: user
      end
    end
  end

  def reopen(user: Current.user)
    if closed?
      transaction do
        closure&.destroy
        track_event :reopened, creator: user
      end
    end
  end
end
```

**Pattern breakdown:**
1. `extend ActiveSupport::Concern` - Required first line
2. `included do` block - Code run when the concern is included (associations, scopes, callbacks)
3. Public instance methods - The concern's API
4. Private methods (if needed) - Indented per style guide

### Naming Conventions

**Shared concerns** (adjectives):
- `Eventable` - can track events
- `Notifiable` - can send notifications
- `Searchable` - indexed for search
- `Attachments` - can have file attachments
- `Mentions` - can mention users

**Model-specific concerns** (namespaced):
- `Card::Closeable` - card closing/reopening logic
- `Card::Golden` - golden card functionality
- `Card::Postponable` - postponement logic
- `Board::Accessible` - board access control
- `Board::Storage` - storage calculation

### Template Method Pattern

Concerns can define override points for including models to customize behavior.

**Base concern** (`app/models/concerns/eventable.rb`):

```ruby
module Eventable
  extend ActiveSupport::Concern

  included do
    has_many :events, as: :eventable, dependent: :destroy
  end

  def track_event(action, creator: Current.user, board: self.board, **particulars)
    if should_track_event?  # ← Template method
      board.events.create!(
        action: "#{eventable_prefix}_#{action}",  # ← Template method
        creator:,
        board:,
        eventable: self,
        particulars:
      )
    end
  end

  def event_was_created(event)  # ← Template method
    # Override in specific concerns
  end

  private
    def should_track_event?  # ← Template method (default implementation)
      true
    end

    def eventable_prefix  # ← Template method (default implementation)
      self.class.name.demodulize.underscore
    end
end
```

**Card-specific override** (`app/models/card/eventable.rb`):

```ruby
module Card::Eventable
  extend ActiveSupport::Concern

  include ::Eventable  # ← Includes the base concern

  included do
    before_create { self.last_active_at ||= created_at || Time.current }
    after_save :track_title_change, if: :saved_change_to_title?
  end

  def event_was_created(event)  # ← Overrides template method
    transaction do
      create_system_comment_for(event)
      touch_last_active_at unless was_just_published?
    end
  end

  private
    def should_track_event?  # ← Overrides template method
      published?  # Only track events for published cards
    end

    def track_title_change
      if title_before_last_save.present?
        track_event "title_changed",
          particulars: { old_title: title_before_last_save, new_title: title }
      end
    end
end
```

**The pattern**: Base concern provides default behavior with override points. Model-specific concerns customize by overriding those methods.

### When to Create a Concern

**Create a shared concern when:**
- 3+ unrelated models need the same behavior
- The behavior is cross-cutting (events, search, notifications)
- The functionality is self-contained with clear boundaries

**Create a model-specific concern when:**
- A model has complex domain behavior
- You can extract 50+ lines into a cohesive module
- The feature has multiple methods working together
- Examples: state management, complex calculations, batch operations

**Don't create a concern when:**
- You have only 1-2 simple methods
- The code is unique to one place
- You're just grouping unrelated methods

### Concern Layering

Concerns can include other concerns:

```ruby
module Card::Eventable
  extend ActiveSupport::Concern

  include ::Eventable  # ← Card::Eventable layers on top of Eventable

  # Additional card-specific behavior
end
```

### Combining Concerns with Object Composition

Concerns are not a silver bullet. They organize large API surfaces into cohesive modules, but complex logic shouldn't live entirely inside concerns. The pattern: **concerns provide the entry point and framework integration; dedicated plain Ruby objects handle the complexity.**

**Example 1: Notifiable → Notifier hierarchy**

The `Notifiable` concern defines the interface, but delegates the actual work:

**File**: `app/models/concerns/notifiable.rb`

```ruby
module Notifiable
  extend ActiveSupport::Concern

  included do
    has_many :notifications, as: :source, dependent: :destroy
    after_create_commit :notify_recipients_later
  end

  def notify_recipients
    Notifier.for(self)&.notify  # ← Delegates to a dedicated object
  end
end
```

The `Notifier` class uses a factory method and template method pattern — a hierarchy of objects where each subclass customizes recipient logic:

```ruby
# app/models/notifier.rb
class Notifier
  def self.for(source)
    # Returns the right notifier subclass based on source type
  end

  def notify
    recipients.each { |user| create_notification_for(user) }
  end

  def recipients  # ← Template method, overridden by subclasses
    raise NotImplementedError
  end
end

# app/models/mention/notifier.rb
class Mention::Notifier < Notifier
  def recipients
    # Mention-specific recipient logic
  end
end
```

The concern organizes the API surface (`notify_recipients`, the callback, the association). The Notifier hierarchy handles the complexity.

**Example 2: Stallable → ActivitySpike::Detector**

The `Card::Stallable` concern detects when cards go cold after a burst of activity:

**File**: `app/models/card/stallable.rb`

```ruby
module Card::Stallable
  extend ActiveSupport::Concern

  included do
    has_one :activity_spike, dependent: :destroy
    after_update :detect_activity_spikes_later
  end

  def detect_activity_spikes
    Card::ActivitySpike::Detector.new(self).detect  # ← Delegates to dedicated object
  end
end
```

The detection logic — "is this card entropic? Did multiple people comment? Was it just assigned?" — lives in `Card::ActivitySpike::Detector`, not in the concern itself.

**The pattern:**

```
Concern (framework integration)     Plain Ruby Object (business logic)
─────────────────────────────────   ──────────────────────────────────
• Associations, scopes, callbacks   • Complex decision logic
• Public API methods                • Hierarchies and composition
• Framework hooks                   • Algorithms and calculations
        │                                       ▲
        └── delegates to ──────────────────────┘
```

This combination gives you the best of both worlds: concerns keep your model's API organized and lightweight, while proper object-oriented design handles the complexity behind the scenes.

## 2.2 Intention-Revealing APIs

It emphasizes method names that read like business domain language. Models provide APIs that express intent clearly.

### Boolean Query Methods

Always provide both positive and negative checks:

**File**: `app/models/card/closeable.rb`

```ruby
def closed?
  closure.present?
end

def open?
  !closed?
end
```

**File**: `app/models/card/golden.rb`

```ruby
def golden?
  goldness.present?
end

# Usage in code:
if card.closed?
  # ...
end

if card.open? && card.golden?
  # ...
end
```

**Pattern**: Boolean methods end with `?` and read naturally in conditions.

### Action Methods (Imperative Verbs)

Use clear imperative verbs for actions that change state:

**File**: `app/models/card/golden.rb`

```ruby
def gild
  create_goldness! unless golden?
end

def ungild
  goldness&.destroy
end
```

**File**: `app/models/card/closeable.rb`

```ruby
def close(user: Current.user)
  unless closed?
    transaction do
      create_closure! user: user
      track_event :closed, creator: user
    end
  end
end

def reopen(user: Current.user)
  if closed?
    transaction do
      closure&.destroy
      track_event :reopened, creator: user
    end
  end
end
```

**Notice the pattern:**
- `close` / `reopen` (not `closed` / `unclosed`)
- `gild` / `ungild` (not `make_golden` / `remove_golden`)
- Clear opposites that read naturally

### Delegation for Readability

Use delegation to create more readable APIs:

**File**: `app/models/card/closeable.rb`

```ruby
def closed_by
  closure&.user
end

def closed_at
  closure&.created_at
end

# Usage:
card.closed_by      # ← Reads nicely
# vs
card.closure&.user  # ← Leaks implementation details
```

### Complex Actions with Transactions

Multi-step operations wrap everything in transactions and track events:

**File**: `app/models/card.rb`

```ruby
def handle_board_change
  old_board = account.boards.find_by(id: board_id_before_last_save)

  transaction do
    update! column: nil                           # 1. Clear column
    track_board_change_event(old_board.name)      # 2. Track event
    grant_access_to_assignees unless board.all_access?  # 3. Grant access
  end

  remove_inaccessible_notifications_later         # 4. Async cleanup
end

private
  def track_board_change_event(old_board_name)
    track_event "board_changed",
      particulars: { old_board: old_board_name, new_board: board.name }
  end

  def grant_access_to_assignees
    board.accesses.grant_to(assignees)
  end
```

**Pattern**:
1. **Transaction boundary** - All or nothing
2. **Multiple state changes** - Related updates together
3. **Event tracking** - Always inside the transaction
4. **Async operations** - Outside the transaction (can fail separately)

### Anti-Patterns to Avoid

```ruby
# ✗ Bad: Generic method names
def process
def handle
def do_something

# ✓ Good: Intention-revealing names
def close
def postpone
def assign_to(user)

# ✗ Bad: Leaking implementation details
def create_closure_record
def set_golden_flag

# ✓ Good: Domain concepts
def close
def gild

# ✗ Bad: Unclear what happens
def update_state(value)

# ✓ Good: Explicit actions
def close
def reopen
```

## 2.3 Smart Association Defaults

It uses lambda defaults on `belongs_to` associations to automatically propagate context. This reduces boilerplate and enforces multi-tenancy.

### Basic Pattern

**File**: `app/models/card.rb`

```ruby
class Card < ApplicationRecord
  belongs_to :account, default: -> { board.account }  # ← Get account from board
  belongs_to :board                                    # ← Must declare before use
  belongs_to :creator, class_name: "User", default: -> { Current.user }

  # Now when creating a card:
  # Card.create!(board: some_board, title: "...")
  #
  # Automatically sets:
  # - account (from board.account)
  # - creator (from Current.user)
end
```

**Why this matters:**

```ruby
# Without lambda defaults:
Card.create!(
  board: board,
  account: board.account,      # ← Repetitive
  creator: Current.user,        # ← Easy to forget
  title: "New card"
)

# With lambda defaults:
Card.create!(
  board: board,
  title: "New card"
)
# account and creator set automatically!
```

### Declaration Order Matters

You must declare associations before using them in defaults:

```ruby
# ✓ Correct order
belongs_to :board                             # Declare first
belongs_to :account, default: -> { board.account }  # Use after

# ✗ Wrong order
belongs_to :account, default: -> { board.account }  # Error! board not declared yet
belongs_to :board
```

### Current Context Integration

Lambda defaults commonly use `Current.user` for automatic creator tracking:

**File**: `app/models/event.rb`

```ruby
class Event < ApplicationRecord
  belongs_to :board
  belongs_to :account, default: -> { board.account }
  belongs_to :creator, class_name: "User", default: -> { Current.user }
  belongs_to :eventable, polymorphic: true

  # Usage in models:
  # board.events.create!(action: "card_closed", eventable: card)
  # Automatically sets account and creator!
end
```

### Multi-Tenancy Enforcement

Lambda defaults help enforce multi-tenancy automatically:

**File**: `app/models/access.rb`

```ruby
class Access < ApplicationRecord
  belongs_to :account, default: -> { user.account }  # ← Account from user
  belongs_to :board, touch: true
  belongs_to :user, touch: true
end
```

Every record automatically gets its `account_id` set, maintaining tenant isolation.

### When to Use Lambda Defaults

**Always use for:**
- `account` - Multi-tenancy (get from parent association)
- `creator`/`user` - User tracking (from `Current.user`)

**Consider for:**
- Other contextual defaults that come from parent objects
- Values that are always derived from other associations

**Don't use for:**
- Complex business logic (use callbacks or explicit methods instead)
- Values that need validation or can fail
- Defaults that depend on instance state

## 2.4 Scopes That Tell Stories

Scopes have descriptive names that express business concepts, not SQL operations. They're composable and chainable.

### Naming Conventions

**State filters** (adjectives):

**File**: `app/models/card/closeable.rb`

```ruby
scope :closed, -> { joins(:closure) }
scope :open, -> { where.missing(:closure) }
```

**Ordering** (adverbs):

**File**: `app/models/card.rb`

```ruby
scope :reverse_chronologically, -> { order created_at: :desc, id: :desc }
scope :chronologically,         -> { order created_at: :asc,  id: :asc  }
scope :latest,                  -> { order last_active_at: :desc, id: :desc }
```

**Time-based** (gerunds or descriptions):

```ruby
scope :postponing_soon, -> { ... }
scope :due_to_be_postponed, -> { ... }
```

### Composable Scopes

Scopes return `ActiveRecord::Relation` so they can be chained:

```ruby
# All of these work:
Card.open
Card.open.latest
Card.open.golden.latest
Card.closed.closed_by([user1, user2])
```

**File**: `app/models/card/closeable.rb`

```ruby
scope :closed, -> { joins(:closure) }
scope :open, -> { where.missing(:closure) }

scope :recently_closed_first, -> { closed.order(closures: { created_at: :desc }) }
scope :closed_at_window, ->(window) { closed.where(closures: { created_at: window }) }
scope :closed_by, ->(users) { closed.where(closures: { user_id: Array(users) }) }
```

### Conditional Scopes for UI

Use case statements in scopes to map UI concepts to queries:

**File**: `app/models/card.rb`

```ruby
scope :indexed_by, ->(index) do
  case index
  when "stalled" then stalled
  when "postponing_soon" then postponing_soon
  when "closed" then closed
  when "not_now" then postponed.latest
  when "golden" then golden
  when "draft" then drafted
  else all
  end
end

scope :sorted_by, ->(sort) do
  case sort
  when "newest" then reverse_chronologically
  when "oldest" then chronologically
  when "latest" then latest
  else latest
  end
end

# Usage in controllers:
@cards = board.cards.indexed_by(params[:index]).sorted_by(params[:sort])
```

This keeps conditional logic out of controllers.

### Preloading Scopes

Define scopes for eager loading to prevent N+1 queries:

**File**: `app/models/card.rb`

```ruby
scope :with_users, -> {
  preload(
    creator: [ :avatar_attachment, :account ],
    assignees: [ :avatar_attachment, :account ]
  )
}

scope :preloaded, -> {
  with_users
    .preload(:column, :tags, :steps, :closure, :goldness, :activity_spike,
             :image_attachment, board: [ :entropy, :columns ], not_now: [ :user ])
    .with_rich_text_description_and_embeds
}

# Usage:
@cards = board.cards.preloaded  # ← Single query loads everything
```

### Best Practices

```ruby
# ✓ Good: Descriptive business name
scope :closed, -> { joins(:closure) }

# ✗ Bad: SQL operation name
scope :with_closures, -> { joins(:closure) }

# ✓ Good: Chainable
scope :closed, -> { joins(:closure) }
scope :closed_by, ->(users) { closed.where(closures: { user_id: users }) }

# ✗ Bad: Not chainable (returns array)
scope :closed_list, -> { closed.to_a }

# ✓ Good: Use lambda for stability
scope :active, -> { where(status: 'active') }

# ✗ Bad: Direct block (evaluated at load time)
scope :active, where(status: 'active')
```

## 2.5 Callbacks: When and How

### The "Whenever X Happens" Test

Callbacks are controversial in Rails, but the controversy comes from misuse, not from callbacks themselves. The right mental model: **if you can naturally say "whenever X happens, do Y" as a human describing the system, a callback is the right tool.**

Examples where callbacks fit naturally:
- "Whenever a card changes, detect activity spikes" → `after_update :detect_activity_spikes_later`
- "Whenever a notifiable object is created, notify recipients" → `after_create_commit :notify_recipients_later`
- "Whenever a card's title changes, track the change" → `after_save :track_title_change, if: :saved_change_to_title?`

The key insight: callbacks express **reactive, cross-cutting behavior** that should fire regardless of *how* the change happens. If you introduce a new way of commenting on a card, the activity spike detection system keeps working automatically — that's good design.

But having callbacks available doesn't mean using them everywhere. **Explicit invocation is the default.** For example, in `Card::Triageable`, `track_event` is called explicitly inside `send_back_to_triage` — not via a callback — because event tracking there is part of the specific operation, not a cross-cutting reactive concern.

### Minimal Callback Guidelines

**Use callbacks for:**
- Data consistency (setting required fields)
- Triggering async operations
- Touching associations

**Don't use callbacks for:**
- Business logic (use explicit methods instead)
- Complex orchestration
- Anything users might want to skip

### Common Patterns

#### `before_create` - Set Required Data

**File**: `app/models/card.rb`

```ruby
before_create :assign_number

private
  def assign_number
    self.number ||= account.increment!(:cards_count).cards_count
  end
```

Use `before_create` for data that must be set before saving:
- Sequential numbers
- Default values based on other records
- ID generation

#### `after_create_commit` - Async Operations

**File**: `app/models/concerns/notifiable.rb`

```ruby
module Notifiable
  extend ActiveSupport::Concern

  included do
    has_many :notifications, as: :source, dependent: :destroy

    after_create_commit :notify_recipients_later  # ← Note the _commit
  end

  private
    def notify_recipients_later
      NotifyRecipientsJob.perform_later self
    end
end
```

**Why `_commit`?**
- Only runs after transaction successfully commits
- Prevents jobs from running for rolled-back records
- Standard pattern for background jobs

#### `after_save` - Touch Associations

**File**: `app/models/card.rb`

```ruby
after_save   -> { board.touch }, if: :published?
after_touch  -> { board.touch }, if: :published?
```

Cascade touch events to parent associations for cache invalidation.

#### Conditional Callbacks

Use `if:`/`unless:` to run callbacks conditionally:

**File**: `app/models/card.rb`

```ruby
after_update :handle_board_change, if: :saved_change_to_board_id?

# Only runs when board_id changes
```

**File**: `app/models/card/eventable.rb`

```ruby
after_save :track_title_change, if: :saved_change_to_title?

private
  def track_title_change
    if title_before_last_save.present?
      track_event "title_changed",
        particulars: { old_title: title_before_last_save, new_title: title }
    end
  end
```

### Lambda Callbacks for Simple Operations

For single-line operations, use lambda callbacks:

```ruby
# ✓ Good: Simple one-liner
after_save -> { board.touch }, if: :published?

# ✗ Overkill: Method for one line
after_save :touch_board, if: :published?

private
  def touch_board
    board.touch
  end
```

### Anti-Patterns

```ruby
# ✗ Bad: Complex business logic in callback
after_create :send_notifications_and_update_metrics

private
  def send_notifications_and_update_metrics
    # 50 lines of logic
  end

# ✓ Good: Explicit method called from controller
def publish
  transaction do
    update!(status: 'published')
    send_notifications
    update_metrics
  end
end

# ✗ Bad: Callbacks that prevent standard operations
before_destroy :prevent_if_has_comments

# ✓ Good: Explicit methods
def can_destroy?
  comments.none?
end
```

## 2.6 Why Not Service Objects

It deliberately avoids service objects. This isn't a minor style preference — it's a core architectural decision rooted in domain-driven design principles.

### Controllers Already Fill This Role

In DDD, the "application service" layer connects the external world with the domain model. It orchestrates domain entities to satisfy business needs. Rails controllers already do exactly this:

**File**: `app/controllers/cards/closures_controller.rb`

```ruby
class Cards::ClosuresController < ApplicationController
  include CardScoped

  def create
    @card.close  # ← Orchestrating domain logic from the boundary

    respond_to do |format|
      format.turbo_stream { render_card_replacement }
    end
  end
end
```

DDD proposed service objects before Rails existed. Rails controllers fulfill that role — they sit at the boundary and orchestrate domain entities. Adding service objects on top creates a redundant layer.

### The Boilerplate Problem

If you use service objects the way DDD intends (for orchestration, not business logic), they become one-line wrappers:

```ruby
# ✗ Service object that just wraps a domain model call
class SendBackToTriage
  def initialize(card)
    @card = card
  end

  def call
    @card.send_back_to_triage  # ← Just wrapping one line
  end
end

@card.send_back_to_triage
```

You've replaced a single line of code with an entire class for no benefit. Controllers already provide the orchestration context.

### The Real Danger: Anemic Domain Models

The bigger problem comes when developers put business logic *inside* service objects. This is a well-known anti-pattern identified by Eric Evans (DDD, 2003) and Martin Fowler ("Anemic Domain Model," 2003):

```ruby
# ✗ Dangerous: business logic lives in the service object
class SendBackToTriageService
  def initialize(card)
    @card = card
  end

  def call
    @card.update!(column: nil)
    @card.resume  # But wait — this calls another service object...
    ResumeService.new(@card).call
    @card.track_event(:sent_back_to_triage)
  end
end
```

When business logic lives in service objects instead of domain entities:
- **Domain models become empty data holders** — they have attributes but no behavior
- **Logic scatters across a flat list of service classes** — no hierarchy, no composition
- **Code reuse requires coupling between services** — service A calls service B calls service C
- **You lose the benefits of object-oriented design** — encapsulation, polymorphism, cohesion

Compare the approach where the domain model owns its behavior:

**File**: `app/models/card/triageable.rb`

```ruby
module Card::Triageable
  def send_back_to_triage(user: Current.user, skip_event: false)
    if triaged?
      transaction do
        update! column: nil
        track_event :sent_back_to_triage, creator: user unless skip_event
      end
    end
  end
end
```

The logic lives where it belongs — in the domain entity that knows about its own state and invariants.

### Domain Operations as Plain Ruby Objects

When an operation genuinely doesn't fit in a single entity, create a plain Ruby object with a semantic name:

```ruby
# ✓ Good: semantic name, domain operation
class Signup
  def self.create_identity(email:, name:)
    # Creates an identity in the system
    # This isn't an entity — it's a domain operation
  end
end

# Usage in controller:
Signup.create_identity(email: params[:email], name: params[:name])
```

Note the naming: `Signup.create_identity`, not `SignupService.call`. The name describes what the object represents in the domain, not its architectural role.

### Decision Tree: Where Does This Logic Belong?

```
Does the operation act on a single entity's state?
│
├─ YES → Put it in the entity (model or concern)
│        Example: card.close, card.send_back_to_triage
│
└─ NO
   │
   └─ Does it coordinate 2-3 entities at a high level?
      │
      ├─ YES, and it's triggered by HTTP → Controller handles it
      │  Example: @board.update!(params) then @board.accesses.revise(user_ids)
      │
      ├─ YES, and it's a domain concept → Plain Ruby object
      │  Example: Signup.create_identity (not tied to any single entity)
      │
      └─ YES, and it runs async → Job delegates to model method
         Example: NotifyRecipientsJob → notifiable.notify_recipients
```

---

# Part 3: Domain-Specific Patterns

It has several unique domain-specific features that follow consistent patterns.

## 3.1 Event Tracking System

Events audit trail. Every significant action creates an event record that drives activity timelines, notifications, and webhooks.

### Why Events Matter

Events serve multiple purposes:
1. **Activity timeline** - Show users what happened
2. **Webhook payloads** - External integrations get event data
3. **Notification triggers** - Events create notifications
4. **Audit trail** - Historical record of changes

### The Eventable Concern

**File**: `app/models/concerns/eventable.rb`

```ruby
module Eventable
  extend ActiveSupport::Concern

  included do
    has_many :events, as: :eventable, dependent: :destroy
  end

  def track_event(action, creator: Current.user, board: self.board, **particulars)
    if should_track_event?
      board.events.create!(
        action: "#{eventable_prefix}_#{action}",
        creator:,
        board:,
        eventable: self,
        particulars:
      )
    end
  end

  def event_was_created(event)
    # Override in specific models to react to event creation
  end

  private
    def should_track_event?
      true  # Override to conditionally track
    end

    def eventable_prefix
      self.class.name.demodulize.underscore  # "Card" → "card"
    end
end
```

**The API**: `track_event(action, creator:, board:, **particulars)`

### Using Track Event

**File**: `app/models/card/closeable.rb`

```ruby
def close(user: Current.user)
  unless closed?
    transaction do
      create_closure! user: user
      track_event :closed, creator: user  # ← Tracks event
    end
  end
end
```

**File**: `app/models/card/assignable.rb`

```ruby
def assign(user, assigner: Current.user)
  unless assigned_to?(user)
    transaction do
      assignments.create!(assignee: user, assigner: assigner)
      track_event :assigned, assignee_ids: [ user.id ]  # ← With particulars
    end
  end
end
```

### Model-Specific Customization

Models customize event behavior by overriding template methods:

**File**: `app/models/card/eventable.rb`

```ruby
module Card::Eventable
  extend ActiveSupport::Concern

  include ::Eventable  # ← Include base concern

  included do
    before_create { self.last_active_at ||= created_at || Time.current }
    after_save :track_title_change, if: :saved_change_to_title?
  end

  def event_was_created(event)  # ← Override hook
    transaction do
      create_system_comment_for(event)
      touch_last_active_at unless was_just_published?
    end
  end

  private
    def should_track_event?  # ← Override conditional
      published?  # Only track events for published cards
    end

    def track_title_change
      if title_before_last_save.present?
        track_event "title_changed",
          particulars: { old_title: title_before_last_save, new_title: title }
      end
    end

    def create_system_comment_for(event)
      SystemCommenter.new(self, event).comment
    end
end
```

### Event Lifecycle

1. **Action occurs**: `card.close`
2. **Track event** (inside transaction): `track_event :closed`
3. **Event created**: Database INSERT
4. **`after_create` callback**: `eventable.event_was_created(event)` ← Synchronous
5. **`after_create_commit`**: Dispatch webhooks ← Async

### Particulars Hash

The `particulars` hash stores action-specific data as JSON:

```ruby
# Board change event
track_event "board_changed",
  particulars: { old_board: "Project A", new_board: "Project B" }

# Title change event
track_event "title_changed",
  particulars: { old_title: "Old Title", new_title: "New Title" }

# Assignment event
track_event :assigned,
  assignee_ids: [ user.id ]

# Access to particulars:
event.particulars["old_board"]  # => "Project A"
```

### Adding Events to New Actions

**Step-by-step:**

1. Include `Eventable` in your model (if not already included)
2. Call `track_event` in your action method (inside transaction)
3. Pass relevant data in `particulars` hash
4. Test that events are created

**Example**: Adding event to a hypothetical `archive` method:

```ruby
def archive(user: Current.user)
  unless archived?
    transaction do
      update!(archived_at: Time.current)
      track_event :archived, creator: user  # ← Add event tracking
    end
  end
end

# In test:
test "archiving creates event" do
  assert_difference -> { Event.count }, +1 do
    cards(:logo).archive
  end

  assert_equal "card_archived", Event.last.action
  assert_equal cards(:logo), Event.last.eventable
end
```

## 3.2 Storage Tracking Pattern

It tracks file storage usage at the board and account level to enforce quotas. This pattern shows how to handle complex accounting across hierarchies.

### Business Context

- Each account has a storage quota
- Boards show their storage usage
- Count only original uploads (not image variants)
- When cards move between boards, storage moves too

### The Storage::Tracked Concern

**File**: `app/models/concerns/storage/tracked.rb` (simplified)

```ruby
module Storage::Tracked
  extend ActiveSupport::Concern

  TRACKED_RECORD_TYPES = %w[ Card Comment ].freeze

  included do
    after_create_commit :track_storage_later
    after_update_commit :track_storage_transfer_later, if: :saved_change_to_board_id?
  end

  private
    def track_storage_later
      Storage::TrackJob.perform_later(self)
    end

    def track_storage_transfer_later
      Storage::TransferJob.perform_later(
        records: storage_transfer_records,
        from_board_id: board_id_before_last_save,
        to_board_id: board_id
      )
    end

    def storage_transfer_records
      [ self ]  # Override in models to include related records
    end
end
```

### Board Transfer Logic

When a card moves boards, all its storage must transfer:

**File**: `app/models/card.rb`

```ruby
private
  STORAGE_BATCH_SIZE = 1000

  # Override to include comments, but only load comments that have attachments.
  # Cards can have thousands of comments; most won't have attachments.
  # Streams in batches to avoid loading all IDs into memory at once.
  def storage_transfer_records
    comment_ids_with_attachments = storage_comment_ids_with_attachments

    if comment_ids_with_attachments.any?
      [ self, *comments.where(id: comment_ids_with_attachments).to_a ]
    else
      [ self ]
    end
  end

  def storage_comment_ids_with_attachments
    direct = []
    rich_text_map = {}

    # Stream comment IDs in batches to avoid loading all into memory
    comments.in_batches(of: STORAGE_BATCH_SIZE) do |batch|
      batch_ids = batch.pluck(:id)

      # Find comments with direct attachments
      direct.concat \
        ActiveStorage::Attachment
          .where(record_type: "Comment", record_id: batch_ids)
          .distinct
          .pluck(:record_id)

      # Build map of rich text records to comments
      ActionText::RichText
        .where(record_type: "Comment", record_id: batch_ids)
        .pluck(:id, :record_id)
        .each { |rt_id, comment_id| rich_text_map[rt_id] = comment_id }
    end

    # Find comments with rich text embeds
    embed_comment_ids = if rich_text_map.any?
      rich_text_map.keys.each_slice(STORAGE_BATCH_SIZE).flat_map do |batch_ids|
        ActiveStorage::Attachment
          .where(record_type: "ActionText::RichText", record_id: batch_ids)
          .distinct
          .pluck(:record_id)
      end.filter_map { |rt_id| rich_text_map[rt_id] }
    else
      []
    end

    (direct + embed_comment_ids).uniq
  end
```

**Pattern highlights:**
- **Batch processing**: Process in chunks to avoid memory issues
- **Selective loading**: Only load comments with attachments
- **Rich text resolution**: Handle embedded images in rich text
- **Performance**: No N+1 queries, streams data

### When to Modify Storage Tracking

**Adding attachments to a new model:**

1. Add model to `TRACKED_RECORD_TYPES`
2. Include `Storage::Tracked` concern
3. Implement `storage_transfer_records` if hierarchical

**Adding storage features:**

Follow the pattern:
- Track on creation
- Transfer on board changes
- Handle rich text embeds
- Batch process large datasets

## 3.3 Entropy System

The unique "entropy" feature automatically postpones stale cards to prevent infinite todo lists. This shows how to implement complex time-based business rules.

### Business Philosophy

- Cards that go untouched eventually "decay"
- After an inactivity period, cards auto-postpone to "not now"
- Period is configurable per account/board
- Prevents todo lists from growing forever

### The Entropic Concern

**File**: `app/models/card/entropic.rb` (simplified)

```ruby
module Card::Entropic
  extend ActiveSupport::Concern

  included do
    scope :due_to_be_postponed, -> do
      active
        .joins(board: :account)
        .left_outer_joins(board: :entropy)
        .joins("LEFT OUTER JOIN entropies AS account_entropies
                ON account_entropies.account_id = accounts.id")
        .where("last_active_at <= #{connection.date_subtract('?',
                'COALESCE(entropies.auto_postpone_period,
                         account_entropies.auto_postpone_period)')}",
               Time.now)
    end

    delegate :auto_postpone_period, to: :board
  end

  class_methods do
    def auto_postpone_all_due
      due_to_be_postponed.find_each do |card|
        card.auto_postpone(user: card.account.system_user)
      end
    end
  end

  def entropy
    Card::Entropy.for(self)
  end

  def entropic?
    entropy.present?
  end
end
```

**Key points:**
- Complex SQL with COALESCE for fallback
- Board-level period overrides account-level
- Class method for batch processing
- Used by recurring job

### The Postponable Concern

**File**: `app/models/card/postponable.rb` (simplified)

```ruby
module Card::Postponable
  extend ActiveSupport::Concern

  included do
    has_one :not_now, dependent: :destroy
    scope :postponed, -> { joins(:not_now) }
  end

  def postponed?
    not_now.present?
  end

  def postpone(user: Current.user, event_name: :postponed)
    transaction do
      send_back_to_triage(skip_event: true)
      reopen
      activity_spike&.destroy
      create_not_now!(user: user) unless postponed?
      track_event event_name, creator: user
    end
  end

  def auto_postpone(user: Current.user)
    postpone(user: user, event_name: :auto_postponed)
  end

  def resume(user: Current.user)
    if postponed?
      transaction do
        not_now.destroy
        track_event :resumed, creator: user
      end
    end
  end
end
```

**Note**: `auto_postpone` uses different event name than manual `postpone`.

### Configuration Inheritance

```sql
-- SQL shows board entropy overrides account entropy
COALESCE(
  board_entropies.auto_postpone_period,  -- Board-specific first
  account_entropies.auto_postpone_period -- Account default fallback
)
```

### Recurring Job Integration

**File**: `config/recurring.yml`

```yaml
auto_postpone_cards:
  schedule: "50 * * * *"  # Every hour at :50
  command: "Card.auto_postpone_all_due"
```

The class method `Card.auto_postpone_all_due` is called hourly to process all eligible cards.

## 3.4 Presenter Pattern

It uses presenter classes to encapsulate complex view logic. Unlike typical Rails apps, presenters don't live in an `app/presenters/` directory—they live in `app/models/` organized by domain, aligning with "vanilla Rails" philosophy.

### Philosophy

Presenters are plain Ruby classes that:
- Package data and display logic for views
- Transform domain objects into view-ready formats
- Encapsulate conditional display logic
- Provide cache keys for fragment caching

**Why models layer?** Presenters are domain objects that know about business rules. They fit naturally alongside concerns like `User::Filtering` and `Event::Description`. No separate presenter infrastructure is needed.

### When to Create a Presenter

**Create a presenter when:**
- A view needs complex conditional logic (3+ conditions)
- Multiple related values need to be computed together
- You need to transform data into HTML or formatted text
- The same display logic is needed in multiple views
- You want to cache complex view fragments

**Don't create a presenter when:**
- Simple delegation would suffice (use helpers)
- You only need one or two computed values
- The logic is purely formatting (use view helpers)

### Anatomy of a Presenter

**File**: `app/models/user/filtering.rb`

```ruby
class User::Filtering
  attr_reader :user, :filter, :expanded

  delegate :as_params, :single_board, to: :filter
  delegate :only_closed?, to: :filter

  def initialize(user, filter, expanded: false)
    @user, @filter, @expanded = user, filter, expanded
  end

  # Memoized collections (lazy-loaded)
  def boards
    @boards ||= user.boards.ordered_by_recently_accessed
  end

  def tags
    @tags ||= account.tags.all.alphabetically
  end

  def users
    @users ||= account.users.active.alphabetically
  end

  # Boolean methods for conditional display
  def expanded?
    @expanded
  end

  def any?
    filter.used?(ignore_boards: true)
  end

  def show_tags?
    return unless Tag.any?
    filter.tags.any?
  end

  def show_assignees?
    filter.assignees.any?
  end

  # Cache key for fragment caching
  def cache_key
    ActiveSupport::Cache.expand_cache_key(
      [ user, filter, expanded?, boards, tags, users, filters ],
      "user-filtering"
    )
  end

  private
    def account
      user.account
    end
end
```

**Pattern breakdown:**

1. **Plain Ruby class** - No framework, no gem, no inheritance
2. **Explicit dependencies** - All inputs via constructor
3. **Memoization** - `@var ||=` for lazy-loaded collections
4. **Boolean methods** - `show_tags?`, `expanded?` for conditional display
5. **Cache key** - Composite key for fragment caching
6. **Private helpers** - Keep the interface clean

### Generating HTML in Presenters

When presenters need to generate HTML, include ActionView helpers:

**File**: `app/models/event/description.rb`

```ruby
class Event::Description
  include ActionView::Helpers::TagHelper  # ← For tag.span, etc.
  include ERB::Util                       # ← For h() escaping

  attr_reader :event, :user

  def initialize(event, user)
    @event = event
    @user = user
  end

  def to_html
    to_sentence(creator_tag, card_title_tag).html_safe
  end

  def to_plain_text
    to_sentence(creator_name, quoted(card.title))
  end

  private
    def creator_tag
      tag.span data: { creator_id: event.creator.id } do
        tag.span("You", data: { only_visible_to_you: true }) +
        tag.span(event.creator.name, data: { only_visible_to_others: true })
      end
    end

    def card_title_tag
      tag.span card.title, class: "txt-underline"
    end

    # ... action-specific sentence methods ...
end
```

**Key patterns:**
- `to_html` / `to_plain_text` for multiple output formats
- Include only the helpers you need
- Use `h()` for escaping user content
- Keep HTML generation in private methods

### Nested Presenters

Presenters can create other presenters for sub-components:

**File**: `app/models/user/day_timeline.rb`

```ruby
class User::DayTimeline
  def added_column
    @added_column ||= build_column(:added, "Added", 1,
      events.where(action: %w[card_published card_reopened]))
  end

  def updated_column
    @updated_column ||= build_column(:updated, "Updated", 2,
      events.where.not(action: %w[card_published card_closed card_reopened]))
  end

  def closed_column
    @closed_column ||= build_column(:closed, "Done", 3,
      events.where(action: "card_closed"))
  end

  private
    def build_column(id, base_title, index, events)
      Column.new(self, id, base_title, index, events)  # ← Nested presenter
    end
end
```

**File**: `app/models/user/day_timeline/column.rb`

```ruby
class User::DayTimeline::Column
  include ActionView::Helpers::TagHelper, ActionView::Helpers::OutputSafetyHelper

  def title
    date_tag = local_datetime_tag(day_timeline.day, style: :agoorweekday)
    parts = [ base_title, date_tag ]
    parts << tag.span("(#{full_events_count})", class: "font-weight-normal") if full_events_count > 0
    safe_join(parts, " ")
  end

  def events_by_hour
    limited_events.group_by { it.created_at.hour }
  end

  def has_more_events?
    limited_events.count < full_events_count
  end
end
```

### Instantiation Patterns

#### Pattern 1: Controller Concerns

For presenters used across multiple controllers, create a concern:

**File**: `app/controllers/concerns/filter_scoped.rb`

```ruby
module FilterScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_filter
    before_action :set_user_filtering
  end

  private
    def set_filter
      if params[:filter_id].present?
        @filter = Current.user.filters.find(params[:filter_id])
      else
        @filter = Current.user.filters.from_params filter_params
      end
    end

    def set_user_filtering
      @user_filtering = User::Filtering.new(Current.user, @filter, expanded: expanded_param)
    end
end
```

**Usage in controllers:**

```ruby
class CardsController < ApplicationController
  include FilterScoped  # ← Sets @user_filtering automatically

  def index
    # @user_filtering is available
  end
end
```

#### Pattern 2: Factory Methods on Models

For presenters tied to a specific model, add a factory method:

**File**: `app/models/event.rb`

```ruby
class Event < ApplicationRecord
  def description_for(user)
    Event::Description.new(self, user)
  end
end
```

**Usage in views:**

```erb
<%= event.description_for(Current.user).to_html %>
```

This keeps the API discoverable and maintains the object-oriented style.

### View Usage

**With controller-instantiated presenter:**

```erb
<%# @user_filtering set by FilterScoped concern %>

<% if @user_filtering.show_tags? %>
  <div class="filter-tags">
    <% @user_filtering.tags.each do |tag| %>
      <%= render "tag", tag: tag %>
    <% end %>
  </div>
<% end %>

<% if @user_filtering.show_assignees? %>
  <!-- assignees UI -->
<% end %>
```

**With factory method:**

```erb
<% @events.each do |event| %>
  <div class="event-description">
    <%= event.description_for(Current.user).to_html %>
  </div>
<% end %>
```

**With fragment caching:**

```erb
<% cache @user_filtering.cache_key do %>
  <!-- expensive view rendering -->
<% end %>
```

### Testing Presenters

Test presenters like any Ruby class:

```ruby
require "test_helper"

class User::FilteringTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
    @user = users(:david)
    @filter = Filter.new
  end

  test "boards returns user's boards ordered by access" do
    filtering = User::Filtering.new(@user, @filter)

    assert_equal @user.boards.ordered_by_recently_accessed, filtering.boards
  end

  test "show_tags? returns false when no tags selected" do
    filtering = User::Filtering.new(@user, @filter)

    assert_not filtering.show_tags?
  end

  test "show_tags? returns true when tags present" do
    @filter.tags = [ tags(:bug) ]
    filtering = User::Filtering.new(@user, @filter)

    assert filtering.show_tags?
  end

  test "cache_key changes when filter changes" do
    filtering1 = User::Filtering.new(@user, @filter)
    key1 = filtering1.cache_key

    @filter.tags = [ tags(:bug) ]
    filtering2 = User::Filtering.new(@user, @filter)
    key2 = filtering2.cache_key

    assert_not_equal key1, key2
  end
end
```

For presenters that generate HTML:

```ruby
class Event::DescriptionTest < ActiveSupport::TestCase
  test "to_html includes creator name" do
    event = events(:card_closed)
    description = Event::Description.new(event, users(:david))

    assert_includes description.to_html, event.creator.name
  end

  test "to_plain_text is safe for notifications" do
    event = events(:card_closed)
    description = Event::Description.new(event, users(:david))

    # No HTML tags in plain text
    assert_no_match /<[^>]+>/, description.to_plain_text
  end
end
```

### Real Examples

| Presenter | File | Purpose |
|-----------|------|---------|
| `User::Filtering` | `app/models/user/filtering.rb` | Filter UI state and collections |
| `Event::Description` | `app/models/event/description.rb` | Event → human-readable text |
| `User::DayTimeline` | `app/models/user/day_timeline.rb` | Timeline organization |
| `User::DayTimeline::Column` | `app/models/user/day_timeline/column.rb` | Timeline column with HTML generation |

### Summary

Presenter pattern:
- **Plain Ruby classes** in `app/models/` (no special directory)
- **Domain-organized** (`User::Filtering`, not `FilteringPresenter`)
- **Include ActionView helpers** when generating HTML
- **Factory methods** on models for discoverable APIs
- **Controller concerns** for cross-controller instantiation
- **Memoization** for lazy-loaded collections
- **Boolean methods** for conditional display
- **Cache keys** for fragment caching

---

# Part 4: Controller & Job Patterns

Controllers and background jobs are extremely thin. They orchestrate, but delegate all business logic to models.

## 4.1 Thin Controllers with Rich Models

It strictly follows the "thin controller, fat model" philosophy. Controllers have 3 responsibilities: setup, call model, respond.

### The Pattern

**File**: `app/controllers/cards/goldnesses_controller.rb`

```ruby
class Cards::GoldnessesController < ApplicationController
  include CardScoped  # ← Sets @card and @board

  def create
    @card.gild  # ← Single line of business logic

    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :no_content }
    end
  end

  def destroy
    @card.ungild  # ← Single line of business logic

    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :no_content }
    end
  end
end
```

**That's the entire controller!**

### Controller Responsibilities

**Controllers should:**
1. Set instance variables from params (via concerns or before_action)
2. Call one model method
3. Render or redirect

**Controllers should NOT:**
- Contain business logic
- Build complex queries
- Orchestrate multi-step operations
- Directly manipulate multiple models

### Comparison: Before and After

**❌ Anti-pattern (business logic in controller):**

```ruby
def create
  @card = board.cards.find_by!(number: params[:card_id])

  unless @card.goldness.present?
    @goldness = @card.create_goldness!

    Event.create!(
      action: "card_gilded",
      eventable: @card,
      board: @card.board,
      account: @card.account,
      creator: Current.user
    )
  end

  respond_to do |format|
    format.turbo_stream { render_card_replacement }
  end
end
```

**✅ (model handles logic):**

```ruby
def create
  @card.gild  # Model method encapsulates all logic

  respond_to do |format|
    format.turbo_stream { render_card_replacement }
  end
end
```

**The model** (`app/models/card/golden.rb`):

```ruby
def gild
  create_goldness! unless golden?
  # Event tracking happens automatically via another concern
end
```

### Benefits

- **Testable**: Business logic tested at model level (fast)
- **Reusable**: Can call `card.gild` from console, jobs, tests
- **Maintainable**: Logic lives in one place
- **Readable**: Controller action is self-documenting

## 4.2 RESTful Resource Nesting

In models all actions as RESTful resources, not custom routes. This is a core pattern from the style guide.

### The Pattern

Instead of adding custom action methods, create a new resource:

**❌ Anti-pattern:**

```ruby
# routes.rb
resources :cards do
  post :close    # ← Custom action
  post :reopen   # ← Custom action
  post :gild     # ← Custom action
  post :ungild   # ← Custom action
end
```

**✅ pattern:**

```ruby
# routes.rb
resources :cards do
  scope module: :cards do
    resource :closure   # ← RESTful resource (singular!)
    resource :goldness  # ← RESTful resource
    # ...
  end
end
```

### Controller Implementation

**File**: `app/controllers/cards/closures_controller.rb`

```ruby
class Cards::ClosuresController < ApplicationController
  include CardScoped

  def create     # ← POST /cards/:card_id/closure
    @card.close
    respond_to do |format|
      format.turbo_stream { render_card_replacement }
    end
  end

  def destroy    # ← DELETE /cards/:card_id/closure
    @card.reopen
    respond_to do |format|
      format.turbo_stream { render_card_replacement }
    end
  end
end
```

**Routes generated:**
- `POST   /cards/:card_id/closure` → close card
- `DELETE /cards/:card_id/closure` → reopen card

### More Examples

**Gilding cards:**
```ruby
resource :goldness  # Cards::GoldnessesController
# POST   /cards/:card_id/goldness → gild
# DELETE /cards/:card_id/goldness → ungild
```

**Pinning cards:**
```ruby
resource :pin  # Cards::PinsController
# POST   /cards/:card_id/pin → pin
# DELETE /cards/:card_id/pin → unpin
```

**Watching cards:**
```ruby
resource :watch  # Cards::WatchesController
# POST   /cards/:card_id/watch → watch
# DELETE /cards/:card_id/watch → unwatch
```

### Benefits

- **RESTful conventions**: Standard HTTP verbs
- **Clear intent**: URL describes the resource
- **Testable**: Use standard REST helpers in tests
- **Framework alignment**: Follows Rails conventions

### When to Create a New Resource

**Ask**: "Is this action creating, updating, or destroying something?"

If yes, that "something" is probably a resource:
- Closing a card → Creates a `Closure`
- Gilding a card → Creates a `Goldness`
- Assigning a user → Creates an `Assignment`
- Posting a comment → Creates a `Comment`

## 4.3 Controller Concerns

Controller concerns extract common before_action patterns and resource loading.

### CardScoped Concern

**File**: `app/controllers/concerns/card_scoped.rb`

```ruby
module CardScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_card, :set_board
  end

  private
    def set_card
      @card = Current.user.accessible_cards.find_by!(number: params[:card_id])
    end

    def set_board
      @board = @card.board
    end

    def render_card_replacement
      render turbo_stream: turbo_stream.replace(
        [ @card, :card_container ],
        partial: "cards/container",
        method: :morph,
        locals: { card: @card.reload }
      )
    end
end
```

**Used by all nested card controllers:**
- `Cards::ClosuresController`
- `Cards::GoldnessesController`
- `Cards::AssignmentsController`
- `Cards::CommentsController`
- etc.

**Each controller just:**
```ruby
class Cards::GoldnessesController < ApplicationController
  include CardScoped  # ← Sets @card and @board automatically

  def create
    @card.gild
    respond_to do |format|
      format.turbo_stream { render_card_replacement }
    end
  end
end
```

### BoardScoped Concern

**File**: `app/controllers/concerns/board_scoped.rb`

```ruby
module BoardScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_board
  end

  private
    def set_board
      @board = Current.user.boards.find(params[:board_id])
    end

    def ensure_permission_to_admin_board
      unless Current.user.can_administer_board?(@board)
        head :forbidden
      end
    end
end
```

### When to Create Controller Concerns

**Create a controller concern when:**
- 3+ controllers need the same before_action
- Resource loading logic is repeated
- Authorization checks are duplicated

**Don't create when:**
- Logic is unique to one controller
- It's just one simple before_action
- The abstraction doesn't simplify code

## 4.4 Background Jobs: The _now/_later Pattern

It has a strict naming convention for asynchronous operations. Jobs are ultra-thin and delegate everything to models.

### The Pattern

For every async operation:
1. **Synchronous method**: `method_name` (or `method_now` if ambiguous)
2. **Async wrapper**: `method_later`
3. **Job class**: Calls the synchronous method

### Complete Example

**File**: `app/models/concerns/notifiable.rb`

```ruby
module Notifiable
  extend ActiveSupport::Concern

  included do
    has_many :notifications, as: :source, dependent: :destroy
    after_create_commit :notify_recipients_later  # ← Trigger async
  end

  def notify_recipients  # ← Synchronous version
    Notifier.for(self)&.notify
  end

  private
    def notify_recipients_later  # ← Async wrapper
      NotifyRecipientsJob.perform_later self
    end
end
```

**File**: `app/jobs/notify_recipients_job.rb`

```ruby
class NotifyRecipientsJob < ApplicationJob
  def perform(notifiable)
    notifiable.notify_recipients  # ← Calls synchronous method
  end
end
```

**Flow:**
1. Record created
2. `after_create_commit` → `notify_recipients_later`
3. Enqueues `NotifyRecipientsJob`
4. Job executes → calls `notify_recipients`
5. All logic in model method

### Why This Pattern?

**Clear which version is async:**
```ruby
record.notify_recipients        # Synchronous
record.notify_recipients_later  # Async (enqueues job)
```

**Logic tested via synchronous method:**
```ruby
# Test the logic (fast)
test "notify_recipients sends to watchers" do
  comment.notify_recipients
  assert_equal 2, Notification.count
end

# Test the job (integration)
test "notify_recipients_later enqueues job" do
  assert_enqueued_with(job: NotifyRecipientsJob) do
    comment.save!
  end
end
```

**Can call from different contexts:**
```ruby
# In a callback:
after_create_commit :notify_recipients_later

# Synchronously in console:
comment.notify_recipients

# Manually queue a job:
comment.notify_recipients_later
```

### Ultra-Thin Jobs

Jobs should be 3-6 lines:

**File**: `app/jobs/webhook/delivery_job.rb`

```ruby
class Webhook::DeliveryJob < ApplicationJob
  queue_as :webhooks

  def perform(delivery)
    delivery.deliver  # ← That's it!
  end
end
```

**File**: `app/jobs/export_account_data_job.rb`

```ruby
class ExportAccountDataJob < ApplicationJob
  queue_as :backend

  def perform(export)
    export.build  # ← All logic in model
  end
end
```

### Common Mistake

**❌ Don't put logic in jobs:**

```ruby
class NotifyRecipientsJob < ApplicationJob
  def perform(comment)
    # ← 50 lines of notification logic here
    # ← Hard to test
    # ← Can't call synchronously
  end
end
```

**✅ Put logic in models:**

```ruby
class NotifyRecipientsJob < ApplicationJob
  def perform(comment)
    comment.notify_recipients  # ← Logic in model
  end
end
```

## 4.5 Multi-Tenancy in Background Jobs

Background jobs automatically capture and restore the current account context. You never need to manually pass `account` to jobs.

### The Problem

Jobs run outside HTTP requests:
- No `Current.account` set automatically
- Need to restore tenant context for queries
- Easy to forget and cause bugs

### Solution

**File**: `config/initializers/active_job.rb`

```ruby
module AppActiveJobExtensions
  extend ActiveSupport::Concern

  prepended do
    attr_reader :account
    self.enqueue_after_transaction_commit = true
  end

  def initialize(...)
    super
    @account = Current.account  # ← Capture on creation
  end

  def serialize
    super.merge({ "account" => @account&.to_gid })  # ← Serialize
  end

  def deserialize(job_data)
    super
    if _account = job_data.fetch("account", nil)
      @account = GlobalID::Locator.locate(_account)  # ← Deserialize
    end
  end

  def perform_now
    if account.present?
      Current.with_account(account) { super }  # ← Restore context
    else
      super
    end
  end
end

ActiveSupport.on_load(:active_job) do
  prepend AppActiveJobExtensions  # ← Applied to ALL jobs
end
```

### How It Works

**1. Job Creation (in request):**
```ruby
# Current.account is set (from URL)
NotifyRecipientsJob.perform_later(comment)

# Behind the scenes:
# job = NotifyRecipientsJob.new(comment)
# job.initialize → @account = Current.account (captures it!)
```

**2. Job Serialization:**
```ruby
# Job serialized to queue:
{
  "job_class" => "NotifyRecipientsJob",
  "arguments" => [...],
  "account" => "gid://fizzy/Account/abc123..."  # ← Account included
}
```

**3. Job Execution (in worker):**
```ruby
# Job deserialized:
# @account = GlobalID::Locator.locate("gid://fizzy/Account/abc123...")

# Job runs:
# Current.with_account(@account) do
#   perform(comment)  # ← Current.account is set!
# end
```

### Practical Implications

**You never pass account manually:**

```ruby
# ❌ Don't do this:
SomeJob.perform_later(record, account: Current.account)

# ✅ Do this:
SomeJob.perform_later(record)
# Account captured automatically!
```

**Queries in jobs just work:**

```ruby
class NotifyRecipientsJob < ApplicationJob
  def perform(comment)
    # This works because Current.account is set:
    comment.card.watchers.each do |user|
      # All queries properly scoped to account
      Notification.create!(user: user, source: comment)
    end
  end
end
```

**Tests work automatically:**

```ruby
setup do
  Current.session = sessions(:david)  # Sets Current.account
end

test "job processes in correct account" do
  perform_enqueued_jobs do
    comment.notify_recipients_later
  end

  # Job ran with correct Current.account
  assert_equal 2, Current.account.notifications.count
end
```

### Key Insight

Multi-tenancy "just works" in jobs without thinking about it. This is one of the most powerful patterns.

---

# Part 5: Coding Style Guide

It has specific code style conventions beyond standard Ruby/Rails style.

## 5.1 Coding Conventions

### Conditional Returns (Expanded Conditionals Preferred)

It prefers expanded conditionals over guard clauses:

**❌ Avoid:**

```ruby
def todos_for_new_group
  ids = params.require(:todolist)[:todo_ids]
  return [] unless ids  # ← Guard clause
  @bucket.recordings.todos.find(ids.split(","))
end
```

**✅ Prefer:**

```ruby
def todos_for_new_group
  if ids = params.require(:todolist)[:todo_ids]
    @bucket.recordings.todos.find(ids.split(","))
  else
    []
  end
end
```

**Why?** Guard clauses can be hard to read, especially when nested.

**Exception**: Use guard clauses at the beginning of methods when:
- The return is right at the start
- The main body is non-trivial (many lines)
- It improves readability

```ruby
def after_recorded_as_commit(recording)
  return if recording.parent.was_created?  # ← OK: at start, non-trivial body

  if recording.was_created?
    broadcast_new_column(recording)
  else
    broadcast_column_change(recording)
  end
end
```

### Method Ordering

Methods are ordered in classes:

1. `class` methods (at top)
2. `public` methods (`initialize` first if present)
3. `private` methods

```ruby
class SomeClass
  # 1. Class methods
  class << self
    def create_with_owner(attrs)
      # ...
    end
  end

  # 2. Public methods
  def initialize(attrs)
    # ...
  end

  def some_public_method
    # ...
  end

  # 3. Private methods
  private
    def some_private_method
      # ...
    end
end
```

### Invocation Order (Private Methods)

Private methods are ordered vertically by their invocation order:

```ruby
class SomeClass
  def some_method
    method_1
    method_2
  end

  private
    def method_1
      method_1_1
      method_1_2
    end

    def method_1_1  # ← Called from method_1
      # ...
    end

    def method_1_2  # ← Called from method_1
      # ...
    end

    def method_2    # ← Called from some_method (after method_1)
      method_2_1
      method_2_2
    end

    def method_2_1  # ← Called from method_2
      # ...
    end

    def method_2_2  # ← Called from method_2
      # ...
    end
end
```

This makes it easy to read code top-to-bottom following the execution flow.

### Visibility Modifiers

Don't add a newline under visibility modifiers. Indent content under them:

```ruby
class SomeClass
  def some_method
    # ...
  end

  private  # ← No newline after
    def some_private_method_1  # ← Indented
      # ...
    end

    def some_private_method_2  # ← Indented
      # ...
    end
end
```

**Exception**: For modules with only private methods, mark `private` at top with extra newline, but don't indent:

```ruby
module SomeModule
  private  # ← At top
  # ← Extra newline
  def some_private_method  # ← Not indented
    # ...
  end
end
```

### Bang Method Naming

Only use `!` for methods that have a non-bang counterpart:

**✅ Good:**

```ruby
def save    # ← Returns false on failure
def save!   # ← Raises on failure (has counterpart)

def update(attrs)
def update!(attrs)
```

**❌ Avoid:**

```ruby
def destroy!  # ← No non-bang counterpart? Don't use !
def process!  # ← Not signaling danger vs non-bang version
```

**Don't use `!` to flag destructive actions**. Many destructive methods in Ruby/Rails don't have `!`.

---

# Part 6: Common Tasks & Recipes

Step-by-step guides for common development tasks.

## 6.1 Recipe: Adding a New State to Cards

Let's say you want to add an "archived" state to cards. Here's the full pattern:

### Step 1: Create the State Model

```ruby
# app/models/card/archive.rb
class Card::Archive < ApplicationRecord
  self.table_name = "card_archives"

  belongs_to :card
  belongs_to :user
  belongs_to :account, default: -> { card.account }
end
```

**Migration:**

```ruby
class CreateCardArchives < ActiveRecord::Migration[7.1]
  def change
    create_table :card_archives, id: :uuid do |t|
      t.references :card, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.timestamps
    end
  end
end
```

### Step 2: Create the Concern

```ruby
# app/models/card/archivable.rb
module Card::Archivable
  extend ActiveSupport::Concern

  included do
    has_one :archive, dependent: :destroy

    scope :archived, -> { joins(:archive) }
    scope :unarchived, -> { where.missing(:archive) }
  end

  def archived?
    archive.present?
  end

  def unarchived?
    !archived?
  end

  def archived_by
    archive&.user
  end

  def archived_at
    archive&.created_at
  end

  def archive(user: Current.user)
    unless archived?
      transaction do
        create_archive! user: user
        track_event :archived, creator: user
      end
    end
  end

  def unarchive(user: Current.user)
    if archived?
      transaction do
        archive.destroy
        track_event :unarchived, creator: user
      end
    end
  end
end
```

### Step 3: Include in Card Model

```ruby
# app/models/card.rb
class Card < ApplicationRecord
  include Assignable, Archivable, Attachments, Broadcastable, Closeable, ...
  #                   └─ Add here
```

### Step 4: Create the Controller

```ruby
# app/controllers/cards/archives_controller.rb
class Cards::ArchivesController < ApplicationController
  include CardScoped

  def create
    @card.archive

    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :no_content }
    end
  end

  def destroy
    @card.unarchive

    respond_to do |format|
      format.turbo_stream { render_card_replacement }
      format.json { head :no_content }
    end
  end
end
```

### Step 5: Add Routes

```ruby
# config/routes.rb
resources :cards do
  scope module: :cards do
    resource :archive  # ← Add this
    # ...
  end
end
```

### Step 6: Add Tests

```ruby
# test/models/card/archivable_test.rb
require "test_helper"

class Card::ArchivableTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
  end

  test "archive creates archive record and event" do
    card = cards(:logo)

    assert_difference -> { Card::Archive.count }, +1 do
      assert_difference -> { Event.count }, +1 do
        card.archive
      end
    end

    assert card.archived?
    assert_equal "card_archived", Event.last.action
  end

  test "unarchive removes archive record" do
    card = cards(:logo)
    card.archive

    assert_difference -> { Card::Archive.count }, -1 do
      card.unarchive
    end

    assert card.unarchived?
  end

  test "archived scope" do
    card = cards(:logo)
    card.archive

    assert_includes Card.archived, card
    assert_not_includes Card.unarchived, card
  end
end
```

### Step 7: Update Views

Add UI elements to trigger archive/unarchive.

## 6.2 Recipe: Adding Event Tracking

Add event tracking to any model action:

### Step 1: Ensure Eventable is Included

```ruby
class Card < ApplicationRecord
  include Eventable, ...  # ← Already included
```

### Step 2: Add track_event Call

```ruby
def some_action(user: Current.user)
  transaction do
    # ... state changes ...

    track_event :action_name, creator: user  # ← Add this
  end
end
```

### Step 3: Add Particulars for Context

If you need to store additional data:

```ruby
def move_to(new_board)
  old_board_name = board.name

  transaction do
    update!(board: new_board)
    track_event :board_changed,
      particulars: {
        old_board: old_board_name,
        new_board: new_board.name
      }
  end
end
```

### Step 4: Test Event Creation

```ruby
test "moving boards creates event with particulars" do
  card = cards(:logo)
  old_board = card.board
  new_board = boards(:other)

  assert_difference -> { Event.count }, +1 do
    card.move_to(new_board)
  end

  event = Event.last
  assert_equal "card_board_changed", event.action
  assert_equal old_board.name, event.particulars["old_board"]
  assert_equal new_board.name, event.particulars["new_board"]
end
```

## 6.3 Recipe: Creating Background Jobs

Follow the _now/_later pattern:

### Step 1: Create Synchronous Method

```ruby
# app/models/some_model.rb
def process_data
  # All the logic here
  some_complex_operation
  update_related_records
  send_notifications
end
```

### Step 2: Create Async Wrapper

```ruby
def process_data_later
  ProcessDataJob.perform_later(self)
end
```

### Step 3: Create Job

```ruby
# app/jobs/process_data_job.rb
class ProcessDataJob < ApplicationJob
  queue_as :backend

  def perform(record)
    record.process_data  # ← Calls synchronous method
  end
end
```

### Step 4: Add Callback (if needed)

```ruby
after_create_commit :process_data_later
```

### Step 5: Test Both Versions

```ruby
# Test synchronous logic
test "process_data updates records" do
  record.process_data
  assert record.processed?
end

# Test async wrapper
test "process_data_later enqueues job" do
  assert_enqueued_with(job: ProcessDataJob, args: [record]) do
    record.process_data_later
  end
end
```

---

# Part 7: Quick Reference

## 7.1 Concern Catalog

### Shared Concerns (`app/models/concerns/`)

| Concern | Purpose | Key Methods |
|---------|---------|-------------|
| `Eventable` | Track events for actions | `track_event(action, **particulars)` |
| `Notifiable` | Send notifications | `notify_recipients`, `notify_recipients_later` |
| `Searchable` | Index for full-text search | `reindex`, creates search records on save |
| `Attachments` | Support for file attachments | ActiveStorage integration |
| `Mentions` | Scan and create @mentions | `create_mentions`, scans on save |
| `Storage::Tracked` | Track storage usage | Automatic tracking on attachment changes |
| `Storage::Totaled` | Materialized storage totals | `bytes_used`, `bytes_used_exact` |

### Card-Specific Concerns (`app/models/card/`)

| Concern | Purpose | Key Methods |
|---------|---------|-------------|
| `Assignable` | Assign users to cards | `assign(user)`, `unassign(user)` |
| `Closeable` | Close/reopen cards | `close`, `reopen`, `closed?`, `open?` |
| `Golden` | Mark cards as golden | `gild`, `ungild`, `golden?` |
| `Postponable` | Postpone to "not now" | `postpone`, `resume`, `auto_postpone` |
| `Entropic` | Auto-postpone stale cards | `entropic?`, scope: `due_to_be_postponed` |
| `Triageable` | Move through triage workflow | `triage_into(column)`, `send_back_to_triage` |
| `Watchable` | Watch/unwatch cards | `watch`, `unwatch`, `watched_by?(user)` |
| `Eventable` | Card-specific event logic | Overrides from base `Eventable` |

### Board-Specific Concerns (`app/models/board/`)

| Concern | Purpose | Key Methods |
|---------|---------|-------------|
| `Accessible` | Board access control | `accessible_to?(user)`, `accesses.grant_to(users)` |
| `Storage` | Calculate board storage | `storage_used`, `storage_limit` |

## 7.2 Decision Trees

### "Where Does This Code Belong?"

```
Is it business logic that changes data or makes decisions?
│
├─ YES
│  │
│  └─ Is it used by multiple controllers OR console OR jobs?
│     │
│     ├─ YES → Put in MODEL
│     │
│     └─ NO → Still put in MODEL (keeps controller thin)
│
└─ NO
   │
   └─ Is it about HTTP (params, rendering, redirects)?
      │
      ├─ YES → Put in CONTROLLER
      │
      └─ NO → Is it about background execution?
             │
             ├─ YES → Create JOB (but logic goes in MODEL)
             │
             └─ NO → Is it a utility/helper?
                    │
                    └─ YES → Put in lib/ or helper/
```

### "Should I Create a Concern?"

```
Is the behavior needed by multiple models?
│
├─ YES
│  │
│  └─ Are they related models (same hierarchy)?
│     │
│     ├─ YES → Model-specific concern (Card::Something)
│     │
│     └─ NO → Shared concern (Somethingable)
│
└─ NO
   │
   └─ Is it 50+ lines of cohesive behavior?
      │
      ├─ YES → Model-specific concern (Card::Something)
      │
      └─ NO → Keep in model (don't over-extract)
```

### "Is This a New Resource or Custom Action?"

```
Does this action create, update, or destroy something?
│
├─ YES
│  │
│  └─ What is that "something"?
│     │
│     └─ That's your resource!
│        │
│        Examples:
│        - Closing card → Creates "Closure" resource
│        - Gilding card → Creates "Goldness" resource
│        - Assigning user → Creates "Assignment" resource
│
└─ NO → Maybe it's actually creating/destroying something?
         Look harder. Most actions fit the resource pattern.
```

## 7.3 Common Gotchas

### 1. Forgetting Current.session in Model Tests

**Problem:**

```ruby
test "creating card" do
  card = Card.create!(board: boards(:writebook), title: "Test")
  # Error: Current.user is nil!
end
```

**Solution:**

```ruby
test "creating card" do
  Current.session = sessions(:david)  # ← Add this!
  card = Card.create!(board: boards(:writebook), title: "Test")
end
```

**Why:** Lambda defaults like `default: -> { Current.user }` need `Current.session` set.

### 2. Adding Business Logic to Controllers

**Problem:**

```ruby
def create
  @card = board.cards.create!(...)
  @card.events.create!(...)
  @card.comments.create!(...)
  # ... 10 more lines
end
```

**Solution:**

```ruby
def create
  @card = board.cards.create_with_initial_comment!(...)  # ← Model method
end
```

Put logic in models, not controllers.

### 3. Creating Custom Actions Instead of Resources

**Problem:**

```ruby
resources :cards do
  post :close  # ← Anti-pattern
end
```

**Solution:**

```ruby
resources :cards do
  resource :closure  
end
```

Model actions as resources.

### 4. Putting Logic in Jobs Instead of Models

**Problem:**

```ruby
class ProcessJob < ApplicationJob
  def perform(record)
    # 50 lines of business logic here
  end
end
```

**Solution:**

```ruby
class ProcessJob < ApplicationJob
  def perform(record)
    record.process  # ← Logic in model
  end
end
```

Jobs should be thin wrappers.

### 5. Breaking Association Declaration Order

**Problem:**

```ruby
belongs_to :account, default: -> { board.account }  # ← Error!
belongs_to :board  # ← board not declared yet above
```

**Solution:**

```ruby
belongs_to :board                                    # ← Declare first
belongs_to :account, default: -> { board.account }  # ← Use after
```

Declare associations before using them in defaults.

### 6. Using .find for Cards in Controllers

**Problem:**

```ruby
@card = Card.find(params[:id])  # ← Wrong! Cards use :number
```

**Solution:**

```ruby
@card = Current.user.accessible_cards.find_by!(number: params[:id])
```

Cards use `number` for user-facing IDs, not `id`.

### 7. Not Using Transactions for Multi-Step Operations

**Problem:**

```ruby
def close
  create_closure!
  track_event :closed  # ← If this fails, closure exists but no event
end
```

**Solution:**

```ruby
def close
  transaction do
    create_closure!
    track_event :closed
  end
end
```

Wrap related operations in transactions.

---

# Conclusion

This documentation covers the core patterns and practices used throughout the Rails application:

- **Foundation**: Multi-tenancy via Current context, UUID primary keys
- **Models**: Concern-driven architecture, intention-revealing APIs, smart defaults
- **Controllers**: Thin controllers that delegate to rich models
- **Jobs**: Ultra-thin jobs following _now/_later pattern
- **Style**: specific conventions for readable code

The key principle underlying all patterns: **business logic belongs in models, and everything else orchestrates that logic as simply as possible.**

For more details, explore the actual code files referenced throughout this document. The patterns are consistent, so once you understand them, you can navigate the entire codebase confidently.

---

**Document Version**: 1.1
**Last Updated**: 2026-02-14
**Maintainer**: Development Team
