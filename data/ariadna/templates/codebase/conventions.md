# Coding Conventions Template

Template for `.planning/codebase/CONVENTIONS.md` - captures coding style and patterns.

**Purpose:** Document how code is written in this codebase. Prescriptive guide for Claude to match existing style.

---

## File Template

```markdown
# Coding Conventions

**Analysis Date:** [YYYY-MM-DD]

## Naming Patterns

**Files:**
- [Pattern: e.g., "snake_case for all Ruby files"]
- [Test files: e.g., "`*_test.rb` in `test/` mirroring `app/` structure"]
- [Controllers: e.g., "`users_controller.rb`, plural resource name"]
- [Models: e.g., "`user.rb`, singular"]
- [Concerns: e.g., "`closeable.rb` for shared, `card/closeable.rb` for model-specific"]

**Methods:**
- [Pattern: e.g., "snake_case for all methods"]
- [Booleans: e.g., "`?` suffix — `active?`, `closed?`, `can_edit?`"]
- [Bang: e.g., "`!` only when a non-bang counterpart exists — `save!`/`save`"]
- [Actions: e.g., "imperative verbs — `close`, `gild`, `postpone`"]

**Variables:**
- [Pattern: e.g., "snake_case for locals and parameters"]
- [Instance: e.g., "`@board`, `@card` — set in `before_action`"]
- [Constants: e.g., "`SCREAMING_SNAKE_CASE` — `MAX_RETRIES`, `DEFAULT_LIMIT`"]
- [Class variables: e.g., "`@@class_var` — rarely used, prefer class-level accessors"]

**Classes & Modules:**
- [Classes: e.g., "PascalCase — `User`, `CardPolicy`, `ApplicationController`"]
- [Modules: e.g., "PascalCase — `Eventable`, `Card::Closeable`"]
- [Namespacing: e.g., "`Card::Closeable` maps to `app/models/card/closeable.rb`"]

## Code Style

**Formatting:**
- [Tool: e.g., "RuboCop with `.rubocop.yml`"]
- [Pragma: e.g., "`# frozen_string_literal: true` at top of every file"]
- [Line length: e.g., "120 characters max"]
- [Quotes: e.g., "double quotes for strings"]
- [Indentation: e.g., "2-space indentation, no tabs"]

**Linting:**
- [Tool: e.g., "RuboCop"]
- [Config: e.g., "`.rubocop.yml` with project-specific overrides"]
- [Run: e.g., "`bundle exec rubocop` / `bundle exec rubocop -a`"]

## Require & Include Organization

**Require Order:**
1. [e.g., "Standard library (`require 'json'`, `require 'net/http'`)"]
2. [e.g., "Gem requires (`require 'nokogiri'`)"]
3. [e.g., "Application requires (`require_relative '../lib/parser'`)"]

**Include/Extend Order in Models:**
- [e.g., "`include` for concerns — listed alphabetically on one line"]
- [e.g., "`extend` for class-level modules"]
- [e.g., "Concern declaration: `extend ActiveSupport::Concern` as first line"]

**Concern Declaration:**
- [e.g., "`extend ActiveSupport::Concern` + `included do` block"]
- [e.g., "Associations, scopes, callbacks inside `included do`"]
- [e.g., "Instance methods below the `included` block"]

## Error Handling

**Patterns:**
- [Strategy: e.g., "`rescue_from` in controllers, `begin/rescue` in methods"]
- [Custom errors: e.g., "inherit `StandardError`, named `*Error`"]
- [Model validation: e.g., "re-render form with `@model.errors`"]

**Error Types:**
- [When to raise: e.g., "invalid input, authorization failures, missing records"]
- [When to return: e.g., "expected failures return `false` or `nil`"]
- [Jobs: e.g., "`retry_on` for transient, `discard_on` for permanent failures"]

## Logging

**Framework:**
- [Tool: e.g., "`Rails.logger`"]
- [Levels: e.g., "debug, info, warn, error, fatal"]

**Patterns:**
- [Format: e.g., "tagged logging with request ID and user context"]
- [Request logs: e.g., "Lograge for structured single-line request logs"]
- [When: e.g., "log external API calls, state transitions, errors"]

## Comments

**When to Comment:**
- [e.g., "explain why, not what"]
- [e.g., "document business rules and edge cases"]
- [e.g., "avoid obvious comments"]

**Documentation:**
- [Pragma: e.g., "`# frozen_string_literal: true` — required first line"]
- [YARD: e.g., "`@param`, `@return` if YARD is used, optional otherwise"]
- [TODO: e.g., "`# TODO:` format, link to issue if available"]

## Method Design

**Size:**
- [e.g., "max ~30 lines per method (RuboCop enforced)"]
- [e.g., "extract private helpers for complex logic"]

**Parameters:**
- [e.g., "keyword arguments for clarity: `def create(name:, email:)`"]
- [e.g., "default to `Current` context: `def close(user: Current.user)`"]

**Return Values:**
- [e.g., "guard clauses for early returns at method start"]
- [e.g., "expanded conditionals preferred over guard clauses mid-method"]
- [e.g., "implicit return of last expression"]

**Visibility:**
- [e.g., "public methods first, then `private` keyword, then private methods"]
- [e.g., "private methods indented under `private`, no blank line after keyword"]
- [e.g., "private methods ordered by invocation order"]

## Module & Concern Design

**Concerns:**
- [Shared: e.g., "adjective names — `Eventable`, `Searchable`, `Notifiable`"]
- [Model-specific: e.g., "namespaced — `Card::Closeable`, `Board::Accessible`"]
- [Pattern: e.g., "`ActiveSupport::Concern` with `included do` block"]

**Plain Ruby Objects:**
- [e.g., "semantic names — `Signup`, `Notifier`, not `SignupService`"]
- [e.g., "concerns delegate complex logic to dedicated objects"]

---

*Convention analysis: [date]*
*Update when patterns change*
```

<good_examples>
```markdown
# Coding Conventions

**Analysis Date:** 2025-01-20

## Naming Patterns

**Files:**
- snake_case for all Ruby files (`user.rb`, `users_controller.rb`, `card_policy.rb`)
- `*_test.rb` in `test/` mirroring `app/` structure (`test/models/card_test.rb`)
- Controllers: plural resource name + `_controller.rb` (`boards_controller.rb`)
- Models: singular (`card.rb`, `event.rb`)
- Concerns: adjective for shared (`eventable.rb`), namespaced for model-specific (`card/closeable.rb`)
- Jobs: descriptive + `_job.rb` (`notify_recipients_job.rb`)
- Mailers: descriptive + `_mailer.rb` (`invitation_mailer.rb`)

**Methods:**
- snake_case for all methods
- `?` suffix for boolean queries — `closed?`, `open?`, `golden?`, `can_edit?`
- `!` suffix only when a non-bang counterpart exists — `save!`/`save`, `update!`/`update`
- Imperative verbs for actions — `close`, `reopen`, `gild`, `ungild`, `postpone`, `archive`
- No generic names — `close` not `process`, `gild` not `handle`
- Boolean pairs — always provide both: `closed?`/`open?`, `golden?`/`not_golden?`

**Variables:**
- snake_case for locals and parameters (`board_name`, `card_count`)
- `@instance_vars` set in `before_action` callbacks (`@board`, `@card`)
- `SCREAMING_SNAKE_CASE` for constants (`MAX_RETRIES`, `DEFAULT_PAGE_SIZE`)
- No Hungarian notation, no type prefixes

**Classes & Modules:**
- PascalCase for classes (`User`, `CardPolicy`, `ApplicationController`)
- PascalCase for modules (`Eventable`, `Card::Closeable`, `Board::Accessible`)
- Namespace maps to directory: `Card::Closeable` lives at `app/models/card/closeable.rb`

## Code Style

**Formatting:**
- RuboCop with `.rubocop.yml`
- `# frozen_string_literal: true` as first line of every `.rb` file
- Double quotes for strings
- 120 character line length
- 2-space indentation, no tabs
- No trailing whitespace
- Newline at end of file

**Linting:**
- RuboCop with project `.rubocop.yml`
- Method length max ~30 lines (RuboCop `Metrics/MethodLength`)
- ABC size max ~30 (RuboCop `Metrics/AbcSize`)
- Run: `bundle exec rubocop`
- Auto-fix: `bundle exec rubocop -a`

## Require & Include Organization

**Require Order (in non-Rails files like gems and scripts):**
1. Standard library (`require "json"`, `require "net/http"`)
2. Gem requires (`require "nokogiri"`)
3. Application requires (`require_relative "../lib/parser"`)

**Include Order in Models:**
- Concerns listed alphabetically on one line, wrapped if long:
  ```ruby
  include Assignable, Attachments, Closeable, Eventable, Golden,
    Mentions, Postponable, Searchable, Taggable, Watchable
  ```
- `extend` for class-level modules (rare)

**Concern Declaration:**
- `extend ActiveSupport::Concern` as first line
- `included do` block for associations, scopes, callbacks
- Instance methods below the `included` block
- Private methods at the bottom under `private`

```ruby
module Card::Closeable
  extend ActiveSupport::Concern

  included do
    has_one :closure, dependent: :destroy
    scope :closed, -> { joins(:closure) }
    scope :open, -> { where.missing(:closure) }
  end

  def closed?
    closure.present?
  end

  def close(user: Current.user)
    # ...
  end

  private
    def track_closure_event(user)
      # ...
    end
end
```

## Error Handling

**Patterns:**
- `rescue_from` in `ApplicationController` for cross-cutting error handling
- `begin/rescue/ensure` blocks in methods for specific recovery
- Custom error classes inherit `StandardError`
- Model validation errors re-render form with `@model.errors`

**Error Types:**
- Raise on authorization failures: `rescue_from Pundit::NotAuthorizedError`
- Raise on missing records: `rescue_from ActiveRecord::RecordNotFound`
- Return `false`/`nil` for expected domain failures
- Jobs: `retry_on` for transient failures (network, timeouts), `discard_on ActiveRecord::RecordNotFound`

**Custom Errors:**
```ruby
class InsufficientStorageError < StandardError; end
class AccountSuspendedError < StandardError; end
```

## Logging

**Framework:**
- `Rails.logger` — standard Rails logger
- Levels: debug, info, warn, error, fatal

**Patterns:**
- Tagged logging with request context: `Rails.logger.tagged("ImportJob") { logger.info "..." }`
- Lograge for structured single-line request logs
- Log external API calls, state transitions, unexpected conditions
- No `puts` or `p` in committed code

## Comments

**When to Comment:**
- Explain why, not what: `# Retry because API has transient 503 errors`
- Document business rules: `# Users must verify email within 24 hours`
- Explain non-obvious workarounds or edge cases
- Avoid obvious comments: `# Close the card` above `card.close`

**Pragmas & Documentation:**
- `# frozen_string_literal: true` — required first line, every file
- YARD docs (`@param`, `@return`) if the project uses YARD, optional otherwise
- `# TODO:` format with description, link to issue if exists

## Method Design

**Size:**
- Max ~30 lines per method (RuboCop enforced)
- Extract private helpers for complex logic
- One level of abstraction per method

**Parameters:**
- Keyword arguments for clarity: `def close(user: Current.user)`
- Default to `Current` context where appropriate
- Max 3-4 parameters; use keyword arguments for more

**Return Values:**
- Guard clauses only at method start for non-trivial bodies
- Expanded conditionals preferred over mid-method guard clauses:
  ```ruby
  # Preferred
  def todos_for_group
    if ids = params.require(:todolist)[:todo_ids]
      @bucket.recordings.todos.find(ids.split(","))
    else
      []
    end
  end
  ```
- Implicit return of last expression (no explicit `return` at end)

**Method Ordering:**
1. Class methods (`class << self`)
2. Public instance methods (`initialize` first if present)
3. `private` keyword (no blank line after)
4. Private methods (indented, ordered by invocation order)

```ruby
class Board
  class << self
    def default_for(account)
      # ...
    end
  end

  def archive
    # ...
  end

  private
    def notify_members
      # ...
    end

    def track_archive_event
      # ...
    end
end
```

**Visibility Modifier Style:**
- No blank line after `private` keyword
- Private methods indented one level under `private`
- Private methods ordered by invocation order (read top-to-bottom)

## Module & Concern Design

**Shared Concerns:**
- Adjective names for cross-cutting behavior: `Eventable`, `Searchable`, `Notifiable`, `Attachments`
- Located in `app/models/concerns/`
- Reusable across 3+ unrelated models

**Model-Specific Concerns:**
- Namespaced names for domain behavior: `Card::Closeable`, `Card::Golden`, `Board::Accessible`
- Located in model subdirectories: `app/models/card/`, `app/models/board/`
- Extract when 50+ lines of cohesive behavior

**Concern Anatomy:**
- `extend ActiveSupport::Concern` first line
- `included do` block: associations, scopes, callbacks
- Public API methods: intention-revealing names
- Template method pattern for override points (`should_track_event?`, `eventable_prefix`)

**Plain Ruby Objects:**
- Semantic names: `Signup`, `Notifier`, `Detector` — not `SignupService`, `NotificationHandler`
- Concerns delegate complex logic to dedicated objects:
  ```
  Concern (framework integration)  -->  Plain Ruby Object (business logic)
  ```

**Intention-Revealing APIs:**
- Action methods use imperative verbs: `close`, `gild`, `postpone`, `archive`
- Not implementation-revealing: `close` not `create_closure_record`
- Boolean pairs always provided: `closed?`/`open?`, `golden?`
- Business-named scopes: `closed` not `with_closures`, `open` not `without_closures`

---

*Convention analysis: 2025-01-20*
*Update when patterns change*
```
</good_examples>

<guidelines>
**What belongs in CONVENTIONS.md:**
- Naming patterns for files, methods, variables, classes, and modules
- Code formatting rules (RuboCop config, line length, quotes, indentation)
- Require/include organization patterns
- Error handling strategy
- Logging approach
- Comment conventions
- Method design patterns (size, parameters, returns, ordering, visibility)
- Module and concern design patterns

**What does NOT belong here:**
- Architecture decisions (that's ARCHITECTURE.md)
- Technology choices and gem versions (that's STACK.md)
- Test patterns (that's TESTING.md)
- File organization (that's STRUCTURE.md)

**When filling this template:**
- Check `.rubocop.yml` for formatting rules, line length, method size limits
- Check `Gemfile` for linting gems (rubocop, standard, etc.)
- Examine 5-10 representative files in `app/models/`, `app/controllers/`, `app/models/concerns/`
- Look for consistency: if 80%+ follows a pattern, document it
- Be prescriptive: "Use X" not "Sometimes Y is used"
- Note deviations: "Legacy code uses Y, new code should use X"
- Keep under ~150 lines total

**Useful for phase planning when:**
- Writing new code (match existing style)
- Adding features (follow naming patterns — imperative verbs, boolean pairs, concern naming)
- Creating concerns (follow `ActiveSupport::Concern` anatomy, naming conventions)
- Refactoring (apply consistent conventions — method ordering, visibility style)
- Code review (check against documented patterns)
- Onboarding (understand style expectations)

**Analysis approach:**
- Read `.rubocop.yml` for enforced style rules (line length, method size, ABC size, quote style)
- Check `Gemfile` for `rubocop`, `standard`, or other linting gems
- Scan `app/models/` and `app/controllers/` for file naming patterns
- Read 2-3 model files to identify method naming, concern composition, and visibility style
- Read 2-3 concern files to identify concern anatomy (`included do` block, public API, private methods)
- Check `app/models/concerns/` for shared concern naming conventions (adjective names)
- Check for model-specific concern directories (`app/models/card/`, `app/models/board/`)
- Read a controller to identify error handling, parameter style, before_action patterns
- Note patterns in method ordering, visibility modifiers, conditional style
- Look for `# frozen_string_literal: true` pragma usage
</guidelines>
