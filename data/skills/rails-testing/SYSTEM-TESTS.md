# System Tests & Integration Tests

Part of the [Rails Testing Skill](SKILL.md).

---

## When to Write System Tests

System tests (browser-driven via Capybara) are reserved for **critical user flows**:

- Authentication and session management
- Multi-step form submissions
- JavaScript-dependent interactions (Turbo streams, Stimulus)
- Flows that span multiple controllers

For business logic, prefer model tests — faster and more precise.

---

## Test Type Selection

| Concern | Use |
|---|---|
| Business logic, state changes | Model test (`ActiveSupport::TestCase`) |
| Controller routing, response codes | `ActionDispatch::IntegrationTest` |
| Full browser flow, JS interactions | System test (`ApplicationSystemTestCase`) |
| Job enqueuing | `assert_enqueued_with` in model/controller test |

---

## System Test Structure

```ruby
require "application_system_test_case"

class CardLifecycleTest < ApplicationSystemTestCase
  setup do
    sign_in_as users(:david)
  end

  test "user can close and reopen a card" do
    visit card_path(cards(:logo))
    click_on "Close"
    assert_text "Card closed"

    click_on "Reopen"
    assert_text "Card reopened"
  end
end
```

Define `sign_in_as` in `ApplicationSystemTestCase` — do not repeat the login flow in each test.

---

## Integration Tests (Controller-Level)

For HTTP assertions without a browser, set `Current.session` directly:

```ruby
class Cards::ClosuresControllerTest < ActionDispatch::IntegrationTest
  setup do
    Current.session = sessions(:david)
  end

  test "POST creates closure and redirects" do
    post card_closure_path(cards(:logo).number)
    assert_redirected_to card_path(cards(:logo).number)
  end
end
```

No browser sign-in flow needed — `Current.session` assignment is sufficient for controller tests.
