# Codebase Concerns Template

Template for `.planning/codebase/CONCERNS.md` - captures known issues and areas requiring care.

**Purpose:** Surface actionable warnings about the codebase. Focused on "what to watch out for when making changes."

---

## File Template

```markdown
# Codebase Concerns

**Analysis Date:** [YYYY-MM-DD]

## Tech Debt

**[Area/Component]:**
- Issue: [What's the shortcut/workaround]
- Why: [Why it was done this way]
- Impact: [What breaks or degrades because of it]
- Fix approach: [How to properly address it]

**[Area/Component]:**
- Issue: [What's the shortcut/workaround]
- Why: [Why it was done this way]
- Impact: [What breaks or degrades because of it]
- Fix approach: [How to properly address it]

## Known Bugs

**[Bug description]:**
- Symptoms: [What happens]
- Trigger: [How to reproduce]
- Workaround: [Temporary mitigation if any]
- Root cause: [If known]
- Blocked by: [If waiting on something]

**[Bug description]:**
- Symptoms: [What happens]
- Trigger: [How to reproduce]
- Workaround: [Temporary mitigation if any]
- Root cause: [If known]

## Security Considerations

**[Area requiring security care]:**
- Risk: [What could go wrong]
- Current mitigation: [What's in place now]
- Recommendations: [What should be added]

**[Area requiring security care]:**
- Risk: [What could go wrong]
- Current mitigation: [What's in place now]
- Recommendations: [What should be added]

## Performance Bottlenecks

**[Slow operation/endpoint]:**
- Problem: [What's slow]
- Measurement: [Actual numbers: "500ms p95", "2s load time"]
- Cause: [Why it's slow]
- Improvement path: [How to speed it up]

**[Slow operation/endpoint]:**
- Problem: [What's slow]
- Measurement: [Actual numbers]
- Cause: [Why it's slow]
- Improvement path: [How to speed it up]

## Fragile Areas

**[Component/Module]:**
- Why fragile: [What makes it break easily]
- Common failures: [What typically goes wrong]
- Safe modification: [How to change it without breaking]
- Test coverage: [Is it tested? Gaps?]

**[Component/Module]:**
- Why fragile: [What makes it break easily]
- Common failures: [What typically goes wrong]
- Safe modification: [How to change it without breaking]
- Test coverage: [Is it tested? Gaps?]

## Scaling Limits

**[Resource/System]:**
- Current capacity: [Numbers: "100 req/sec", "10k users"]
- Limit: [Where it breaks]
- Symptoms at limit: [What happens]
- Scaling path: [How to increase capacity]

## Dependencies at Risk

**[Gem/Service]:**
- Risk: [e.g., "deprecated", "unmaintained", "breaking changes coming"]
- Impact: [What breaks if it fails]
- Migration plan: [Alternative or upgrade path]

## Missing Critical Features

**[Feature gap]:**
- Problem: [What's missing]
- Current workaround: [How users cope]
- Blocks: [What can't be done without it]
- Implementation complexity: [Rough effort estimate]

## Test Coverage Gaps

**[Untested area]:**
- What's not tested: [Specific functionality]
- Risk: [What could break unnoticed]
- Priority: [High/Medium/Low]
- Difficulty to test: [Why it's not tested yet]

---

*Concerns audit: [date]*
*Update as issues are fixed or new ones discovered*
```

<good_examples>
```markdown
# Codebase Concerns

**Analysis Date:** 2025-01-20

## Tech Debt

**N+1 queries in controllers:**
- Issue: Direct `@board.cards` iteration without eager loading in 8+ controller actions
- Files: `app/controllers/boards_controller.rb`, `app/controllers/cards_controller.rb`, `app/controllers/dashboards_controller.rb`
- Why: Rapid prototyping during MVP phase, controllers grew organically
- Impact: Index pages fire 50+ queries on boards with many cards, p95 response time over 800ms
- Fix approach: Add `preloaded` scope to Card model using `includes(:assignees, :tags, :closure, :column)`, use in controllers

**Business logic in controllers:**
- Issue: `CardsController#create` contains 40 lines of inline notification, assignment, and event-tracking logic
- Files: `app/controllers/cards_controller.rb` (lines 25-65), `app/controllers/comments_controller.rb` (lines 18-42)
- Why: Features added incrementally without extracting to model layer
- Impact: Same logic duplicated between controller and background job, behavior differs depending on entry point
- Fix approach: Move to model methods and concerns (`Card::Notifiable`, `Card::Assignable`), controller calls single method

**Missing concern extraction in User model:**
- Issue: `User` model is 520 lines with inline notification preferences, filtering, avatar handling, and role checks
- File: `app/models/user.rb`
- Why: Grew over time without periodic refactoring
- Impact: Hard to test individual behaviors, merge conflicts when multiple developers touch User
- Fix approach: Extract to `User::Filterable`, `User::NotificationPreferences`, `User::Avatars`, `User::Roles` in `app/models/user/`

## Known Bugs

**ActiveRecord callback ordering on Card creation:**
- Symptoms: Cards created without sequential number when `before_create` callbacks run out of order
- Trigger: Creating a card while another `before_create` sets `board` association via lambda default
- Files: `app/models/card.rb` (line 12, `before_create :set_number`), `app/models/concerns/eventable.rb`
- Workaround: Database-level default fills in number on save, but numbering can have gaps
- Root cause: `belongs_to :board` must be declared before `before_create :set_number` because `set_number` depends on `board.account`

**Race condition in background notification jobs:**
- Symptoms: Duplicate notifications sent when card is assigned to multiple users simultaneously
- Trigger: Bulk assignment via board import or API, multiple `NotifyAssigneeJob` enqueued at once
- Files: `app/jobs/notify_assignee_job.rb`, `app/models/card/assignable.rb`
- Workaround: Unique constraint on `notifications` table prevents duplicates at DB level, but jobs error with `ActiveRecord::RecordNotUnique`
- Root cause: No idempotency check in job before creating notification
- Fix: Add `find_or_create_by` guard in `Card#notify_assignee`

**Stale Current context in async operations:**
- Symptoms: Background jobs occasionally run with wrong tenant context, creating records in wrong account
- Trigger: Job enqueued during request A, executed during request B on same thread in development
- File: `app/jobs/application_job.rb`
- Workaround: Production uses separate Solid Queue process (not affected), only impacts development with inline adapter
- Root cause: `Current.account` not properly reset between inline job executions in development

**Turbo Stream partial not updating after card close:**
- Symptoms: Card status badge shows "Open" after closing via Turbo Stream until page refresh
- Trigger: Close card from board view when card partial uses cached fragment
- Files: `app/views/cards/_card.html.erb`, `app/controllers/cards/closures_controller.rb`
- Workaround: Hard refresh updates correctly
- Root cause: Fragment cache key does not include `closure` association, stale cached partial served after Turbo Stream replace

## Security Considerations

**Mass assignment on User update:**
- Risk: `UsersController#update` permits `role` parameter — users could escalate to admin via crafted request
- File: `app/controllers/users_controller.rb` (line 34, `user_params` method)
- Current mitigation: Frontend form does not display role field
- Recommendations: Remove `role` from `permit()` list, add separate `Admin::UsersController` for role changes with proper authorization

**Missing authorization checks on nested resources:**
- Risk: Card comments endpoint does not verify user has access to the parent board
- Files: `app/controllers/comments_controller.rb`, missing `authorize @comment` call
- Current mitigation: Obscured by UUID-based URLs (hard to guess)
- Recommendations: Add Pundit `authorize` call or `before_action` scope check, add `CommentPolicy` with board-access verification

**Unscoped queries leaking tenant data:**
- Risk: `Admin::ReportsController` uses `Card.where(created_at: range)` without `Current.account` scope
- File: `app/controllers/admin/reports_controller.rb` (line 22)
- Current mitigation: Admin area behind authentication, but any admin sees all tenants' data
- Recommendations: Scope all queries through `Current.account.cards` or add `default_scope` guard in multi-tenant models

**SQL injection via string interpolation in search:**
- Risk: `Card.where("title LIKE '%#{params[:q]}%'")` in search controller
- File: `app/controllers/search_controller.rb` (line 15)
- Current mitigation: None
- Recommendations: Use parameterized query `Card.where("title LIKE ?", "%#{Card.sanitize_sql_like(params[:q])}%")` or the `Searchable` concern's safe search scope

## Performance Bottlenecks

**Boards index page (N+1 queries):**
- Problem: Loading boards with card counts, latest activity, and member avatars
- File: `app/controllers/boards_controller.rb` (line 8, `index` action)
- Measurement: 1.8s p95 response time with 30+ boards, 847ms with counter cache
- Cause: N+1 on `board.cards.count`, `board.cards.order(updated_at: :desc).first`, and `board.members`
- Improvement path: Add `cards_count` counter cache to `boards` table, use `includes(:members)` and preload latest card via window function scope

**Heavy after_save callbacks on Card:**
- Problem: Saving a card triggers cache invalidation, search reindexing, and event tracking
- Files: `app/models/card.rb`, `app/models/concerns/searchable.rb`, `app/models/concerns/eventable.rb`
- Measurement: Card save takes 120ms vs 15ms for a plain ActiveRecord save
- Cause: `after_save` callbacks for `reindex_search`, `invalidate_board_cache`, and `track_changes` all run synchronously
- Improvement path: Move `reindex_search` and `invalidate_board_cache` to `after_commit` with `perform_later` jobs

**Missing database indexes:**
- Problem: Slow queries on card filtering and sorting
- Files: `db/migrate/` (missing indexes), query visible in `app/models/card.rb` scopes
- Measurement: `Card.where(board_id: id).where(status: "open").order(position: :asc)` does full table scan on 10k+ cards
- Cause: Composite index on `[board_id, status, position]` never added
- Improvement path: Add migration with `add_index :cards, [:board_id, :status, :position]`

## Fragile Areas

**Concern chain in Card model:**
- Files: `app/models/card.rb`, `app/models/card/closeable.rb`, `app/models/card/golden.rb`, `app/models/card/eventable.rb`, `app/models/concerns/eventable.rb`
- Why fragile: Card includes 20+ concerns that can override each other's hooks. `Card::Eventable` layers on top of `::Eventable` with template method overrides
- Common failures: Adding a new concern that defines `after_save` changes callback execution order, breaking event tracking or cache invalidation
- Safe modification: Always check existing callback chain with `Card._save_callbacks.map(&:filter)` before adding. Add tests for callback ordering
- Test coverage: Individual concern tests exist, but no integration test verifying the full callback chain

**Callback ordering dependencies:**
- Files: `app/models/card.rb`, `app/models/concerns/eventable.rb`
- Why fragile: `before_create :set_number` depends on `board` being set, which depends on `belongs_to :board` declaration order
- Common failures: Moving association declarations or reordering `include` statements breaks number generation
- Safe modification: Never reorder `include` or `belongs_to` declarations without verifying dependent callbacks. Add comments documenting ordering constraints
- Test coverage: Happy path tested, but ordering-dependent edge cases not covered

**Multi-tenancy scoping:**
- Files: `app/models/current.rb`, `app/controllers/application_controller.rb`, `app/jobs/application_job.rb`
- Why fragile: Missing `Current.account` scope in any query leaks data across tenants
- Common failures: New controller action or background job forgets to scope through `Current.account` or `Current.user`
- Safe modification: Always query through `Current.user.boards` or `Current.account.cards`, never use unscoped `Card.find`. Add CI check for unscoped model queries in controllers
- Test coverage: No automated test for tenant isolation across all endpoints

## Scaling Limits

**PostgreSQL connection pool:**
- Current capacity: 20 connections (default `pool` in `config/database.yml`)
- Limit: With Solid Queue workers + Puma (5 workers x 5 threads), need 50+ connections
- Symptoms at limit: `ActiveRecord::ConnectionTimeoutError` in background jobs during peak load
- Scaling path: Increase `pool` to match total thread count, configure PgBouncer for connection multiplexing

**Solid Queue worker memory usage:**
- Current capacity: Single Solid Queue worker process, 512MB RAM
- Limit: Import jobs loading full CSV into memory hit OOM at ~50k rows
- Symptoms at limit: Worker process killed by OOM killer, jobs remain in database as claimed (require manual release)
- Scaling path: Stream CSV processing with `CSV.foreach`, batch database inserts with `insert_all`

## Dependencies at Risk

**Outdated gems with security patches:**
- Risk: `nokogiri` pinned to 1.14.x, 3 known CVEs in current version
- Impact: XML/HTML parsing vulnerable to crafted payloads
- Migration plan: Update to latest nokogiri, run test suite, check for API changes

**Deprecated Rails APIs:**
- Risk: Application uses classic autoloader references and `config.active_record.legacy_connection_handling`
- Files: `config/application.rb` (line 18), `config/environments/production.rb` (line 45)
- Impact: Will break on Rails 8 upgrade
- Migration plan: Switch to Zeitwerk autoloader conventions, remove legacy connection config, run `rails zeitwerk:check`

## Missing Critical Features

**Audit trail for admin actions:**
- Problem: No record of which admin changed user roles, deleted boards, or modified account settings
- Current workaround: Check Rails logs manually (unreliable, logs rotate)
- Blocks: Compliance requirements, incident investigation
- Implementation complexity: Medium (extend `Eventable` concern to admin controllers, add `AdminEvent` model)

**Soft delete for cards:**
- Problem: Card deletion is permanent, no recovery possible
- Current workaround: Users told to close cards instead of deleting
- Blocks: Accidental deletion recovery, trash/archive feature
- Implementation complexity: Low (add `discarded_at` column, use `discard` gem or manual scope `kept`)

## Test Coverage Gaps

**Model concern integration tests:**
- What's not tested: How concerns interact when composed together on Card (e.g., closing a golden card, postponing an assigned card)
- Risk: Concern interactions could produce unexpected behavior — callbacks from one concern conflicting with another
- Priority: High
- Difficulty to test: Need fixtures with multiple concern states, test matrix grows combinatorially

**Controller integration tests for authorization:**
- What's not tested: Whether non-admin users are properly blocked from admin actions, whether cross-tenant access is denied
- Risk: Authorization bypass, tenant data leakage
- Priority: High
- Difficulty to test: Need multi-tenant test setup with separate user contexts per tenant

**System tests for Turbo Stream flows:**
- What's not tested: Card state changes via Turbo Stream (close, reopen, assign) update DOM correctly without page reload
- Risk: UI shows stale state after actions, users see incorrect card status
- Priority: Medium
- Difficulty to test: Need Capybara with JavaScript driver, Turbo Stream assertions not built into Rails default test helpers

---

*Concerns audit: 2025-01-20*
*Update as issues are fixed or new ones discovered*
```
</good_examples>

<guidelines>
**What belongs in CONCERNS.md:**
- Tech debt with clear impact and fix approach
- Known bugs with reproduction steps
- Security gaps and mitigation recommendations
- Performance bottlenecks with measurements
- Fragile code that breaks easily
- Scaling limits with numbers
- Dependencies that need attention
- Missing features that block workflows
- Test coverage gaps

**What does NOT belong here:**
- Opinions without evidence ("code is messy")
- Complaints without solutions ("auth sucks")
- Future feature ideas (that's for product planning)
- Normal TODOs (those live in code comments)
- Architectural decisions that are working fine
- Minor code style issues

**When filling this template:**
- **Always include file paths** - Concerns without locations are not actionable. Use backticks: `app/models/user.rb`
- Be specific with measurements ("500ms p95" not "slow")
- Include reproduction steps for bugs
- Suggest fix approaches, not just problems
- Focus on actionable items
- Prioritize by risk/impact
- Update as issues get resolved
- Add new concerns as discovered

**Analysis approach for Rails codebases:**
- Check `app/models/` for fat models (300+ lines without concerns), N+1 patterns in scopes, missing validations
- Review `app/controllers/` for business logic that belongs in models, missing `authorize` calls, unpermitted params
- Scan `app/models/concerns/` for concerns with tangled dependencies or overlapping responsibilities
- Look at `db/schema.rb` for missing indexes on foreign keys (`_id` columns) and frequently queried columns
- Check `app/jobs/` for jobs with inline logic instead of delegating to model methods, missing `Current` context handling
- Review `config/routes.rb` for non-RESTful custom actions that should be modeled as sub-resources
- Check `test/` for missing model tests, controller tests without authorization assertions, absence of system tests
- Scan `Gemfile.lock` for outdated gems with known CVEs using `bundle audit`
- Look at `app/views/` for queries in templates (N+1 hidden in partials) and missing fragment cache keys

**Tone guidelines:**
- Professional, not emotional ("N+1 query pattern" not "terrible queries")
- Solution-oriented ("Fix: add `includes` scope" not "needs fixing")
- Risk-focused ("Could expose tenant data across accounts" not "security is bad")
- Factual ("1.8s p95 load time" not "really slow")

**Useful for phase planning when:**
- Deciding what to work on next
- Estimating risk of changes
- Understanding where to be careful
- Prioritizing improvements
- Onboarding new Claude contexts
- Planning refactoring work

**How this gets populated:**
Explore agents detect these during codebase mapping. Manual additions welcome for human-discovered issues. This is living documentation, not a complaint list.
</guidelines>
