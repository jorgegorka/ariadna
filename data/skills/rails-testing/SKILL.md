---
name: rails-testing
description: Ruby on Rails testing conventions — Minitest strategy, fixtures, system tests. Use when writing tests, setting up test data, or running test suites.
---

# Rails Testing Skill

Testing strategy for Rails applications using **Minitest** and **fixtures**. Not RSpec, not FactoryBot.

**Sub-files:**
- [FIXTURES.md](FIXTURES.md) — Fixture patterns and test data management
- [SYSTEM-TESTS.md](SYSTEM-TESTS.md) — System and integration test conventions

---

## Philosophy

- **Test at the model level first** — Business logic lives in models; that's where tests provide the most value
- **Fixtures over factories** — YAML fixtures are deterministic, fast, and require no setup code
- **Always set `Current.session`** — Lambda defaults and multi-tenancy depend on it; forgetting it is the #1 test failure
- **Test behavior, not implementation** — Assert on outcomes, not internal method calls
- **Use `assert_difference` for state changes** — Catches false positives that boolean checks alone miss

---

## File Organization

```
test/
  models/
    card/
      archivable_test.rb    # Concern tests get their own file
    card_test.rb
  controllers/
    cards/
      closures_controller_test.rb
  jobs/
    notify_recipients_job_test.rb
  fixtures/
    cards.yml
    sessions.yml
```

---

## Standard Test Structure

```ruby
require "test_helper"

class Card::CloseableTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)  # Always — sets user + account context
  end

  test "close creates closure record and marks card closed" do
    card = cards(:logo)

    assert_difference -> { Closure.count }, +1 do
      card.close
    end

    assert card.closed?
  end
end
```

---

## Model Testing

### State Changes

Nest `assert_difference` blocks when multiple record types change together:

```ruby
assert_difference -> { Closure.count }, +1 do
  assert_difference -> { Event.count }, +1 do
    card.close
  end
end

assert card.closed?
assert_equal "card_closed", Event.last.action
```

### Event Attributes

Count alone is insufficient — always verify attributes:

```ruby
event = Event.last
assert_equal "card_archived", event.action
assert_equal card, event.eventable
assert_equal Current.user, event.creator
# For events with particulars:
assert_equal old_board.name, event.particulars["old_board"]
```

### Scopes

```ruby
card.archive

assert_includes Card.archived, card
assert_not_includes Card.unarchived, card
```

---

## Controller Testing

Inherit from `ActionDispatch::IntegrationTest`. Assert on model state after the request:

```ruby
class Cards::ClosuresControllerTest < ActionDispatch::IntegrationTest
  setup do
    Current.session = sessions(:david)
    @card = cards(:logo)
  end

  test "create closes the card" do
    post card_closure_path(@card.number)
    assert @card.reload.closed?
  end
end
```

---

## Job Testing

Test synchronous logic and async enqueuing separately:

```ruby
# Business logic — fast, no job infrastructure
test "process_data updates records" do
  record.process_data
  assert record.processed?
end

# Async wrapper — verify enqueuing
test "process_data_later enqueues job" do
  assert_enqueued_with(job: ProcessDataJob, args: [record]) do
    record.process_data_later
  end
end
```

Multi-tenancy is automatic — `Current.account` is captured and restored by the job extension. Setting `Current.session` in `setup` is sufficient.

---

## Common Gotchas

**1. Missing `Current.session`** — Lambda defaults (`default: -> { Current.user }`) raise `nil` errors. Put it in `setup`, not inline.

**2. Only checking event count** — After `assert_difference`, verify `Event.last.action`, `eventable`, and `creator`.

**3. Skipping `assert_difference`** — `assert card.archived?` can pass if the flag is set wrong. Wrap the action in `assert_difference -> { Card::Archive.count }, +1` to confirm the record was created.
