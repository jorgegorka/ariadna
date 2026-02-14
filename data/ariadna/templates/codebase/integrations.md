# External Integrations Template

Template for `.planning/codebase/INTEGRATIONS.md` - captures external service dependencies.

**Purpose:** Document what external systems this codebase communicates with. Focused on "what lives outside our code that we depend on."

---

## File Template

```markdown
# External Integrations

**Analysis Date:** [YYYY-MM-DD]

## APIs & External Services

**Payment Processing:**
- [Service] - [What it's used for: e.g., "subscription billing, one-time payments"]
  - Gem: [e.g., "`stripe` gem"]
  - Auth: [e.g., "`Rails.application.credentials.stripe[:secret_key]` or `ENV["STRIPE_SECRET_KEY"]`"]
  - Integration: [e.g., "Stripe::Customer, Stripe::PaymentIntent, webhooks"]

**Email:**
- [Service] - [What it's used for: e.g., "transactional emails"]
  - Gem: [e.g., "`postmark-rails` gem"]
  - Delivery method: [e.g., "ActionMailer with SMTP or API delivery"]
  - Templates: [e.g., "ERB views in `app/views/user_mailer/`"]
  - Config: [e.g., "`config/environments/production.rb` mail settings"]

**External APIs:**
- [Service] - [What it's used for]
  - Gem/Client: [e.g., "`faraday` gem", "`httparty` gem", "custom API wrapper in `app/services/`"]
  - Auth: [e.g., "Bearer token via `Rails.application.credentials`"]
  - Rate limits: [if applicable]

## Data Storage

**Databases:**
- [Type/Provider] - [e.g., "PostgreSQL on Render"]
  - Connection: [e.g., "via `config/database.yml` and `DATABASE_URL` env var"]
  - Client: [e.g., "ActiveRecord"]
  - Migrations: [e.g., "`db/migrate/` via `rails db:migrate`"]

**File Storage:**
- [Service] - [e.g., "AWS S3 for user uploads via ActiveStorage"]
  - Gem: [e.g., "`aws-sdk-s3` gem"]
  - Config: [e.g., "`config/storage.yml`"]
  - Service: [e.g., "`amazon` service in production, `local` in development"]

**Caching:**
- [Service] - [e.g., "Redis for fragment caching and sessions"]
  - Gem: [e.g., "`redis` gem or Solid Cache"]
  - Interface: [e.g., "`Rails.cache` with `redis_cache_store`"]
  - Config: [e.g., "`config/environments/production.rb` cache store settings"]

## Authentication & Identity

**Auth Provider:**
- [Approach] - [e.g., "Devise with database-backed sessions", "`has_secure_password` with custom auth"]
  - Gem: [e.g., "`devise` gem"]
  - Config: [e.g., "`config/initializers/devise.rb`"]
  - Session management: [e.g., "cookie-based sessions", "Redis session store"]

**OAuth Integrations:**
- [Provider] - [e.g., "Google OAuth for sign-in"]
  - Gem: [e.g., "`omniauth-google-oauth2`"]
  - Credentials: [e.g., "`Rails.application.credentials.google[:client_id]`"]
  - Scopes: [e.g., "email, profile"]

## Monitoring & Observability

**Error Tracking:**
- [Service] - [e.g., "Sentry"]
  - Gem: [e.g., "`sentry-ruby` and `sentry-rails`"]
  - DSN: [e.g., "`Rails.application.credentials.sentry[:dsn]` or `ENV["SENTRY_DSN"]`"]
  - Config: [e.g., "`config/initializers/sentry.rb`"]

**Analytics:**
- [Service] - [e.g., "Ahoy for product analytics"]
  - Gem: [e.g., "`ahoy_matey`"]

**Logs:**
- [Service] - [e.g., "Lograge for structured logs", "stdout only"]
  - Gem: [e.g., "`lograge`"]
  - Config: [e.g., "`config/initializers/lograge.rb`"]

## Background Jobs

**Job Backend:**
- [Service] - [e.g., "Sidekiq for background processing"]
  - Gem: [e.g., "`sidekiq`"]
  - Config: [e.g., "`config/sidekiq.yml`"]
  - Dashboard: [e.g., "Sidekiq Web UI mounted at `/sidekiq` in `config/routes.rb`"]
  - Queues: [e.g., "default, mailers, backend"]

## CI/CD & Deployment

**Hosting:**
- [Platform] - [e.g., "Hetzner via Kamal", "Render", "Heroku"]
  - Deployment: [e.g., "Kamal deploy via `config/deploy.yml`"]
  - Docker: [e.g., "`Dockerfile` in project root"]
  - Environment vars: [e.g., "configured in `config/deploy.yml` secrets or platform dashboard"]

**CI Pipeline:**
- [Service] - [e.g., "GitHub Actions"]
  - Workflows: [e.g., "`.github/workflows/ci.yml`"]
  - Secrets: [e.g., "stored in GitHub repo secrets"]

## Environment Configuration

**Development:**
- Required env vars: [List critical vars]
- Secrets location: [e.g., "`.env` via `dotenv-rails` gem (gitignored)", "`config/database.yml`"]
- Mock/stub services: [e.g., "Stripe test mode", "local PostgreSQL", "ActiveStorage local disk"]

**Staging:**
- Environment-specific differences: [e.g., "uses staging Stripe account"]
- Data: [e.g., "separate staging database"]

**Production:**
- Secrets management: [e.g., "`config/credentials/production.yml.enc` via `rails credentials:edit --environment production`"]
- Failover/redundancy: [e.g., "multi-region DB replication"]

## Webhooks & Callbacks

**Incoming:**
- [Service] - [Route: e.g., "`post "/webhooks/stripe", to: "webhooks/stripe#create"`"]
  - Verification: [e.g., "`Stripe::Webhook.construct_event` with signing secret"]
  - Events: [e.g., "payment_intent.succeeded, customer.subscription.updated"]
  - Controller: [e.g., "`app/controllers/webhooks/stripe_controller.rb`"]

**Outgoing:**
- [Service] - [What triggers it]
  - Delivery: [e.g., "ActiveJob-enqueued HTTP POST via webhook job"]
  - Retry logic: [if applicable]

---

*Integration audit: [date]*
*Update when adding/removing external services*
```

<good_examples>
```markdown
# External Integrations

**Analysis Date:** 2025-01-20

## APIs & External Services

**Payment Processing:**
- Stripe - Subscription billing and one-time course payments
  - Gem: `stripe` gem v10.x
  - Auth: API key via `Rails.application.credentials.stripe[:secret_key]`
  - Integration: Stripe::Customer, Stripe::PaymentIntent, Stripe::Checkout::Session, webhooks

**Email:**
- Postmark - Transactional emails (receipts, password resets, notifications)
  - Gem: `postmark-rails` gem v0.22
  - Delivery method: ActionMailer with Postmark API delivery
  - Templates: ERB views in `app/views/` mailer directories (`user_mailer/`, `notification_mailer/`)
  - Config: `config/environments/production.rb` sets `config.action_mailer.delivery_method = :postmark`

**External APIs:**
- OpenAI API - Course content generation
  - Gem: `ruby-openai` gem v7.x
  - Auth: API key via `Rails.application.credentials.openai[:api_key]`
  - Rate limits: 3500 requests/min (tier 3)

## Data Storage

**Databases:**
- PostgreSQL on Render - Primary data store
  - Connection: `config/database.yml` with `DATABASE_URL` env var in production
  - Client: ActiveRecord
  - Migrations: `db/migrate/` via `rails db:migrate`

**File Storage:**
- AWS S3 via ActiveStorage - User uploads (profile images, course materials)
  - Gem: `aws-sdk-s3` gem
  - Config: `config/storage.yml` defines `amazon` service
  - Service: `amazon` in production, `local` disk in development
  - Auth: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` env vars

**Caching:**
- Redis - Fragment caching and Sidekiq job queue
  - Gem: `redis` gem v5.x
  - Interface: `Rails.cache` with `config.cache_store = :redis_cache_store`
  - Config: `config/environments/production.rb` cache store, `REDIS_URL` env var
  - Session store: Cookie-based (not Redis)

## Authentication & Identity

**Auth Provider:**
- Devise - Email/password authentication with database-backed sessions
  - Gem: `devise` gem v4.9
  - Config: `config/initializers/devise.rb`
  - Session management: Cookie-based sessions with CSRF protection

**OAuth Integrations:**
- Google OAuth - Social sign-in
  - Gem: `omniauth-google-oauth2`
  - Credentials: `Rails.application.credentials.google[:client_id]`, `Rails.application.credentials.google[:client_secret]`
  - Scopes: email, profile
  - Callback: `config/routes.rb` via Devise OmniAuth routes

## Monitoring & Observability

**Error Tracking:**
- Sentry - Server-side error tracking
  - Gem: `sentry-ruby` and `sentry-rails`
  - DSN: `Rails.application.credentials.sentry[:dsn]`
  - Config: `config/initializers/sentry.rb`
  - Release tracking: Git commit SHA

**Analytics:**
- None (planned: Ahoy)

**Logs:**
- Lograge - Structured single-line request logs
  - Gem: `lograge`
  - Config: `config/initializers/lograge.rb`
  - Production: stdout for container log aggregation

## Background Jobs

**Job Backend:**
- Sidekiq - Background job processing
  - Gem: `sidekiq` gem v7.x
  - Config: `config/sidekiq.yml`
  - Dashboard: Sidekiq Web UI mounted at `/sidekiq` in `config/routes.rb` (admin-only)
  - Queues: default, mailers, backend (exports, heavy processing)
  - Redis: Shares `REDIS_URL` with caching

## CI/CD & Deployment

**Hosting:**
- Hetzner via Kamal - Docker-based deployment
  - Deployment: `kamal deploy` via `config/deploy.yml`
  - Docker: `Dockerfile` in project root with multi-stage build
  - Environment vars: Secrets managed in `config/deploy.yml` via `.kamal/secrets`

**CI Pipeline:**
- GitHub Actions - Tests, linting, and security checks
  - Workflows: `.github/workflows/ci.yml`
  - Secrets: `RAILS_MASTER_KEY` stored in GitHub repo secrets

## Environment Configuration

**Development:**
- Required env vars: None (development defaults in `config/database.yml`)
- Secrets location: `config/credentials.yml.enc` via `rails credentials:edit`, `.env` via `dotenv-rails` for overrides
- Mock/stub services: Stripe test mode, local PostgreSQL, ActiveStorage local disk service

**Staging:**
- Uses staging Stripe account
- Separate database on Render
- Same Kamal setup, different deploy target

**Production:**
- Secrets management: `config/credentials/production.yml.enc` via `rails credentials:edit --environment production`
- Database: PostgreSQL on Render with daily backups
- Redis: Managed Redis instance via Render

## Webhooks & Callbacks

**Incoming:**
- Stripe - `post "/webhooks/stripe", to: "webhooks/stripe#create"` in `config/routes.rb`
  - Verification: `Stripe::Webhook.construct_event` with signing secret from `Rails.application.credentials.stripe[:webhook_signing_secret]`
  - Events: payment_intent.succeeded, customer.subscription.updated, customer.subscription.deleted
  - Controller: `app/controllers/webhooks/stripe_controller.rb`

**Outgoing:**
- None

---

*Integration audit: 2025-01-20*
*Update when adding/removing external services*
```
</good_examples>

<guidelines>
**What belongs in INTEGRATIONS.md:**
- External services the code communicates with
- Authentication patterns (where secrets live, not the secrets themselves)
- Gems and client libraries used for each integration
- Environment variable names (not values)
- Webhook endpoints, routes, and verification methods
- Database connection patterns via `config/database.yml`
- File storage configuration via ActiveStorage and `config/storage.yml`
- Background job backend and queue configuration
- Monitoring, logging, and error tracking services
- Deployment platform and CI/CD pipeline

**What does NOT belong here:**
- Actual API keys or secrets (NEVER write these)
- Internal architecture (that's ARCHITECTURE.md)
- Code patterns (that's PATTERNS.md)
- Technology choices (that's STACK.md)
- Performance issues (that's CONCERNS.md)

**When filling this template:**
- Check `Gemfile` for integration gems (`stripe`, `devise`, `sentry-rails`, `sidekiq`, `aws-sdk-s3`, etc.)
- Check `config/initializers/` for service configuration files
- Check `config/credentials.yml.enc` structure (via `rails credentials:show` or reading initializers that reference credentials)
- Check `config/storage.yml` for ActiveStorage service configuration
- Check `config/database.yml` for database connection setup
- Check `config/environments/production.rb` for mail, cache store, and job backend settings
- Look for webhook controllers in `app/controllers/webhooks/` or routes with `webhooks` in `config/routes.rb`
- Check `config/deploy.yml` or platform config for deployment setup
- Check `.github/workflows/` for CI pipeline configuration
- Note where secrets are managed (credentials files, env vars, platform dashboard) — not the secrets themselves
- Document environment-specific differences (development/staging/production)

**Useful for phase planning when:**
- Adding new external service integrations
- Debugging authentication issues with third-party services
- Understanding data flow outside the application
- Setting up new environments or onboarding developers
- Auditing third-party gem dependencies
- Planning for service outages or migrations
- Configuring deployment and CI/CD pipelines

**Security note:**
Document WHERE secrets live (`Rails.application.credentials`, env vars, `.kamal/secrets`), never WHAT the secrets are.
</guidelines>
