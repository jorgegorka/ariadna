# Rails Backend: Jobs

ActiveJob patterns — ultra-thin jobs, _now/_later naming, automatic multi-tenancy, retry logic.

---

## Core Rule

Jobs are thin wrappers around model methods. **All business logic belongs in models.** A job should be 3-6 lines.

```ruby
# Good
class NotifyRecipientsJob < ApplicationJob
  def perform(notifiable) = notifiable.notify_recipients

# Bad: 50 lines of logic that can't be called synchronously or tested easily
class NotifyRecipientsJob < ApplicationJob
  def perform(comment)
    # logic that belongs in comment.notify_recipients
  end
end
```

---

## The _now/_later Pattern

For every async operation, create a matched pair on the model plus a job class:

```ruby
# In the model/concern:
module Notifiable
  extend ActiveSupport::Concern

  included do
    after_create_commit :notify_recipients_later  # Trigger async after commit
  end

  def notify_recipients                           # Synchronous — call from anywhere
    Notifier.for(self)&.notify
  end

  private
    def notify_recipients_later                   # Async wrapper
      NotifyRecipientsJob.perform_later self
    end
end

# Job:
class NotifyRecipientsJob < ApplicationJob
  def perform(notifiable) = notifiable.notify_recipients
end
```

### Why

```ruby
# Async vs sync is explicit:
comment.notify_recipients        # Synchronous — use in console, tests, other methods
comment.notify_recipients_later  # Async — enqueues job

# Synchronous method enables:
# - Fast unit tests (no queue)
# - Rails console usage
# - Calling from other model methods
```

---

## Job Examples

```ruby
class Webhook::DeliveryJob < ApplicationJob
  queue_as :webhooks
  def perform(delivery) = delivery.deliver
end

class ExportAccountDataJob < ApplicationJob
  queue_as :backend
  def perform(export) = export.build
end
```

---

## Multi-Tenancy in Jobs

A global `ActiveJob` extension handles tenant context transparently. **Never pass account manually.**

```ruby
# Don't do this:
SomeJob.perform_later(record, account: Current.account)

# Do this — account captured automatically at enqueue time:
SomeJob.perform_later(record)
```

How it works:
- **On enqueue**: captures `Current.account` (serialized as GlobalID)
- **On execute**: wraps `perform` in `Current.with_account(@account) { ... }`

All queries inside `perform` have `Current.account` set correctly. Jobs are always enqueued `after_transaction_commit` — prevents jobs for rolled-back records.

---

## Recurring Jobs

```yaml
# config/recurring.yml
auto_postpone_cards:
  schedule: "50 * * * *"   # Every hour at :50
  command: "Card.auto_postpone_all_due"
```

Commands call class methods on models — consistent with keeping logic in models.

---

## Retry Logic

```ruby
class ImportJob < ApplicationJob
  retry_on Net::TimeoutError, wait: :polynomially_longer, attempts: 5
  discard_on ActiveJob::DeserializationError  # Record deleted before job ran

  def perform(import) = import.run
end
```

- `retry_on` for transient failures (network timeouts, rate limits)
- `discard_on` for permanent failures where retrying is pointless
- Keep retry configuration on the job class; keep the work in model methods
