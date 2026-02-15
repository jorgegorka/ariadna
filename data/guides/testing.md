# Testing Patterns & Practices

**A Guide to Testing Rails Applications with Minitest**

This guide consolidates all testing patterns and practices used across the application. It covers setup conventions, model testing, controller testing, job testing, and common gotchas.

**Related guides:**
- [Backend Patterns](backend.md) — Architecture, models, controllers, jobs, style guide
- [Frontend Patterns](frontend.md) — Presenter pattern (includes presenter testing examples)
- [Security Guide](security.md) — Agent-oriented security checklist for code review

## Table of Contents

- [1. Testing Philosophy](#1-testing-philosophy)
- [2. Model Testing Patterns](#2-model-testing-patterns)
  - [2.1 Current Context Setup](#21-current-context-setup)
  - [2.2 Testing State Changes](#22-testing-state-changes)
  - [2.3 Testing Event Creation](#23-testing-event-creation)
  - [2.4 Testing Scopes](#24-testing-scopes)
- [3. Controller Testing Patterns](#3-controller-testing-patterns)
- [4. Job Testing Patterns](#4-job-testing-patterns)
  - [4.1 Testing Synchronous Logic](#41-testing-synchronous-logic)
  - [4.2 Testing Async Wrappers](#42-testing-async-wrappers)
  - [4.3 Multi-Tenancy in Job Tests](#43-multi-tenancy-in-job-tests)
- [5. Presenter Testing Patterns](#5-presenter-testing-patterns)
- [6. Recipe Test Steps](#6-recipe-test-steps)
  - [6.1 Recipe: Testing New Card States](#recipe-testing-new-card-states)
  - [6.2 Recipe: Testing Event Creation](#recipe-testing-event-creation)
  - [6.3 Recipe: Testing Background Jobs](#recipe-testing-background-jobs)
- [7. Common Testing Gotchas](#7-common-testing-gotchas)

---

# 1. Testing Philosophy

The application uses **Minitest** (Rails default) with **fixtures** for test data. Key principles:

- **Test at the model level first** — Business logic lives in models, so that's where tests provide the most value
- **Use fixtures, not factories** — YAML fixtures provide deterministic, fast test data
- **Always set `Current.session`** — Lambda defaults and multi-tenancy depend on it
- **Test behavior, not implementation** — Assert on outcomes, not internal method calls
- **Use `assert_difference` for state changes** — Verify record counts change as expected

### Test File Organization

Tests mirror the `app/` directory structure:

```
test/
  models/
    card/
      archivable_test.rb    # Tests for Card::Archivable concern
      closeable_test.rb     # Tests for Card::Closeable concern
    card_test.rb            # Tests for Card model
  controllers/
    cards/
      closures_controller_test.rb
  jobs/
    notify_recipients_job_test.rb
  fixtures/
    cards.yml
    sessions.yml
```

### Standard Test Structure

```ruby
require "test_helper"

class Card::CloseableTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)  # Always set Current context
  end

  test "descriptive name of what is being tested" do
    # Arrange
    card = cards(:logo)

    # Act & Assert
    assert_difference -> { Closure.count }, +1 do
      card.close
    end

    assert card.closed?
  end
end
```

---

# 2. Model Testing Patterns

## 2.1 Current Context Setup

Every model test that creates records or uses `Current.user`/`Current.account` must set up the Current context:

```ruby
setup do
  Current.session = sessions(:david)  # Sets up user and account context
end
```

**The cascade**: Setting `Current.session` automatically:
1. Extracts the `identity` from the session
2. Finds the `user` for that identity in the current `account`

This is required because:
- Lambda defaults like `default: -> { Current.user }` need it
- Multi-tenancy scoping depends on `Current.account`
- Event tracking uses `Current.user` as default creator

## 2.2 Testing State Changes

Use `assert_difference` to verify records are created or destroyed:

```ruby
test "close creates closure record and event" do
  card = cards(:logo)

  assert_difference -> { Closure.count }, +1 do
    assert_difference -> { Event.count }, +1 do
      card.close
    end
  end

  assert card.closed?
  assert_equal "card_closed", Event.last.action
end

test "reopen removes closure record" do
  card = cards(:logo)
  card.close

  assert_difference -> { Closure.count }, -1 do
    card.reopen
  end

  assert card.open?
end
```

**Pattern**: Nest `assert_difference` blocks when multiple record types change together.

## 2.3 Testing Event Creation

When testing actions that track events, verify both the event count and event attributes:

```ruby
test "archiving creates event with correct attributes" do
  card = cards(:logo)

  assert_difference -> { Event.count }, +1 do
    card.archive
  end

  event = Event.last
  assert_equal "card_archived", event.action
  assert_equal card, event.eventable
  assert_equal Current.user, event.creator
end
```

For events with particulars:

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

## 2.4 Testing Scopes

Test scopes by creating records in the expected state and asserting membership:

```ruby
test "archived scope returns only archived cards" do
  card = cards(:logo)
  card.archive

  assert_includes Card.archived, card
  assert_not_includes Card.unarchived, card
end

test "open scope excludes closed cards" do
  card = cards(:logo)
  card.close

  assert_not_includes Card.open, card
  assert_includes Card.closed, card
end
```

---

# 3. Controller Testing Patterns

Controller tests verify that the controller correctly delegates to the model and renders the right response:

```ruby
require "test_helper"

class Cards::ClosuresControllerTest < ActionDispatch::IntegrationTest
  setup do
    Current.session = sessions(:david)
    @card = cards(:logo)
  end

  test "create closes the card" do
    post card_closure_path(@card.number)

    assert @card.reload.closed?
  end

  test "destroy reopens the card" do
    @card.close

    delete card_closure_path(@card.number)

    assert @card.reload.open?
  end
end
```

**Key points:**
- Use RESTful route helpers matching the resource nesting pattern
- Assert on the model state after the request, not on internal calls
- The `setup` block sets `Current.session` for authentication context

---

# 4. Job Testing Patterns

## 4.1 Testing Synchronous Logic

Test the synchronous version of the method directly — this tests the actual business logic without job infrastructure:

```ruby
test "notify_recipients sends to watchers" do
  comment = comments(:first)

  comment.notify_recipients

  assert_equal 2, Notification.count
end

test "process_data updates records" do
  record = some_model(:example)

  record.process_data

  assert record.processed?
end
```

## 4.2 Testing Async Wrappers

Test that the async wrapper correctly enqueues the job:

```ruby
test "notify_recipients_later enqueues job" do
  assert_enqueued_with(job: NotifyRecipientsJob) do
    comment.save!
  end
end

test "process_data_later enqueues job with correct args" do
  assert_enqueued_with(job: ProcessDataJob, args: [record]) do
    record.process_data_later
  end
end
```

**Pattern**: Test synchronous logic and async enqueuing separately. This gives you:
- Fast, focused tests for business logic (via synchronous method)
- Integration tests for job enqueuing (via async wrapper)

## 4.3 Multi-Tenancy in Job Tests

The multi-tenancy job extension automatically captures and restores `Current.account`. Tests work naturally when you set `Current.session`:

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

**You don't need to manually pass account to jobs in tests** — it's captured automatically, just like in production.

---

# 5. Presenter Testing Patterns

Presenter tests live alongside their presenters in the test directory. For detailed presenter testing examples, see [Frontend Patterns — Testing Presenters](frontend.md#18-testing-presenters).

Key patterns:
- Test presenters like any Ruby class
- Set `Current.session` in setup for context
- Test boolean display methods (`show_tags?`, `expanded?`)
- Test cache key uniqueness for different states
- For HTML-generating presenters, test both `to_html` and `to_plain_text` outputs

---

# 6. Recipe Test Steps

These test examples correspond to the recipes in [Backend Patterns — Common Tasks & Recipes](backend.md#part-6-common-tasks--recipes).

## Recipe: Testing New Card States

Complete test for the "Adding a New State to Cards" recipe (see [Backend Patterns — Recipe 6.1](backend.md#61-recipe-adding-a-new-state-to-cards)):

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

## Recipe: Testing Event Creation

Complete test for the "Adding Event Tracking" recipe (see [Backend Patterns — Recipe 6.2](backend.md#62-recipe-adding-event-tracking)):

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

## Recipe: Testing Background Jobs

Complete tests for the "Creating Background Jobs" recipe (see [Backend Patterns — Recipe 6.3](backend.md#63-recipe-creating-background-jobs)):

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

# 7. Common Testing Gotchas

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

**Why:** Lambda defaults like `default: -> { Current.user }` need `Current.session` set. This is the most common test failure for new developers. Always include it in your `setup` block:

```ruby
setup do
  Current.session = sessions(:david)
end
```

### 2. Testing Events Without Checking Attributes

**Problem:**

```ruby
test "closing creates event" do
  assert_difference -> { Event.count }, +1 do
    card.close
  end
  # Only checks count, not that the right event was created
end
```

**Solution:**

```ruby
test "closing creates event" do
  assert_difference -> { Event.count }, +1 do
    card.close
  end

  event = Event.last
  assert_equal "card_closed", event.action
  assert_equal card, event.eventable
end
```

Always verify event attributes after checking the count.

### 3. Not Using assert_difference for State Changes

**Problem:**

```ruby
test "archive creates record" do
  card.archive
  assert card.archived?  # Passes, but doesn't verify a record was created
end
```

**Solution:**

```ruby
test "archive creates record" do
  assert_difference -> { Card::Archive.count }, +1 do
    card.archive
  end
  assert card.archived?
end
```

`assert_difference` catches bugs where the boolean check passes for the wrong reason.

---

**Document Version**: 1.0
**Last Updated**: 2026-02-15
**Maintainer**: Development Team
