# Testing Patterns Template

Template for `.ariadna_planning/codebase/TESTING.md` - captures test framework and patterns.

**Purpose:** Document how tests are written and run. Guide for adding tests that match existing patterns.

---

## File Template

```markdown
# Testing Patterns

**Analysis Date:** [YYYY-MM-DD]

## Test Framework

**Runner:**
- [Framework: e.g., "Minitest 5.x (Rails default, stdlib)"]
- [Config: e.g., "`test/test_helper.rb`"]

**Assertions:**
- [Core: e.g., "`assert`, `assert_equal`, `assert_nil`, `assert_raises`, `assert_not`, `refute`"]
- [Rails: e.g., "`assert_difference`, `assert_no_difference`, `assert_changes`, `assert_includes`"]
- [Controller: e.g., "`assert_response`, `assert_redirected_to`, `assert_enqueued_with`"]

**Run Commands:**
```bash
[e.g., "bundle exec rake test"]                          # Run all tests
[e.g., "bin/rails test"]                                 # Rails test runner
[e.g., "bin/rails test test/models/user_test.rb"]        # Single file
[e.g., "bin/rails test test/models/"]                    # Directory
[e.g., "bin/rails test:system"]                          # System tests
```

## Test File Organization

**Location:**
- [Pattern: e.g., "`test/` directory mirroring `app/` structure"]
- [Models: e.g., "`test/models/`"]
- [Controllers: e.g., "`test/controllers/`"]
- [Integration: e.g., "`test/integration/`"]
- [System: e.g., "`test/system/`"]

**Naming:**
- [Convention: e.g., "`*_test.rb` suffix for all test files"]
- [Models: e.g., "`test/models/card_test.rb`"]
- [Concerns: e.g., "`test/models/card/closeable_test.rb`"]

**Structure:**
```
[Show actual directory pattern, e.g.:
test/
  test_helper.rb
  models/
    card_test.rb
    card/
      closeable_test.rb
      golden_test.rb
  controllers/
    cards_controller_test.rb
    cards/
      closures_controller_test.rb
  integration/
    card_lifecycle_test.rb
  system/
    card_management_test.rb
  fixtures/
    cards.yml
    users.yml
    sessions.yml
]
```

## Test Structure

**Suite Organization:**
```ruby
[Show actual pattern used, e.g.:

require "test_helper"

class CardTest < ActiveSupport::TestCase
  setup do
    @card = cards(:open_card)
    Current.session = sessions(:david)
  end

  test "validates presence of title" do
    @card.title = nil
    assert_not @card.valid?
    assert_includes @card.errors[:title], "can't be blank"
  end

  test "generates sequential number" do
    card = Card.create!(board: boards(:main_board), title: "New card")
    assert card.number.positive?
  end
end
]
```

**Patterns:**
- [Setup: e.g., "`setup` block for per-test state, always set `Current.session`"]
- [Teardown: e.g., "Rarely needed — database transactions roll back automatically"]
- [Structure: e.g., "`test \"description\"` blocks for clarity"]
- [Focus: e.g., "One concept per test"]

## Mocking

**Framework:**
- [Tool: e.g., "`Minitest::Mock` for mock objects, `stub` for method stubbing"]
- [Time: e.g., "`travel_to` for time-dependent tests (ActiveSupport)"]

**Patterns:**
```ruby
[Show actual mocking pattern, e.g.:

# Minitest::Mock
mock = Minitest::Mock.new
mock.expect :call, "result", [String]

# Stub
User.stub :find, @user do
  get user_url(@user)
  assert_response :success
end

# Time travel
travel_to Time.zone.parse("2025-01-15 10:00") do
  assert card.stale?
end
]
```

**What to Mock:**
- [e.g., "External HTTP calls (APIs, webhooks)"]
- [e.g., "Email delivery (use ActionMailer test helpers)"]
- [e.g., "Time-dependent code (`travel_to`)"]
- [e.g., "File system operations"]

**What NOT to Mock:**
- [e.g., "ActiveRecord queries (use fixtures)"]
- [e.g., "Pure Ruby methods"]
- [e.g., "Internal business logic"]

## Fixtures

**Test Data:**
```yaml
[Show actual fixture pattern, e.g.:

# test/fixtures/cards.yml
open_card:
  title: "Fix login bug"
  board: main_board
  creator: david
  number: 1

closed_card:
  title: "Update docs"
  board: main_board
  creator: david
  number: 2
]
```

```ruby
[Show fixture access pattern, e.g.:

# Accessing fixtures in tests
@card = cards(:open_card)
@user = users(:david)
Current.session = sessions(:david)
]
```

**Location:**
- [e.g., "`test/fixtures/` for YAML fixtures (Rails default)"]
- [e.g., "`test/factories/` for FactoryBot factories (if present)"]

## Coverage

**Requirements:**
- [Target: e.g., "No enforced target, focus on models and business logic"]
- [Tool: e.g., "SimpleCov for coverage tracking"]

**View Coverage:**
```bash
[e.g., "COVERAGE=true bundle exec rake test"]
[e.g., "open coverage/index.html"]
```

## Test Types

**Model Tests:**
- [Location: e.g., "`test/models/`"]
- [Scope: e.g., "Validations, associations, scopes, concern behavior, business logic methods"]
- [Setup: e.g., "Fixtures + `Current.session` for request context"]

**Controller Tests:**
- [Location: e.g., "`test/controllers/`"]
- [Scope: e.g., "Request/response, params, auth, redirects, Turbo Stream responses"]
- [Setup: e.g., "Sign in via session fixture, use URL helpers"]

**Integration Tests:**
- [Location: e.g., "`test/integration/`"]
- [Scope: e.g., "Multi-step flows, API endpoints, cross-controller interactions"]

**System Tests:**
- [Location: e.g., "`test/system/`"]
- [Scope: e.g., "Browser tests with Capybara"]
- [Driver: e.g., "`driven_by :selenium, using: :headless_chrome`"]

## Common Patterns

**Assert Database Changes:**
```ruby
[Show pattern, e.g.:

assert_difference "Event.count", 1 do
  @card.close
end

assert_no_difference "Card.count" do
  post cards_url, params: { card: { title: "" } }
end
]
```

**Assert Attribute Changes:**
```ruby
[Show pattern, e.g.:

assert_changes -> { @card.reload.title }, from: "Old", to: "New" do
  @card.update!(title: "New")
end
]
```

**Controller Tests:**
```ruby
[Show pattern, e.g.:

test "creates card" do
  assert_difference "Card.count", 1 do
    post cards_url, params: { card: { title: "New card" } }
  end
  assert_redirected_to card_url(Card.last)
end
]
```

**System Tests:**
```ruby
[Show pattern, e.g.:

test "user closes a card" do
  visit card_url(@card)
  click_on "Close"
  assert_text "Card closed"
end
]
```

---

*Testing analysis: [date]*
*Update when test patterns change*
```

<good_examples>
```markdown
# Testing Patterns

**Analysis Date:** 2025-01-20

## Test Framework

**Runner:**
- Minitest 5.x (Rails default, stdlib)
- Config: `test/test_helper.rb`

**Assertions:**
- Core: `assert`, `assert_equal`, `assert_nil`, `assert_raises`, `assert_not`, `refute`, `assert_includes`
- Rails: `assert_difference`, `assert_no_difference`, `assert_changes`, `assert_no_changes`
- Controller: `assert_response`, `assert_redirected_to`, `assert_enqueued_with`, `assert_enqueued_jobs`

**Run Commands:**
```bash
bundle exec rake test                          # Run all tests
bin/rails test                                 # Rails test runner
bin/rails test test/models/card_test.rb        # Single file
bin/rails test test/models/                    # Directory
bin/rails test:system                          # System tests
```

## Test File Organization

**Location:**
- `test/` directory mirroring `app/` structure
- Model-specific concern tests in subdirectories

**Naming:**
- `*_test.rb` suffix for all test files
- Concern tests mirror concern structure: `test/models/card/closeable_test.rb`

**Structure:**
```
test/
  test_helper.rb
  models/
    card_test.rb
    board_test.rb
    user_test.rb
    card/
      closeable_test.rb
      golden_test.rb
      postponable_test.rb
  controllers/
    cards_controller_test.rb
    cards/
      closures_controller_test.rb
      goldnesses_controller_test.rb
  integration/
    card_lifecycle_test.rb
  system/
    card_management_test.rb
  fixtures/
    cards.yml
    boards.yml
    users.yml
    sessions.yml
    closures.yml
```

## Test Structure

**Suite Organization:**
```ruby
require "test_helper"

class CardTest < ActiveSupport::TestCase
  setup do
    @card = cards(:open_card)
    Current.session = sessions(:david)
  end

  test "closes card" do
    assert_difference "Closure.count", 1 do
      @card.close
    end
    assert @card.closed?
  end

  test "cannot close already closed card" do
    @card.close
    assert_no_difference "Closure.count" do
      @card.close
    end
  end
end
```

**Patterns:**
- `setup` block for per-test state — always set `Current.session`
- Database transactions roll back after each test — teardown rarely needed
- `test "description"` blocks for clarity (not `def test_*`)
- One concept per test

## Mocking

**Framework:**
- `Minitest::Mock` for mock objects
- `stub` for method stubbing (stdlib, no extra gems)
- `travel_to` for time-dependent tests (ActiveSupport)

**Patterns:**
```ruby
# Minitest::Mock
mock = Minitest::Mock.new
mock.expect :call, "result", [String]
service = MyService.new(dependency: mock)
service.perform
mock.verify

# Stub
User.stub :find, @user do
  get user_url(@user)
  assert_response :success
end

# Time travel
travel_to Time.zone.parse("2025-01-15 10:00") do
  assert card.stale?
end
```

**What to Mock:**
- External HTTP calls (APIs, webhooks)
- Email delivery (use ActionMailer test helpers)
- Time-dependent code (`travel_to`)
- File system operations

**What NOT to Mock:**
- ActiveRecord queries (use fixtures)
- Pure Ruby methods
- Internal business logic

## Fixtures

**Test Data:**
```yaml
# test/fixtures/cards.yml
open_card:
  title: "Fix login bug"
  board: main_board
  creator: david
  number: 1

closed_card:
  title: "Update docs"
  board: main_board
  creator: david
  number: 2
```

```ruby
# Accessing fixtures in tests
@card = cards(:open_card)
@user = users(:david)
Current.session = sessions(:david)
```

**Location:**
- `test/fixtures/` for YAML fixtures (Rails default)
- Fixture-based testing preferred over FactoryBot — faster, deterministic, no build overhead
- Fixture associations use label references (not IDs): `board: main_board`

**Current Context in Tests:**
- `Current.session = sessions(:fixture_name)` sets up the full cascade: session -> identity -> user
- Required whenever model code references `Current.user` (e.g., lambda defaults on `belongs_to :creator`)
- Set in `setup` block so every test has proper context

## Coverage

**Requirements:**
- No enforced coverage target
- Focus on models and business logic
- SimpleCov for coverage tracking

**View Coverage:**
```bash
COVERAGE=true bundle exec rake test
open coverage/index.html
```

## Test Types

**Model Tests:**
- Location: `test/models/`
- Scope: Validations, associations, scopes, concern behavior, business logic methods
- Setup: Fixtures + `Current.session` for request context
- Examples: `card_test.rb`, `card/closeable_test.rb`, `board_test.rb`

**Controller Tests:**
- Location: `test/controllers/`
- Scope: Request/response, params, auth, redirects, Turbo Stream responses
- Setup: Sign in via session fixture, use URL helpers
- Examples: `cards_controller_test.rb`, `cards/closures_controller_test.rb`

**Integration Tests:**
- Location: `test/integration/`
- Scope: Multi-step flows, API endpoints, cross-controller interactions
- Examples: `card_lifecycle_test.rb`

**System Tests:**
- Location: `test/system/`
- Scope: Full browser tests with Capybara
- Driver: `driven_by :selenium, using: :headless_chrome`
- Examples: `card_management_test.rb`

## Common Patterns

**Assert Database Changes:**
```ruby
# Assert a record is created
assert_difference "Event.count", 1 do
  @card.close
end

# Assert no records created (e.g., invalid input)
assert_no_difference "Card.count" do
  post cards_url, params: { card: { title: "" } }
end

# Assert multiple changes
assert_difference -> { Card::Archive.count }, +1 do
  assert_difference -> { Event.count }, +1 do
    @card.archive
  end
end
```

**Assert Attribute Changes:**
```ruby
assert_changes -> { @card.reload.title }, from: "Old", to: "New" do
  @card.update!(title: "New")
end
```

**Controller Tests:**
```ruby
test "creates card" do
  assert_difference "Card.count", 1 do
    post cards_url, params: { card: { title: "New card" } }
  end
  assert_redirected_to card_url(Card.last)
end
```

**Job Enqueue Tests:**
```ruby
test "notify_recipients_later enqueues job" do
  assert_enqueued_with(job: NotifyRecipientsJob) do
    comment.save!
  end
end

# Or test with inline execution
test "job processes in correct account" do
  perform_enqueued_jobs do
    comment.notify_recipients_later
  end
  assert_equal 2, Current.account.notifications.count
end
```

**System Tests:**
```ruby
test "user closes a card" do
  visit card_url(@card)
  click_on "Close"
  assert_text "Card closed"
end
```

---

*Testing analysis: 2025-01-20*
*Update when test patterns change*
```
</good_examples>

<guidelines>
**What belongs in TESTING.md:**
- Test framework and runner configuration
- Test file location and naming patterns
- Test structure (`setup`, `test "description"` blocks)
- Mocking approach and examples (`Minitest::Mock`, `stub`, `travel_to`)
- Fixture patterns and `Current.session` setup
- Coverage requirements
- How to run tests (commands)
- Common testing patterns in actual code (`assert_difference`, `assert_changes`, job enqueue assertions)

**What does NOT belong here:**
- Specific test cases (defer to actual test files)
- Technology choices (that's STACK.md)
- CI/CD setup (that's deployment docs)

**When filling this template:**
- Check `Gemfile` for test framework (Minitest is Rails default — check if RSpec is present instead)
- Read `test/test_helper.rb` for test configuration, included modules, global setup
- Examine `test/` directory structure for organization patterns
- Check for `test/fixtures/` (Rails default) vs `test/factories/` (FactoryBot)
- Read 3-5 existing test files to identify patterns (setup, assertions, fixture usage)
- Look for test support in `test/support/` or custom helpers in `test/test_helper.rb`
- Check for `Current.session` setup patterns in model tests
- Note whether concern tests exist in subdirectories (`test/models/card/`)
- Document actual patterns used, not ideal patterns

**Key Rails testing conventions to note:**
- Fixture-based testing is Rails default (vs FactoryBot) — faster, deterministic
- `Current.session = sessions(:fixture_name)` pattern for setting up request context in tests
- `assert_difference` / `assert_no_difference` as the primary pattern for testing state changes
- Concern tests mirror concern file structure (`test/models/card/closeable_test.rb`)
- System tests use Capybara with `driven_by :selenium, using: :headless_chrome`

**Useful for phase planning when:**
- Adding new features (write matching tests)
- Adding new concerns (create corresponding concern test file)
- Refactoring (maintain test patterns)
- Fixing bugs (add regression tests using `assert_difference`)
- Understanding verification approach
- Setting up test infrastructure

**Analysis approach:**
- Check `Gemfile` for test framework and related gems (minitest, capybara, selenium-webdriver, simplecov)
- Read `test/test_helper.rb` for configuration, required files, global setup
- Examine `test/` directory structure (does it mirror `app/`? are concern tests in subdirectories?)
- Check for `test/fixtures/` and examine fixture files for association patterns
- Review 5 test files for patterns (setup blocks, `Current.session` usage, assertion style, fixture access)
- Look for test utilities in `test/support/` or custom assertions
- Note test types present (model, controller, integration, system)
- Document commands for running tests (`bin/rails test`, `bundle exec rake test`)
</guidelines>
