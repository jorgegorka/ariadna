# Research Template

Template for `.ariadna_planning/phases/XX-name/{phase}-RESEARCH.md` - comprehensive ecosystem research before planning.

**Purpose:** Document what Claude needs to know to implement a phase well - not just "which library" but "how do experts build this."

---

## File Template

```markdown
# Phase [X]: [Name] - Research

**Researched:** [date]
**Domain:** [primary technology/problem domain]
**Confidence:** [HIGH/MEDIUM/LOW]

<user_constraints>
## User Constraints (from CONTEXT.md)

**CRITICAL:** If CONTEXT.md exists from /ariadna:discuss-phase, copy locked decisions here verbatim. These MUST be honored by the planner.

### Locked Decisions
[Copy from CONTEXT.md `## Decisions` section - these are NON-NEGOTIABLE]
- [Decision 1]
- [Decision 2]

### Claude's Discretion
[Copy from CONTEXT.md - areas where researcher/planner can choose]
- [Area 1]
- [Area 2]

### Deferred Ideas (OUT OF SCOPE)
[Copy from CONTEXT.md - do NOT research or plan these]
- [Deferred 1]
- [Deferred 2]

**If no CONTEXT.md exists:** Write "No user constraints - all decisions at Claude's discretion"
</user_constraints>

<research_summary>
## Summary

[2-3 paragraph executive summary]
- What was researched
- What the standard approach is
- Key recommendations

**Primary recommendation:** [one-liner actionable guidance]
</research_summary>

<standard_stack>
## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| [name] | [ver] | [what it does] | [why experts use it] |
| [name] | [ver] | [what it does] | [why experts use it] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| [name] | [ver] | [what it does] | [use case] |
| [name] | [ver] | [what it does] | [use case] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| [standard] | [alternative] | [when alternative makes sense] |

**Installation:**
```bash
bundle add [gems]
# or add to Gemfile and run:
bundle install
```
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Recommended Project Structure
```
app/
├── [folder]/        # [purpose]
├── [folder]/        # [purpose]
└── [folder]/        # [purpose]
```

### Pattern 1: [Pattern Name]
**What:** [description]
**When to use:** [conditions]
**Example:**
```ruby
# [code example from Context7/official docs]
```

### Pattern 2: [Pattern Name]
**What:** [description]
**When to use:** [conditions]
**Example:**
```ruby
# [code example]
```

### Anti-Patterns to Avoid
- **[Anti-pattern]:** [why it's bad, what to do instead]
- **[Anti-pattern]:** [why it's bad, what to do instead]
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| [problem] | [what you'd build] | [library] | [edge cases, complexity] |
| [problem] | [what you'd build] | [library] | [edge cases, complexity] |
| [problem] | [what you'd build] | [library] | [edge cases, complexity] |

**Key insight:** [why custom solutions are worse in this domain]
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: [Name]
**What goes wrong:** [description]
**Why it happens:** [root cause]
**How to avoid:** [prevention strategy]
**Warning signs:** [how to detect early]

### Pitfall 2: [Name]
**What goes wrong:** [description]
**Why it happens:** [root cause]
**How to avoid:** [prevention strategy]
**Warning signs:** [how to detect early]

### Pitfall 3: [Name]
**What goes wrong:** [description]
**Why it happens:** [root cause]
**How to avoid:** [prevention strategy]
**Warning signs:** [how to detect early]
</common_pitfalls>

<code_examples>
## Code Examples

Verified patterns from official sources:

### [Common Operation 1]
```ruby
# Source: [Context7/official docs URL]
[code]
```

### [Common Operation 2]
```ruby
# Source: [Context7/official docs URL]
[code]
```

### [Common Operation 3]
```ruby
# Source: [Context7/official docs URL]
[code]
```
</code_examples>

<sota_updates>
## State of the Art (2024-2025)

What's changed recently:

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| [old] | [new] | [date/version] | [what it means for implementation] |

**New tools/patterns to consider:**
- [Tool/Pattern]: [what it enables, when to use]
- [Tool/Pattern]: [what it enables, when to use]

**Deprecated/outdated:**
- [Thing]: [why it's outdated, what replaced it]
</sota_updates>

<open_questions>
## Open Questions

Things that couldn't be fully resolved:

1. **[Question]**
   - What we know: [partial info]
   - What's unclear: [the gap]
   - Recommendation: [how to handle during planning/execution]

2. **[Question]**
   - What we know: [partial info]
   - What's unclear: [the gap]
   - Recommendation: [how to handle]
</open_questions>

<sources>
## Sources

### Primary (HIGH confidence)
- [Context7 library ID] - [topics fetched]
- [Official docs URL] - [what was checked]

### Secondary (MEDIUM confidence)
- [WebSearch verified with official source] - [finding + verification]

### Tertiary (LOW confidence - needs validation)
- [WebSearch only] - [finding, marked for validation during implementation]
</sources>

<metadata>
## Metadata

**Research scope:**
- Core technology: [what]
- Ecosystem: [libraries explored]
- Patterns: [patterns researched]
- Pitfalls: [areas checked]

**Confidence breakdown:**
- Standard stack: [HIGH/MEDIUM/LOW] - [reason]
- Architecture: [HIGH/MEDIUM/LOW] - [reason]
- Pitfalls: [HIGH/MEDIUM/LOW] - [reason]
- Code examples: [HIGH/MEDIUM/LOW] - [reason]

**Research date:** [date]
**Valid until:** [estimate - 30 days for stable tech, 7 days for fast-moving]
</metadata>

---

*Phase: XX-name*
*Research completed: [date]*
*Ready for planning: [yes/no]*
```

---

## Good Example

```markdown
# Phase 3: Background Job Processing - Research

**Researched:** 2025-01-20
**Domain:** Rails background jobs with Sidekiq and Redis
**Confidence:** HIGH

<research_summary>
## Summary

Researched the Rails ecosystem for building a robust background job processing system. The standard approach uses Sidekiq with Redis for async job execution, Active Job as the adapter interface, and Sidekiq Pro/Enterprise features for critical workloads.

Key finding: Don't hand-roll job retry logic, rate limiting, or queue prioritization. Sidekiq handles all of this out of the box with battle-tested implementations. Custom retry logic leads to silent failures and lost jobs.

**Primary recommendation:** Use Sidekiq + Active Job + Redis stack. Configure job classes with proper retry policies, use Sidekiq's built-in web UI for monitoring, and implement dead letter queues for failed jobs.
</research_summary>

<standard_stack>
## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| sidekiq | 7.2.0 | Background job processor | De facto standard for Rails async work |
| redis | 5.1.0 | Job queue backend | Required by Sidekiq, fast in-memory store |
| activejob | 7.1.0 | Job adapter interface | Rails built-in, framework integration |
| sidekiq-cron | 1.12.0 | Recurring jobs | Cron-like scheduling without OS cron |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| sidekiq-failures | 1.0.4 | Failure tracking | Debugging failed jobs |
| sidekiq-unique-jobs | 8.0.7 | Job deduplication | Preventing duplicate processing |
| sidekiq-throttled | 1.3.0 | Rate limiting | API rate limits, external services |
| sidekiq-batch | (Pro) | Job batching | Complex multi-step workflows |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Sidekiq | GoodJob | GoodJob uses Postgres (no Redis), but slower throughput |
| Sidekiq | Solid Queue | Rails 8 default, but less mature ecosystem |
| sidekiq-cron | whenever | whenever uses OS cron, harder to manage in containers |

**Installation:**
```bash
bundle add sidekiq redis sidekiq-cron
```
</standard_stack>

<architecture_patterns>
## Architecture Patterns

### Recommended Project Structure
```
app/
├── jobs/
│   ├── application_job.rb        # Base job with defaults
│   ├── order_processing_job.rb   # Order workflow
│   ├── email_delivery_job.rb     # Async email sending
│   └── report_generation_job.rb  # Heavy computation
├── services/
│   ├── order_processor.rb        # Business logic (called by job)
│   └── report_generator.rb       # Report logic (called by job)
├── models/
│   └── concerns/
│       └── async_processable.rb  # Shared job-triggering concern
config/
├── sidekiq.yml                   # Queue config and concurrency
└── initializers/
    └── sidekiq.rb                # Redis connection, middleware
```

### Pattern 1: Thin Job, Fat Service
**What:** Jobs should only orchestrate; business logic lives in service objects
**When to use:** Always - keeps jobs testable and logic reusable
**Example:**
```ruby
# Source: Sidekiq best practices
class OrderProcessingJob < ApplicationJob
  queue_as :critical
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(order_id)
    order = Order.find(order_id)
    OrderProcessor.new(order).call
  end
end
```

### Pattern 2: Idempotent Jobs
**What:** Jobs must be safe to run multiple times with the same arguments
**When to use:** Every job - Sidekiq guarantees at-least-once delivery
**Example:**
```ruby
# Source: Sidekiq wiki - Best Practices
class ChargeCustomerJob < ApplicationJob
  def perform(order_id)
    order = Order.find(order_id)
    return if order.charged?  # Idempotency guard

    PaymentGateway.charge(order)
    order.update!(status: :charged)
  end
end
```

### Anti-Patterns to Avoid
- **Passing complex objects as arguments:** Serialize IDs only, look up in perform
- **Long-running jobs without heartbeats:** Break into smaller jobs or use batches
- **Ignoring job failures:** Always configure dead set monitoring and alerting
</architecture_patterns>

<dont_hand_roll>
## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Retry logic | Custom retry with sleep loops | Sidekiq retry with backoff | Handles edge cases, dead letter queue |
| Rate limiting | Token bucket implementation | sidekiq-throttled | Thread-safe, Redis-backed, configurable |
| Job scheduling | Custom cron with rake tasks | sidekiq-cron | Runs in-process, no OS dependency |
| Job uniqueness | Database locks for dedup | sidekiq-unique-jobs | Handles race conditions, TTL expiry |
| Job monitoring | Custom admin dashboard | Sidekiq Web UI | Real-time stats, retry/delete interface |

**Key insight:** Background job processing has decades of solved problems. Sidekiq implements proper job lifecycle management with retry, dead letters, and monitoring. Custom retry logic leads to silent job loss and data inconsistency.
</dont_hand_roll>

<common_pitfalls>
## Common Pitfalls

### Pitfall 1: Serializing ActiveRecord Objects
**What goes wrong:** Jobs fail on deserialization when record changes or is deleted
**Why it happens:** Passing full objects instead of IDs; object state is stale by execution time
**How to avoid:** Always pass IDs, look up record in perform method, handle RecordNotFound
**Warning signs:** Mysterious deserialization errors, stale data in job execution

### Pitfall 2: No Idempotency Guards
**What goes wrong:** Duplicate charges, duplicate emails, duplicate records
**Why it happens:** Sidekiq guarantees at-least-once, not exactly-once delivery
**How to avoid:** Check state before acting, use database unique constraints, use idempotency keys
**Warning signs:** Duplicate records after retries, customer complaints about double charges

### Pitfall 3: Queue Starvation
**What goes wrong:** Low-priority jobs block critical jobs
**Why it happens:** Single queue or misconfigured queue weights
**How to avoid:** Separate queues by priority, configure weights in sidekiq.yml
**Warning signs:** Critical jobs delayed, uneven queue depths
</common_pitfalls>

<code_examples>
## Code Examples

### Basic Sidekiq Configuration
```ruby
# Source: Sidekiq wiki - Getting Started
# config/sidekiq.yml
---
:concurrency: 10
:queues:
  - [critical, 6]
  - [default, 3]
  - [low, 1]

# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
```

### Job with Error Handling
```ruby
# Source: Rails Active Job guide
class ReportGenerationJob < ApplicationJob
  queue_as :low
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(report_id)
    report = Report.find(report_id)
    report.update!(status: :processing)

    result = ReportGenerator.new(report).call
    report.update!(status: :completed, data: result)
  rescue StandardError => e
    report&.update!(status: :failed, error_message: e.message)
    raise  # Re-raise so Sidekiq retry kicks in
  end
end
```
</code_examples>

<sota_updates>
## State of the Art (2024-2025)

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Delayed::Job | Sidekiq | 2015+ | Sidekiq is multithreaded, much faster |
| Resque | Sidekiq | 2016+ | Sidekiq uses less memory, better maintained |
| whenever gem | sidekiq-cron | 2020+ | No OS cron dependency, better for containers |

**New tools/patterns to consider:**
- **Solid Queue:** Rails 8 default queue backend, uses database instead of Redis
- **Mission Control - Jobs:** Rails admin UI for Solid Queue

**Deprecated/outdated:**
- **Delayed::Job:** Still works but single-threaded, much slower than Sidekiq
- **Resque:** Fork-based model uses more memory; Sidekiq's thread model is better
</sota_updates>

<sources>
## Sources

### Primary (HIGH confidence)
- Sidekiq wiki - getting started, best practices, configuration
- Rails Active Job guide - adapter setup, callbacks, error handling
- Redis documentation - connection pooling, persistence settings

### Secondary (MEDIUM confidence)
- Sidekiq GitHub issues "job processing patterns" - verified patterns against wiki
- Rails community guides on background jobs - verified code works

### Tertiary (LOW confidence - needs validation)
- None - all findings verified
</sources>

<metadata>
## Metadata

**Research scope:**
- Core technology: Rails + Sidekiq
- Ecosystem: Redis, Active Job, sidekiq-cron
- Patterns: Thin jobs, idempotency, queue prioritization
- Pitfalls: Serialization, retry safety, queue starvation

**Confidence breakdown:**
- Standard stack: HIGH - verified with Sidekiq wiki, widely used
- Architecture: HIGH - from official best practices
- Pitfalls: HIGH - documented in wiki, verified in production
- Code examples: HIGH - from official sources

**Research date:** 2025-01-20
**Valid until:** 2025-02-20 (30 days - Sidekiq ecosystem stable)
</metadata>

---

*Phase: 03-background-jobs*
*Research completed: 2025-01-20*
*Ready for planning: yes*
```

---

## Guidelines

**When to create:**
- Before planning phases in niche/complex domains
- When Claude's training data is likely stale or sparse
- When "how do experts do this" matters more than "which library"

**Structure:**
- Use XML tags for section markers (matches Ariadna templates)
- Seven core sections: summary, standard_stack, architecture_patterns, dont_hand_roll, common_pitfalls, code_examples, sources
- All sections required (drives comprehensive research)

**Content quality:**
- Standard stack: Specific versions, not just names
- Architecture: Include actual code examples from authoritative sources
- Don't hand-roll: Be explicit about what problems to NOT solve yourself
- Pitfalls: Include warning signs, not just "don't do this"
- Sources: Mark confidence levels honestly

**Integration with planning:**
- RESEARCH.md loaded as @context reference in PLAN.md
- Standard stack informs library choices
- Don't hand-roll prevents custom solutions
- Pitfalls inform verification criteria
- Code examples can be referenced in task actions

**After creation:**
- File lives in phase directory: `.ariadna_planning/phases/XX-name/{phase}-RESEARCH.md`
- Referenced during planning workflow
- plan-phase loads it automatically when present
