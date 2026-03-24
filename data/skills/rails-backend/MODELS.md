# Rails Backend: Models

ActiveRecord patterns, concern architecture, associations, scoping, and callbacks.

---

## Concern Architecture

Concerns are the most distinctive pattern. Models compose behavior from focused modules.

**Shared concerns** (`app/models/concerns/`) — reusable across 3+ unrelated models, adjective naming: `Eventable`, `Notifiable`, `Searchable`, `Attachments`

**Model-specific concerns** (`app/models/card/`, `app/models/board/`) — namespaced, tightly coupled: `Card::Closeable`, `Card::Golden`, `Board::Accessible`

### Anatomy

```ruby
module Card::Closeable
  extend ActiveSupport::Concern  # Required first line

  included do
    has_one :closure, dependent: :destroy
    scope :closed, -> { joins(:closure) }
    scope :open,   -> { where.missing(:closure) }
  end

  def closed? = closure.present?
  def open?   = !closed?

  def close(user: Current.user)
    unless closed?
      transaction do
        create_closure! user: user
        track_event :closed, creator: user
      end
    end
  end

  private
    # Private helpers indented under private
end
```

### Concern Composition

```ruby
class Card < ApplicationRecord
  include Assignable, Attachments, Closeable, Eventable, Golden, Mentions,
    Notifiable, Postponable, Searchable, Storage::Tracked, Taggable, Watchable

  belongs_to :board
  belongs_to :account, default: -> { board.account }  # board declared first
  belongs_to :creator, class_name: "User", default: -> { Current.user }
end
```

### When to Create

- **Shared concern**: 3+ unrelated models, cross-cutting behavior (events, search, notifications)
- **Model-specific**: 50+ lines of cohesive behavior for one model feature
- **Don't create**: 1-2 simple methods, just grouping unrelated methods

### Template Method Pattern

Base concerns define override points; model-specific concerns customize them:

```ruby
module Eventable
  private
    def should_track_event? = true                                    # Override point
    def eventable_prefix = self.class.name.demodulize.underscore      # Override point
end

module Card::Eventable
  extend ActiveSupport::Concern
  include ::Eventable
  private
    def should_track_event? = published?   # Override: only track published cards
end
```

### Concerns Delegate Complexity to Plain Ruby Objects

```ruby
module Notifiable
  included do
    after_create_commit :notify_recipients_later
  end
  def notify_recipients = Notifier.for(self)&.notify  # Delegates to Notifier hierarchy
end
```

---

## Intention-Revealing APIs

Always provide both query forms, use imperative verbs, delegate for readability:

```ruby
def closed? = closure.present?    # Positive check
def open?   = !closed?            # Negative check

def close  /  def reopen          # not: set_closed / remove_closure
def gild   /  def ungild          # not: make_golden / remove_golden

def closed_by = closure&.user     # Delegates — not: closure&.user in callers
def closed_at = closure&.created_at
```

Multi-step operations: transactions wrap everything; async ops go outside:

```ruby
def close(user: Current.user)
  transaction do
    create_closure! user: user
    track_event :closed, creator: user  # Inside transaction
  end
end
```

---

## Smart Association Defaults

```ruby
belongs_to :board                                          # Declare before use
belongs_to :account, default: -> { board.account }        # Derives from parent
belongs_to :creator, class_name: "User", default: -> { Current.user }
# Card.create!(board:, title:) — account and creator set automatically
```

Use for `account` (multi-tenancy) and `creator`/`user` (from `Current.user`).

---

## Scopes That Tell Stories

Business names, not SQL names. Always use `-> { }` lambdas:

```ruby
scope :closed, -> { joins(:closure) }
scope :open,   -> { where.missing(:closure) }
scope :closed_by, ->(users) { closed.where(closures: { user_id: Array(users) }) }

# Conditional scope maps UI concepts — keeps conditionals out of controllers:
scope :indexed_by, ->(index) do
  case index
  when "closed" then closed
  when "golden" then golden
  else all
  end
end

# Named preloading scope — prevents N+1:
scope :preloaded, -> {
  preload(:column, :tags, :closure, :goldness, board: [:entropy, :columns])
    .with_rich_text_description_and_embeds
}
```

---

## Callbacks

**Use for:** required data on create, async triggers, touching associations.
**Don't use for:** business logic, complex orchestration, anything callers want to skip.

```ruby
before_create :assign_number                                        # Set required data
after_create_commit :notify_recipients_later                        # After commit (not after_create)
after_save   -> { board.touch }, if: :published?                    # Simple one-liners as lambdas
after_update :handle_board_change, if: :saved_change_to_board_id?  # Conditional
```

Use `_commit` variants for async jobs — prevents running for rolled-back records.

---

## Event Tracking

Call `track_event` inside transactions; auto-prefixed by model name:

```ruby
transaction do
  create_closure! user: user
  track_event :closed, creator: user   # Produces "card_closed"
end

transaction do
  update!(board: new_board)
  track_event "board_changed", particulars: { old_board: name_was, new_board: new_board.name }
end
```

---

## Concern Reference

| Shared | Key API |
|--------|---------|
| `Eventable` | `track_event(action, **particulars)` |
| `Notifiable` | `notify_recipients`, `notify_recipients_later` |
| `Searchable` | auto-indexes on save |
| `Storage::Tracked` | auto-tracks on attachment changes |

| Card | Key API |
|------|---------|
| `Card::Closeable` | `close`, `reopen`, `closed?`, `open?` |
| `Card::Golden` | `gild`, `ungild`, `golden?` |
| `Card::Assignable` | `assign(user)`, `unassign(user)` |
| `Card::Postponable` | `postpone`, `resume`, `auto_postpone` |
| `Card::Triageable` | `triage_into(column)`, `send_back_to_triage` |
| `Card::Watchable` | `watch`, `unwatch`, `watched_by?(user)` |
