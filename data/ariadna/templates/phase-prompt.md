# Phase Prompt Template

> **Note:** Planning methodology is in `agents/ariadna-planner.md`.
> This template defines the PLAN.md output format that the agent produces.

Template for `.ariadna_planning/phases/XX-name/{phase}-{plan}-PLAN.md` - executable phase plans optimized for parallel execution.

**Naming:** Use `{phase}-{plan}-PLAN.md` format (e.g., `01-02-PLAN.md` for Phase 1, Plan 2)

---

## File Template

```markdown
---
phase: XX-name
plan: NN
type: execute
wave: N                     # Execution wave (1, 2, 3...). Pre-computed at plan time.
depends_on: []              # Plan IDs this plan requires (e.g., ["01-01"]).
files_modified: []          # Files this plan modifies.
autonomous: true            # false if plan has checkpoints requiring user interaction
user_setup: []              # Human-required setup Claude cannot automate (see below)
domain: general             # optional: backend, frontend, testing, general
domain_guide: ~             # optional: guide filename (e.g., backend.md)

# Goal-backward verification (derived during planning, verified after execution)
must_haves:
  truths: []                # Observable behaviors that must be true for goal achievement
  artifacts: []             # Files that must exist with real implementation
  key_links: []             # Critical connections between artifacts
---

<objective>
[What this plan accomplishes]

Purpose: [Why this matters for the project]
Output: [What artifacts will be created]
</objective>

<execution_context>
@~/.claude/ariadna/workflows/execute-plan.md
@~/.claude/ariadna/templates/summary.md
[If plan contains checkpoint tasks (type="checkpoint:*"), add:]
@~/.claude/ariadna/references/checkpoints.md
</execution_context>

<context>
@.ariadna_planning/PROJECT.md
@.ariadna_planning/ROADMAP.md
@.ariadna_planning/STATE.md

# Only reference prior plan SUMMARYs if genuinely needed:
# - This plan uses types/exports from prior plan
# - Prior plan made decision that affects this plan
# Do NOT reflexively chain: Plan 02 refs 01, Plan 03 refs 02...

[Relevant source files:]
@app/path/to/relevant.rb
</context>

<tasks>

<task type="auto">
  <name>Task 1: [Action-oriented name]</name>
  <files>path/to/file.ext, another/file.ext</files>
  <action>[Specific implementation - what to do, how to do it, what to avoid and WHY]</action>
  <verify>[Command or check to prove it worked]</verify>
  <done>[Measurable acceptance criteria]</done>
</task>

<task type="auto">
  <name>Task 2: [Action-oriented name]</name>
  <files>path/to/file.ext</files>
  <action>[Specific implementation]</action>
  <verify>[Command or check]</verify>
  <done>[Acceptance criteria]</done>
</task>

<!-- For checkpoint task examples and patterns, see @~/.claude/ariadna/references/checkpoints.md -->
<!-- Key rule: Claude starts dev server BEFORE human-verify checkpoints. User only visits URLs. -->

<task type="checkpoint:decision" gate="blocking">
  <decision>[What needs deciding]</decision>
  <context>[Why this decision matters]</context>
  <options>
    <option id="option-a"><name>[Name]</name><pros>[Benefits]</pros><cons>[Tradeoffs]</cons></option>
    <option id="option-b"><name>[Name]</name><pros>[Benefits]</pros><cons>[Tradeoffs]</cons></option>
  </options>
  <resume-signal>Select: option-a or option-b</resume-signal>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>[What Claude built] - server running at [URL]</what-built>
  <how-to-verify>Visit [URL] and verify: [visual checks only, NO CLI commands]</how-to-verify>
  <resume-signal>Type "approved" or describe issues</resume-signal>
</task>

</tasks>

<verification>
Before declaring plan complete:
- [ ] [Specific test command]
- [ ] [Build/type check passes]
- [ ] [Behavior verification]
</verification>

<success_criteria>

- All tasks completed
- All verification checks pass
- No errors or warnings introduced
- [Plan-specific criteria]
  </success_criteria>

<output>
After completion, create `.ariadna_planning/phases/XX-name/{phase}-{plan}-SUMMARY.md`
</output>
```

---

## Frontmatter Fields

| Field | Required | Purpose |
|-------|----------|---------|
| `phase` | Yes | Phase identifier (e.g., `01-foundation`) |
| `plan` | Yes | Plan number within phase (e.g., `01`, `02`) |
| `type` | Yes | Always `execute` for standard plans, `tdd` for TDD plans |
| `wave` | Yes | Execution wave number (1, 2, 3...). Pre-computed at plan time. |
| `depends_on` | Yes | Array of plan IDs this plan requires. |
| `files_modified` | Yes | Files this plan touches. |
| `autonomous` | Yes | `true` if no checkpoints, `false` if has checkpoints |
| `user_setup` | No | Array of human-required setup items (external services) |
| `domain` | No | Domain assignment: `backend`, `frontend`, `testing`, `general` (for domain-split execution) |
| `domain_guide` | No | Guide filename for domain executor (e.g., `backend.md`) |
| `must_haves` | Yes | Goal-backward verification criteria (see below) |

**Wave is pre-computed:** Wave numbers are assigned during `/ariadna:plan-phase`. Execute-phase reads `wave` directly from frontmatter and groups plans by wave number. No runtime dependency analysis needed.

**Must-haves enable verification:** The `must_haves` field carries goal-backward requirements from planning to execution. After all plans complete, execute-phase spawns a verification subagent that checks these criteria against the actual codebase.

---

## Parallel vs Sequential

<parallel_examples>

**Wave 1 candidates (parallel):**

```yaml
# Plan 01 - User feature
wave: 1
depends_on: []
files_modified: [app/models/user.rb, app/controllers/users_controller.rb]
autonomous: true

# Plan 02 - Product feature (no overlap with Plan 01)
wave: 1
depends_on: []
files_modified: [app/models/product.rb, app/controllers/products_controller.rb]
autonomous: true

# Plan 03 - Order feature (no overlap)
wave: 1
depends_on: []
files_modified: [app/models/order.rb, app/controllers/orders_controller.rb]
autonomous: true
```

All three run in parallel (Wave 1) - no dependencies, no file conflicts.

**Sequential (genuine dependency):**

```yaml
# Plan 01 - Auth foundation
wave: 1
depends_on: []
files_modified: [app/services/authentication.rb, app/controllers/concerns/authenticatable.rb]
autonomous: true

# Plan 02 - Protected features (needs auth)
wave: 2
depends_on: ["01"]
files_modified: [app/controllers/dashboards_controller.rb]
autonomous: true
```

Plan 02 in Wave 2 waits for Plan 01 in Wave 1 - genuine dependency on auth types/middleware.

**Checkpoint plan:**

```yaml
# Plan 03 - UI with verification
wave: 3
depends_on: ["01", "02"]
files_modified: [app/views/dashboards/show.html.erb]
autonomous: false  # Has checkpoint:human-verify
```

Wave 3 runs after Waves 1 and 2. Pauses at checkpoint, orchestrator presents to user, resumes on approval.

**Domain-split (horizontal by expertise):**

```yaml
# Plan 01 - Backend: User model + controller
wave: 1
depends_on: []
files_modified: [app/models/user.rb, app/controllers/users_controller.rb]
autonomous: true
domain: backend
domain_guide: backend.md

# Plan 02 - Backend: Product model + controller
wave: 1
depends_on: []
files_modified: [app/models/product.rb, app/controllers/products_controller.rb]
autonomous: true
domain: backend
domain_guide: backend.md

# Plan 03 - Frontend: User + Product views
wave: 2
depends_on: ["01", "02"]
files_modified: [app/views/users/, app/views/products/]
autonomous: true
domain: frontend
domain_guide: frontend.md

# Plan 04 - Testing: Model + controller tests
wave: 2
depends_on: ["01", "02"]
files_modified: [test/models/user_test.rb, test/controllers/users_controller_test.rb]
autonomous: true
domain: testing
domain_guide: testing.md
```

Backend plans run in Wave 1. Frontend and testing plans run in Wave 2 (parallel, both depend on backend). Domain executors load their respective guides for domain-specific expertise.

</parallel_examples>

---

## Context Section

**Parallel-aware context:**

```markdown
<context>
@.ariadna_planning/PROJECT.md
@.ariadna_planning/ROADMAP.md
@.ariadna_planning/STATE.md

# Only include SUMMARY refs if genuinely needed:
# - This plan imports types from prior plan
# - Prior plan made decision affecting this plan
# - Prior plan's output is input to this plan
#
# Independent plans need NO prior SUMMARY references.
# Do NOT reflexively chain: 02 refs 01, 03 refs 02...

@app/models/relevant.rb
</context>
```

**Bad pattern (creates false dependencies):**
```markdown
<context>
@.ariadna_planning/phases/03-features/03-01-SUMMARY.md  # Just because it's earlier
@.ariadna_planning/phases/03-features/03-02-SUMMARY.md  # Reflexive chaining
</context>
```

---

## Scope Guidance

**Plan sizing:**

- 2-3 tasks per plan
- ~50% context usage maximum
- Complex phases: Multiple focused plans, not one large plan

**When to split:**

- Different subsystems (auth vs API vs UI)
- >3 tasks
- Risk of context overflow
- TDD candidates - separate plans

**Vertical slices preferred:**

```
PREFER: Plan 01 = User (model + API + UI)
        Plan 02 = Product (model + API + UI)

AVOID:  Plan 01 = All models
        Plan 02 = All APIs
        Plan 03 = All UIs
```

---

## TDD Plans

TDD features get dedicated plans with `type: tdd`.

**Heuristic:** Can you write `assert_equal expected, fn(input)` before writing `fn`?
→ Yes: Create a TDD plan
→ No: Standard task in standard plan

See `~/.claude/ariadna/references/tdd.md` for TDD plan structure.

---

## Task Types

| Type | Use For | Autonomy |
|------|---------|----------|
| `auto` | Everything Claude can do independently | Fully autonomous |
| `checkpoint:human-verify` | Visual/functional verification | Pauses, returns to orchestrator |
| `checkpoint:decision` | Implementation choices | Pauses, returns to orchestrator |
| `checkpoint:human-action` | Truly unavoidable manual steps (rare) | Pauses, returns to orchestrator |

**Checkpoint behavior in parallel execution:**
- Plan runs until checkpoint
- Agent returns with checkpoint details + agent_id
- Orchestrator presents to user
- User responds
- Orchestrator resumes agent with `resume: agent_id`

---

## Examples

**Autonomous parallel plan:**

```markdown
---
phase: 03-features
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: [app/models/user.rb, app/controllers/users_controller.rb, app/views/users/index.html.erb]
autonomous: true
---

<objective>
Implement complete User feature as vertical slice.

Purpose: Self-contained user management that can run parallel to other features.
Output: User model, controller, and view templates.
</objective>

<context>
@.ariadna_planning/PROJECT.md
@.ariadna_planning/ROADMAP.md
@.ariadna_planning/STATE.md
</context>

<tasks>
<task type="auto">
  <name>Task 1: Create User model and migration</name>
  <files>app/models/user.rb, db/migrate/create_users.rb</files>
  <action>Generate User model with email, name, timestamps. Add validations for presence and uniqueness.</action>
  <verify>bundle exec rake test passes</verify>
  <done>User model with validations and passing migration</done>
</task>

<task type="auto">
  <name>Task 2: Create User controller and views</name>
  <files>app/controllers/users_controller.rb, app/views/users/</files>
  <action>RESTful UsersController with index, show, create actions. Add corresponding view templates.</action>
  <verify>bundle exec rake test passes</verify>
  <done>All CRUD operations work</done>
</task>
</tasks>

<verification>
- [ ] bundle exec rake test passes
- [ ] API endpoints respond correctly
</verification>

<success_criteria>
- All tasks completed
- User feature works end-to-end
</success_criteria>

<output>
After completion, create `.ariadna_planning/phases/03-features/03-01-SUMMARY.md`
</output>
```

**Plan with checkpoint (non-autonomous):**

```markdown
---
phase: 03-features
plan: 03
type: execute
wave: 2
depends_on: ["03-01", "03-02"]
files_modified: [app/controllers/dashboards_controller.rb, app/views/dashboards/show.html.erb]
autonomous: false
---

<objective>
Build dashboard with visual verification.

Purpose: Integrate user and product features into unified view.
Output: Working dashboard controller and view.
</objective>

<execution_context>
@~/.claude/ariadna/workflows/execute-plan.md
@~/.claude/ariadna/templates/summary.md
@~/.claude/ariadna/references/checkpoints.md
</execution_context>

<context>
@.ariadna_planning/PROJECT.md
@.ariadna_planning/ROADMAP.md
@.ariadna_planning/phases/03-features/03-01-SUMMARY.md
@.ariadna_planning/phases/03-features/03-02-SUMMARY.md
</context>

<tasks>
<task type="auto">
  <name>Task 1: Build Dashboard controller and view</name>
  <files>app/controllers/dashboards_controller.rb, app/views/dashboards/show.html.erb</files>
  <action>Create DashboardsController#show with users and products data. Build responsive view with partials for user list and product list.</action>
  <verify>bundle exec rake test passes</verify>
  <done>Dashboard renders without errors</done>
</task>

<!-- Checkpoint pattern: Claude starts server, user visits URL. See checkpoints.md for full patterns. -->
<task type="auto">
  <name>Start dev server</name>
  <action>Run `bin/rails server` in background, wait for ready</action>
  <verify>curl localhost:3000 returns 200</verify>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>Dashboard - server at http://localhost:3000</what-built>
  <how-to-verify>Visit localhost:3000/dashboard. Check: desktop grid, mobile stack, no scroll issues.</how-to-verify>
  <resume-signal>Type "approved" or describe issues</resume-signal>
</task>
</tasks>

<verification>
- [ ] bundle exec rake test passes
- [ ] Visual verification passed
</verification>

<success_criteria>
- All tasks completed
- User approved visual layout
</success_criteria>

<output>
After completion, create `.ariadna_planning/phases/03-features/03-03-SUMMARY.md`
</output>
```

---

## Anti-Patterns

**Bad: Reflexive dependency chaining**
```yaml
depends_on: ["03-01"]  # Just because 01 comes before 02
```

**Bad: Horizontal layer grouping**
```
Plan 01: All models
Plan 02: All APIs (depends on 01)
Plan 03: All UIs (depends on 02)
```

**Bad: Missing autonomy flag**
```yaml
# Has checkpoint but no autonomous: false
depends_on: []
files_modified: [...]
# autonomous: ???  <- Missing!
```

**Bad: Vague tasks**
```xml
<task type="auto">
  <name>Set up authentication</name>
  <action>Add auth to the app</action>
</task>
```

---

## Guidelines

- Always use XML structure for Claude parsing
- Include `wave`, `depends_on`, `files_modified`, `autonomous` in every plan
- Prefer vertical slices over horizontal layers
- Only reference prior SUMMARYs when genuinely needed
- Group checkpoints with related auto tasks in same plan
- 2-3 tasks per plan, ~50% context max

---

## User Setup (External Services)

When a plan introduces external services requiring human configuration, declare in frontmatter:

```yaml
user_setup:
  - service: stripe
    why: "Payment processing requires API keys"
    env_vars:
      - name: STRIPE_SECRET_KEY
        source: "Stripe Dashboard → Developers → API keys → Secret key"
      - name: STRIPE_WEBHOOK_SECRET
        source: "Stripe Dashboard → Developers → Webhooks → Signing secret"
    dashboard_config:
      - task: "Create webhook endpoint"
        location: "Stripe Dashboard → Developers → Webhooks → Add endpoint"
        details: "URL: https://[your-domain]/api/webhooks/stripe"
    local_dev:
      - "stripe listen --forward-to localhost:3000/api/webhooks/stripe"
```

**The automation-first rule:** `user_setup` contains ONLY what Claude literally cannot do:
- Account creation (requires human signup)
- Secret retrieval (requires dashboard access)
- Dashboard configuration (requires human in browser)

**NOT included:** Package installs, code changes, file creation, CLI commands Claude can run.

**Result:** Execute-plan generates `{phase}-USER-SETUP.md` with checklist for the user.

See `~/.claude/ariadna/templates/user-setup.md` for full schema and examples

---

## Must-Haves (Goal-Backward Verification)

The `must_haves` field defines what must be TRUE for the phase goal to be achieved. Derived during planning, verified after execution.

**Structure:**

```yaml
must_haves:
  truths:
    - "User can see existing messages"
    - "User can send a message"
    - "Messages persist across refresh"
  artifacts:
    - path: "app/views/messages/index.html.erb"
      provides: "Message list rendering"
      min_lines: 30
    - path: "app/controllers/messages_controller.rb"
      provides: "Message CRUD operations"
      exports: ["index", "create"]
    - path: "app/models/message.rb"
      provides: "Message model"
      contains: "class Message"
  key_links:
    - from: "app/views/messages/index.html.erb"
      to: "messages_path"
      via: "form_with and turbo_stream"
      pattern: "form_with.*message"
    - from: "app/controllers/messages_controller.rb"
      to: "Message.where"
      via: "ActiveRecord query"
      pattern: "Message\\.(where|create|find)"
```

**Field descriptions:**

| Field | Purpose |
|-------|---------|
| `truths` | Observable behaviors from user perspective. Each must be testable. |
| `artifacts` | Files that must exist with real implementation. |
| `artifacts[].path` | File path relative to project root. |
| `artifacts[].provides` | What this artifact delivers. |
| `artifacts[].min_lines` | Optional. Minimum lines to be considered substantive. |
| `artifacts[].exports` | Optional. Expected exports to verify. |
| `artifacts[].contains` | Optional. Pattern that must exist in file. |
| `key_links` | Critical connections between artifacts. |
| `key_links[].from` | Source artifact. |
| `key_links[].to` | Target artifact or endpoint. |
| `key_links[].via` | How they connect (description). |
| `key_links[].pattern` | Optional. Regex to verify connection exists. |

**Why this matters:**

Task completion ≠ Goal achievement. A task "create chat component" can complete by creating a placeholder. The `must_haves` field captures what must actually work, enabling verification to catch gaps before they compound.

**Verification flow:**

1. Plan-phase derives must_haves from phase goal (goal-backward)
2. Must_haves written to PLAN.md frontmatter
3. Execute-phase runs all plans
4. Verification subagent checks must_haves against codebase
5. Gaps found → fix plans created → execute → re-verify
6. All must_haves pass → phase complete

See `~/.claude/ariadna/workflows/verify-phase.md` for verification logic.
