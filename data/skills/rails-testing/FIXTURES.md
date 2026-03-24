# Fixtures — Test Data Management

Part of the [Rails Testing Skill](SKILL.md).

---

## Fixtures Over Factories

Use **YAML fixtures**, not FactoryBot. Fixtures are deterministic, fast (loaded once per suite in a transaction), and explicit. Same records every test run — no random IDs.

---

## File Location and Format

```
test/fixtures/
  cards.yml
  sessions.yml
  boards.yml
```

```yaml
# test/fixtures/cards.yml
logo:
  title: "Logo Design"
  board: writebook
  state: open

header:
  title: "Header Redesign"
  board: writebook
  state: closed
```

Use descriptive symbolic names (`logo`, `header`) — never generic names like `one`, `two`.

---

## Accessing Fixtures

```ruby
card = cards(:logo)
session = sessions(:david)
board = boards(:writebook)
```

For associations, use the fixture name in YAML — Rails resolves the foreign key automatically.

---

## Current.session and Sessions Fixtures

The sessions fixture drives the entire Current context cascade:

```ruby
setup do
  Current.session = sessions(:david)
  # Sets Current.session → Current.user → Current.account
end
```

One line sets tenant scope, user context, and event tracking defaults. Define at least one named session per user persona.

---

## Adding New Fixtures

1. Create `test/fixtures/<table_name>.yml`
2. Add named records with meaningful names and all required attributes
3. Reference in tests via `model_name(:fixture_name)`

Avoid `Model.create!` inside tests for arrangement — use existing fixtures. Reserve `create!` calls for tests that specifically verify creation behavior.

---

## Fixture Isolation

Each test wraps in a transaction that rolls back after completion. Fixture records persist for the full suite run but mutations are rolled back between tests. Use `record.reload` to pick up database changes within the same test.
