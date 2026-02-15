# Pitfalls Research Template

Template for `.planning/research/PITFALLS.md` — common mistakes to avoid in Ruby on Rails applications.

<template>

```markdown
# Pitfalls Research

**Rails Application:** [application name / domain]
**Rails Version:** [version]
**Ruby Version:** [version]
**Researched:** [date]
**Confidence:** [HIGH/MEDIUM/LOW]

## Critical Pitfalls

### Pitfall 1: N+1 Query Problems

**What goes wrong:**
[Describe where N+1 queries appear in this application — which models, associations, and controller actions trigger them]

**Why it happens:**
[Root cause — e.g., lazy loading by default, missing `includes`/`preload`/`eager_load` calls, new associations added without updating existing queries]

**How to avoid:**
[Prevention strategy — e.g., Bullet gem in development, strict_loading mode, query count assertions in tests]

**Warning signs:**
[How to detect early — e.g., slow page loads, high query counts in logs, Bullet notifications ignored]

**Example:**
```ruby
# Bad — triggers N+1
@posts = Post.all
@posts.each { |post| post.author.name }

# Good — eager loads association
@posts = Post.includes(:author).all
```

**Phase to address:**
[Which roadmap phase should prevent this]

---

### Pitfall 2: Callback Ordering and Side Effects

**What goes wrong:**
[Describe callback chains that cause unexpected behavior — e.g., `before_save` triggering external API calls, `after_create` callbacks running in wrong order, callbacks firing during migrations or seeds]

**Why it happens:**
[Root cause — e.g., business logic buried in callbacks instead of service objects, callbacks added incrementally without understanding full chain]

**How to avoid:**
[Prevention strategy — e.g., use service objects for complex logic, limit callbacks to data normalization, document callback chains]

**Warning signs:**
[How to detect early — e.g., mysterious side effects on save, tests requiring elaborate setup, callbacks calling other models that trigger their own callbacks]

**Example:**
```ruby
# Risky — side effects hidden in callback chain
class Order < ApplicationRecord
  after_create :charge_payment
  after_create :send_confirmation
  after_create :update_inventory
  after_create :notify_warehouse
end

# Better — explicit orchestration in a service object
class Orders::CreateService
  def call(params)
    order = Order.create!(params)
    PaymentService.charge(order)
    OrderMailer.confirmation(order).deliver_later
    InventoryService.update(order)
  end
end
```

**Phase to address:**
[Which roadmap phase should prevent this]

---

### Pitfall 3: Unsafe Migrations

**What goes wrong:**
[Describe migration risks in this application — e.g., adding columns with defaults locks tables, removing columns breaks running code, renaming columns causes downtime]

**Why it happens:**
[Root cause — e.g., not understanding how the database handles DDL locks, not using zero-downtime migration patterns, skipping `strong_migrations` gem]

**How to avoid:**
[Prevention strategy — e.g., strong_migrations gem, deploy migration before code that uses it, use `ignored_columns` for removals]

**Warning signs:**
[How to detect early — e.g., migrations that take too long in staging, lock timeout errors, failed deploys]

**Example:**
```ruby
# Dangerous — locks table on large datasets (PostgreSQL < 11; SQLite locks entire DB during writes)
add_column :users, :status, :string, default: "active"

# Safer — add column then backfill
add_column :users, :status, :string
# Then in a separate migration or rake task:
User.in_batches.update_all(status: "active")
change_column_default :users, :status, "active"
```

**Phase to address:**
[Which roadmap phase should prevent this]

---

### Pitfall 4: Mass Assignment / Strong Parameters Gaps

**What goes wrong:**
[Describe where strong parameters might be misconfigured — e.g., permitting too many attributes, nested attributes not properly scoped, admin-only fields exposed]

**Why it happens:**
[Root cause — e.g., copying `permit!` from StackOverflow, adding fields to permit list without review, forgetting nested attributes rules]

**How to avoid:**
[Prevention strategy — e.g., never use `permit!`, review parameter permits in code review, test that unpermitted attributes are rejected]

**Warning signs:**
[How to detect early — e.g., `Unpermitted parameter` warnings in logs being ignored, `permit!` in codebase, users able to modify fields they should not]

**Example:**
```ruby
# Dangerous — permits everything
params.require(:user).permit!

# Dangerous — admin fields exposed
params.require(:user).permit(:name, :email, :role, :admin)

# Safe — explicit whitelist, role handled separately
params.require(:user).permit(:name, :email)
```

**Phase to address:**
[Which roadmap phase should prevent this]

---

### Pitfall 5: Unscoped Tenant Data Leaks

**What goes wrong:**
[If multi-tenant: describe how queries without tenant scoping can leak data across tenants — e.g., missing `default_scope`, direct `find` calls, background jobs losing tenant context]

**Why it happens:**
[Root cause — e.g., tenant scoping not enforced at the framework level, new developers unaware of scoping requirements, background jobs not carrying tenant context]

**How to avoid:**
[Prevention strategy — e.g., Current attributes for tenant context, controller-level `around_action` for scoping, test isolation per tenant]

**Warning signs:**
[How to detect early — e.g., queries without `WHERE tenant_id = ?`, cross-tenant data appearing in tests, background jobs processing wrong tenant data]

**Phase to address:**
[Which roadmap phase should prevent this]

---

### Pitfall 6: Gem Version Conflicts and Abandoned Dependencies

**What goes wrong:**
[Describe dependency risks — e.g., gems pinned to old versions blocking Rails upgrades, abandoned gems with security vulnerabilities, transitive dependency conflicts]

**Why it happens:**
[Root cause — e.g., adding gems without evaluating maintenance status, not running `bundle audit`, version pins too strict or too loose]

**How to avoid:**
[Prevention strategy — e.g., regular `bundle audit`, evaluate gem health before adding, prefer stdlib or well-maintained gems, document why each gem is needed]

**Warning signs:**
[How to detect early — e.g., `bundle update` failures, security advisories ignored, gems with no commits in 2+ years]

**Phase to address:**
[Which roadmap phase should prevent this]

---

### Pitfall 7: Explicit Translation Keys Instead of ActiveRecord Automatic Lookup

**What goes wrong:**
[Describe where explicit `t()` calls duplicate what Rails I18n automatic lookup provides — e.g., form labels passing explicit keys, validation messages hardcoded, model names translated manually]

**Why it happens:**
[Root cause — e.g., developers unaware of ActiveRecord I18n conventions, copying patterns from non-Rails projects, not reading Rails I18n guide]

**How to avoid:**
[Prevention strategy — e.g., use `form.label :name` instead of `form.label :name, t("teams.form.name")`, define translations under `activerecord.attributes.*` and `activerecord.models.*`, rely on automatic lookup for validation messages]

**Warning signs:**
[How to detect early — e.g., duplicate translation keys for the same attribute in different namespaces, inconsistent labels between forms and error messages, `t()` calls in form labels that mirror `activerecord.attributes` keys]

**Example:**
```ruby
# Bad — explicit key duplicates what Rails provides automatically
<%= form.label :name, t("teams.form.name") %>
# Requires: teams.form.name in locale file AND activerecord.attributes.team.name for validations

# Good — resolves from activerecord.attributes.team.name automatically
<%= form.label :name %>
# Single source of truth: activerecord.attributes.team.name used by forms AND validations
```

```yaml
# Good — single source of truth for attribute names
en:
  activerecord:
    models:
      team: "Team"
    attributes:
      team:
        name: "Team name"
    errors:
      models:
        team:
          attributes:
            name:
              blank: "cannot be empty"
```

**Phase to address:**
[Which roadmap phase should prevent this]

---

[Continue for additional critical pitfalls specific to this application...]

## Technical Debt Patterns

Rails-specific shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skipping database constraints (relying only on model validations) | [benefit — e.g., faster development, easier to change] | [cost — e.g., data integrity issues from console/jobs/race conditions] | [conditions, or "never"] |
| Raw SQL instead of ActiveRecord | [benefit — e.g., complex query works immediately] | [cost — e.g., database-specific, skips scopes/hooks, hard to maintain] | [conditions — e.g., reporting queries, performance-critical reads] |
| Monkeypatching gems instead of proper extension | [benefit — e.g., quick fix for gem behavior] | [cost — e.g., breaks on gem updates, hidden behavior, untestable] | [conditions, or "never"] |
| Skipping tests / low test coverage | [benefit — e.g., ships faster initially] | [cost — e.g., regressions, fear of refactoring, broken deploys] | [conditions, or "never"] |
| `skip_before_action` proliferation | [benefit — e.g., quick auth bypass for specific actions] | [cost — e.g., security holes, hard to audit which actions are protected] | [conditions — e.g., health checks only] |
| Fat models with mixed concerns | [benefit — e.g., everything in one place] | [cost — e.g., 1000+ line models, tangled logic, slow tests] | [conditions, or "never"] |
| Using `default_scope` | [benefit — e.g., automatic filtering] | [cost — e.g., surprising query behavior, hard to override, breaks joins] | [conditions, or "never"] |
| Storing state in session instead of database | [benefit — e.g., no migration needed] | [cost — e.g., lost on logout, can't query, no audit trail] | [conditions — e.g., ephemeral wizard state only] |
| [shortcut] | [benefit] | [cost] | [conditions, or "never"] |

## Integration Gotchas

Common mistakes when integrating Rails gems and external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Authentication | [e.g., not understanding the generated `Authentication` concern flow, missing `allow_unauthenticated_access`, session fixation on login] | [what to do instead] |
| Solid Queue / background jobs | [e.g., passing ActiveRecord objects instead of IDs, no retry configuration, no error handling] | [what to do instead] |
| ActionCable / WebSockets | [e.g., broadcasting without authorization, no connection authentication, memory leaks from unsubscribed channels] | [what to do instead] |
| ActiveStorage / file uploads | [e.g., missing virus scanning, no file size limits, serving user uploads from same domain] | [what to do instead] |
| Turbo / Hotwire | [e.g., full page reloads from misconfigured frames, missing turbo stream responses, form submission edge cases] | [what to do instead] |
| Rails version upgrades | [e.g., skipping deprecation warnings, upgrading multiple major versions at once, not running `rails app:update`] | [what to do instead] |
| Third-party APIs | [e.g., no circuit breaker, synchronous calls in request cycle, no webhook signature verification] | [what to do instead] |
| I18n / rails-i18n | [e.g., using explicit `t()` keys for model attributes and form labels instead of ActiveRecord automatic lookup, missing `rails-i18n` gem for CLDR data (dates, currency, numbers), inconsistent locale file organization mixing per-model and flat structures] | [e.g., define translations under `activerecord.attributes.*` and `activerecord.models.*`, use `form.label :field` without explicit `t()`, add `rails-i18n` gem for base locale data, organize locale files consistently] |
| [integration] | [what people do wrong] | [what to do instead] |

## Performance Traps

Rails patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Missing database indexes | [e.g., slow queries on `WHERE` and `ORDER BY` columns, sequential scans in `EXPLAIN`] | [e.g., add indexes for foreign keys, frequently queried columns, compound indexes for common query patterns] | [scale threshold — e.g., 100k+ rows] |
| Eager loading mistakes | [e.g., N+1 in views, or over-eager loading pulling entire tables into memory] | [e.g., use `includes` for used associations, `strict_loading` to catch missed ones, Bullet gem] | [scale threshold] |
| Missing counter caches | [e.g., `COUNT(*)` queries on every page load for association counts] | [e.g., `counter_cache: true` on `belongs_to`, reset counters in migrations] | [scale threshold — e.g., 10k+ parent records] |
| Fragment caching not used or invalidated incorrectly | [e.g., slow view rendering, stale data displayed, cache keys not including updated_at] | [e.g., Russian doll caching with `cache [record, "v2"]`, touch associations, cache digests] | [scale threshold] |
| Serialization in hot paths | [e.g., `to_json` on large objects in loops, Jbuilder rendering slowly] | [e.g., use `oj` gem, precompute serialized data, avoid serialization in loops] | [scale threshold] |
| Large file uploads blocking web workers | [e.g., Puma workers tied up during upload, request timeouts, memory spikes] | [e.g., direct-to-cloud uploads with presigned URLs, ActiveStorage direct upload, nginx upload module] | [scale threshold — e.g., files > 10MB] |
| Unoptimized ActiveRecord queries | [e.g., loading full records when only IDs needed, `select *` on wide tables] | [e.g., `pluck`, `select`, `find_each` for batches, `exists?` instead of `present?` on relations] | [scale threshold] |
| [trap] | [symptoms] | [prevention] | [scale threshold] |

## Security Mistakes

Rails-specific security issues beyond basic web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| SQL injection via string interpolation in `where` | [e.g., user input directly in query string allows data exfiltration] | [e.g., always use parameterized queries: `where("name = ?", params[:name])` or hash syntax `where(name: params[:name])`] |
| CSRF token handling gaps | [e.g., API endpoints without `protect_from_forgery`, token not verified on state-changing requests] | [e.g., `protect_from_forgery with: :exception`, proper token handling for JS requests, `csrf_meta_tags` in layout] |
| Credential management mistakes | [e.g., secrets in ENV vars without encryption, credentials checked into git, different credentials per environment not managed] | [e.g., Rails encrypted credentials, `rails credentials:edit`, per-environment credential files] |
| Insecure direct object references | [e.g., `User.find(params[:id])` without authorization check, enumerable IDs exposing records] | [e.g., always scope to authorized records: `current_user.posts.find(params[:id])`, use Current.account or Current.employee] |
| Mass assignment vulnerabilities | [e.g., unpermitted nested attributes modifying admin fields, `accepts_nested_attributes_for` without `reject_if`] | [e.g., explicit strong parameters, test that admin attributes cannot be set via API, `attr_readonly` for sensitive fields] |
| Unsafe `html_safe` / `raw` usage | [e.g., XSS from marking user input as safe, rendering unescaped HTML from database] | [e.g., never call `html_safe` on user input, use `sanitize` helper, Content Security Policy headers] |
| Open redirects | [e.g., `redirect_to params[:return_to]` allows redirecting to malicious sites] | [e.g., validate redirect URLs against allowlist, use `redirect_back` with `fallback_location`] |
| [mistake] | [risk] | [prevention] |

## "Looks Done But Isn't" Checklist

Rails features that appear complete but are missing critical pieces.

- [ ] **Database indexes:** Foreign key columns (`*_id`) have indexes — verify with `rails db:schema:dump` and check `schema.rb`
- [ ] **Background job error handling:** Jobs have `retry_on` / `discard_on` configured — verify jobs don't silently fail, dead letter queue is monitored
- [ ] **Database constraints match validations:** Model validations have corresponding `NOT NULL`, uniqueness indexes, and foreign keys at database level — verify with `active_record_doctor` or `database_consistency` gem
- [ ] **Association cleanup:** `has_many` associations have `dependent: :destroy` or `dependent: :nullify` — verify no orphaned records after parent deletion
- [ ] **Rate limiting:** Public-facing endpoints have rate limiting — verify with `rack-attack` or similar middleware configuration
- [ ] **Background job idempotency:** Jobs can safely be retried without duplicate side effects — verify by running job twice with same arguments
- [ ] **Error tracking:** Exceptions are reported to monitoring service — verify error paths actually reach error tracker (Sentry, Rollbar, etc.)
- [ ] **Database connection pooling:** Pool size matches worker/thread count — verify `database.yml` pool matches Puma thread count
- [ ] **Timezone handling:** Application uses `Time.current` / `Date.current` instead of `Time.now` / `Date.today` — verify `config.time_zone` is set and used consistently
- [ ] **Email delivery:** Mailers use `deliver_later` not `deliver_now` in web requests — verify mailer calls don't block request cycle
- [ ] **I18n locale completeness:** All supported locales have matching keys for `activerecord.models.*`, `activerecord.attributes.*`, and `activerecord.errors.*` — verify with `i18n-tasks` gem or manual comparison that no locale is missing translations present in others
- [ ] **[Feature]:** Often missing [thing] — verify [check]
- [ ] **[Feature]:** Often missing [thing] — verify [check]

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| N+1 queries in production | LOW | [e.g., add `includes` calls, deploy, verify with query logs] |
| Missing database indexes | LOW | [e.g., add index migration, deploy during low-traffic, monitor query performance] |
| Data integrity issues from missing DB constraints | HIGH | [e.g., add constraints, write data cleanup migration, backfill invalid records] |
| Callback spaghetti | MEDIUM | [e.g., extract to service objects incrementally, add integration tests first] |
| Unsafe migration ran on production | HIGH | [e.g., assess damage, write corrective migration, consider rollback, schedule maintenance window] |
| Security vulnerability in dependency | MEDIUM | [e.g., `bundle audit`, update gem, assess exposure, check logs for exploitation] |
| [pitfall] | LOW/MEDIUM/HIGH | [recovery steps] |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| N+1 queries | Phase [X] | [e.g., query count assertions in integration tests, Bullet gem in CI] |
| Callback side effects | Phase [X] | [e.g., service objects documented, callback audit complete] |
| Unsafe migrations | Phase [X] | [e.g., strong_migrations gem installed, CI rejects unsafe migrations] |
| Mass assignment gaps | Phase [X] | [e.g., strong parameters tested, no `permit!` in codebase] |
| Missing database constraints | Phase [X] | [e.g., `database_consistency` gem passes, schema reviewed] |
| Missing indexes | Phase [X] | [e.g., all foreign keys indexed, slow query log clean] |
| Security vulnerabilities | Phase [X] | [e.g., `brakeman` passes, `bundle audit` clean, CSRF verified] |
| [pitfall] | Phase [X] | [how to verify prevention worked] |

## Sources

- [Rails Guides security section referenced]
- [Community discussions — e.g., Rails subreddit, GoRails, Drifting Ruby]
- [Official Rails "gotchas" / upgrade guides]
- [Gem documentation — strong_migrations, Bullet, Brakeman, etc.]
- [Post-mortems / incident reports]
- [Personal experience / known issues]

---
*Pitfalls research for: [application name / domain]*
*Rails version: [version]*
*Researched: [date]*
```

</template>

<guidelines>

**Critical Pitfalls:**
- Focus on Rails-specific failure modes, not generic programming mistakes
- Include concrete Ruby code examples showing the wrong and right approach
- Include warning signs — early detection prevents production incidents
- Link to specific phases — makes pitfalls actionable in the roadmap
- Cover the full Rails stack: ActiveRecord, ActionController, ActionMailer, ActiveJob, ActionCable

**Technical Debt:**
- Be realistic — some shortcuts are acceptable in early phases (MVP, prototype)
- Note when shortcuts are "never acceptable" (e.g., `permit!`, skipping DB constraints on financial data)
- Include the long-term cost to inform tradeoff decisions
- Rails-specific: distinguish between "Rails way" shortcuts and "anti-Rails" shortcuts

**Performance Traps:**
- Include scale thresholds ("breaks at 100k rows", "10k concurrent users")
- Focus on what is relevant for this application's expected scale
- Prioritize database-level optimizations — they have the highest impact in Rails apps
- Include both read-path and write-path performance considerations

**Security Mistakes:**
- Beyond OWASP basics — focus on Rails-specific vectors (mass assignment, CSRF, `html_safe`)
- Use Brakeman categories as a reference for common Rails security issues
- Include credential management approach (Rails credentials vs. ENV vs. secrets manager)
- Note which security issues are caught by Rails defaults vs. require explicit configuration

**Integration Gotchas:**
- Cover common Rails gem integration issues (authentication generator, Solid Queue, Turbo, ActiveStorage)
- Include Rails version upgrade pain points — deprecated APIs, changed defaults
- Note gems that are known to conflict or require specific version coordination

**"Looks Done But Isn't":**
- Checklist format for verification during execution and code review
- Focus on the gap between "works in development" and "production-ready"
- Include database-level checks that are easy to miss (indexes, constraints, connection pool)
- Cover operational readiness items (error tracking, job monitoring, email delivery)

**Pitfall-to-Phase Mapping:**
- Critical for roadmap creation — each pitfall should map to a phase that prevents it
- Early phases should address foundational issues (database schema, authentication)
- Later phases should address optimization issues (caching, performance, scaling)
- Verification should be automated where possible (CI checks, gem-based audits)

</guidelines>
