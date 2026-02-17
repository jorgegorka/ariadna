<rails_conventions>

Pre-baked Rails knowledge for Ariadna planning and execution agents. This document replaces generic research for standard Rails projects, encoding well-known conventions, patterns, and pitfalls so agents don't need to web-search for common Rails patterns.

<standard_stack>

## Standard Rails Stack (2025)

| Layer | Technology | Notes |
|-------|-----------|-------|
| Framework | Rails 8+ | Defaults to SQLite in dev, includes Solid Queue/Cache/Cable |
| Database | PostgreSQL (production) | SQLite for dev/test is fine for most projects |
| Background Jobs | Solid Queue | Rails 8 default, replaces Sidekiq for most cases |
| Caching | Solid Cache | Rails 8 default, database-backed cache |
| WebSockets | Action Cable + Solid Cable | Rails 8 default |
| Real-time UI | Turbo (Hotwire) | Turbo Drive, Frames, Streams |
| JS Sprinkles | Stimulus (Hotwire) | Controllers for interactive behavior |
| CSS | Tailwind CSS or Propshaft | Rails 8 defaults to Propshaft asset pipeline |
| Auth | Rails built-in `has_secure_password` or Devise | Rails 8 includes auth generator |
| Email | Action Mailer | Built-in |
| File Upload | Active Storage | Built-in |
| API | Rails API mode or Jbuilder | Built-in |
| Testing | Minitest | Rails default, use fixtures not factories |
| Linting | RuboCop + rubocop-rails | Standard community linting |

**What NOT to use (and why):**
- Factories (FactoryBot) when fixtures suffice — fixtures are faster, declarative, and Rails-native
- RSpec unless the project already uses it — Minitest is simpler and Rails-native
- Webpacker/Shakapacker — replaced by importmap-rails or jsbundling-rails
- Sprockets — replaced by Propshaft in Rails 8
- Redis for jobs/cache — Solid Queue/Cache use the database, simpler ops

</standard_stack>

<architecture_patterns>

## Rails Architecture Patterns

### MVC Foundation
- **Models:** Business logic lives here. Validations, scopes, callbacks, associations.
- **Controllers:** Thin. Receive request, call model, render response. 7 RESTful actions max.
- **Views:** ERB templates. Logic delegated to presenters or helpers.

### Concern-Driven Architecture
```
app/models/concerns/
  shared/           # Cross-model concerns (Trackable, Searchable)
  model_name/       # Model-specific concerns (User::Authenticatable)
```

**When to extract a concern:**
- Behavior reused across 2+ models → shared concern
- Model file exceeds ~100 lines → model-specific concern
- Logical grouping of related methods → named concern

### Service Objects (When Needed)
Use plain Ruby objects in `app/services/` for:
- Multi-model operations (CreateOrderWithPayment)
- External API integrations (StripeChargeService)
- Complex business processes spanning multiple steps

**Don't use for:** Simple CRUD, single-model operations, or anything a model method handles.

### Presenter Pattern
Plain Ruby classes for complex view logic:
```ruby
# app/models/dashboard_presenter.rb (NOT app/presenters/)
class DashboardPresenter
  include ActionView::Helpers::TagHelper

  def initialize(user)
    @user = user
  end

  def greeting
    "Welcome, #{@user.name}"
  end
end
```

### RESTful Resource Design
- Prefer creating new controllers over adding custom actions
- `POST /messages/:id/archive` → `ArchivesController#create`
- Nest resources max 1 level: `/posts/:post_id/comments`
- Use `concerns` in routes for shared resource patterns

### Current Attributes
```ruby
# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :session, :account
end
```
Set in `ApplicationController`, access everywhere. No parameter passing for auth context.

</architecture_patterns>

<common_pitfalls>

## Common Rails Pitfalls (with Prevention)

### 1. N+1 Queries
**Problem:** Loading associated records in a loop.
**Prevention:** Use `includes`, `preload`, or `eager_load` in controllers. Add `strict_loading` to models in development.
```ruby
# Bad
@posts = Post.all  # then post.comments in view

# Good
@posts = Post.includes(:comments, :author).all
```

### 2. Missing Database Indexes
**Prevention:** Always add indexes for:
- Foreign keys (`add_index :posts, :user_id`)
- Columns used in `where` clauses
- Columns used in `order` clauses
- Unique constraints (`add_index :users, :email, unique: true`)

### 3. Mass Assignment Vulnerabilities
**Prevention:** Always use `strong_parameters` in controllers.
```ruby
def post_params
  params.require(:post).permit(:title, :body, :published)
end
```

### 4. Callback Hell
**Prevention:** Limit callbacks to:
- `before_validation` for normalization (strip whitespace, downcase email)
- `after_create_commit` for async side effects (send email, broadcast)
- Avoid `after_save` chains that trigger cascading updates

### 5. Fat Controllers
**Prevention:** Controllers should only:
1. Authenticate/authorize
2. Load/build the resource
3. Call save/update/destroy
4. Respond with redirect or render

### 6. Missing Validations
**Prevention:** Validate at model level, not just in forms:
- Presence on required fields
- Uniqueness with database-level constraint
- Format for emails, URLs, phone numbers
- Numericality for quantities, prices

### 7. Unscoped Queries (Multi-tenancy)
**Prevention:** Always scope queries to current user/account:
```ruby
# Bad
Post.find(params[:id])

# Good
Current.user.posts.find(params[:id])
```

### 8. Missing Error Handling
**Prevention:** Add `rescue_from` in `ApplicationController`:
```ruby
rescue_from ActiveRecord::RecordNotFound, with: :not_found
rescue_from ActionController::ParameterMissing, with: :bad_request
```

### 9. Synchronous External Calls
**Prevention:** Always use background jobs for:
- Sending emails
- Calling external APIs
- Processing uploads
- Generating reports

### 10. Missing CSRF Protection
**Prevention:** Rails enables CSRF by default. Don't disable `protect_from_forgery`. For API endpoints, use token auth instead.

</common_pitfalls>

<testing_patterns>

## Rails Testing Patterns (Minitest)

### Test Organization
```
test/
  models/           # Unit tests for models
  controllers/      # Integration tests for request/response
  system/           # Browser-based end-to-end tests
  helpers/          # Helper method tests
  jobs/             # Background job tests
  mailers/          # Mailer tests
  fixtures/         # YAML test data
  test_helper.rb    # Shared setup
```

### Fixtures Over Factories
```yaml
# test/fixtures/users.yml
alice:
  name: Alice
  email: alice@example.com
  password_digest: <%= BCrypt::Password.create('password') %>

bob:
  name: Bob
  email: bob@example.com
  password_digest: <%= BCrypt::Password.create('password') %>
```

**Why fixtures:** Faster (loaded once per test suite), declarative, Rails-native, no external gem needed.

### Model Test Pattern
```ruby
class UserTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:alice_session) # Always set Current context
  end

  test "validates email presence" do
    user = User.new(name: "Test")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "creates user with valid attributes" do
    assert_difference "User.count", 1 do
      User.create!(name: "New", email: "new@example.com", password: "password")
    end
  end
end
```

### Controller Test Pattern (Integration)
```ruby
class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    sign_in @user  # Helper method
  end

  test "index returns posts" do
    get posts_url
    assert_response :success
    assert_select "h2", posts(:first).title
  end

  test "create redirects on success" do
    assert_difference "Post.count", 1 do
      post posts_url, params: { post: { title: "New", body: "Content" } }
    end
    assert_redirected_to post_url(Post.last)
  end
end
```

### System Test Pattern
```ruby
class UserFlowsTest < ApplicationSystemTestCase
  test "user can sign up and create a post" do
    visit new_registration_url
    fill_in "Name", with: "Test User"
    fill_in "Email", with: "test@example.com"
    fill_in "Password", with: "password123"
    click_on "Sign up"

    assert_text "Welcome, Test User"

    click_on "New Post"
    fill_in "Title", with: "My First Post"
    fill_in "Body", with: "Hello world"
    click_on "Create Post"

    assert_text "My First Post"
  end
end
```

### Key Testing Conventions
- Use `assert_difference` for state changes, not just boolean checks
- Set `Current.session` in setup blocks for multi-tenancy
- Test happy path and one key failure path per method
- Use `assert_select` for HTML assertions in controller tests
- Run `bin/rails test` (not `rspec`) for the full suite

</testing_patterns>

<domain_templates>

## Rails Task Templates for Planning

These templates help the planner agent decompose common Rails work into well-structured tasks.

### Add Model
```
Tasks:
1. Create migration + model with validations, associations, and concerns
   Files: db/migrate/xxx_create_[model].rb, app/models/[model].rb
2. Add model tests + fixtures
   Files: test/models/[model]_test.rb, test/fixtures/[model].yml
```

### Add Controller (with views)
```
Tasks:
1. Add routes + controller with RESTful actions
   Files: config/routes.rb, app/controllers/[model]_controller.rb
2. Add views (index, show, new, edit, _form partial)
   Files: app/views/[model]/*.html.erb
3. Add controller tests
   Files: test/controllers/[model]_controller_test.rb
```

### Add Authentication
```
Tasks:
1. Generate auth scaffold (Rails 8: bin/rails generate authentication)
   or: Add User model with has_secure_password, Session model, SessionsController
   Files: app/models/user.rb, app/models/session.rb, app/controllers/sessions_controller.rb
2. Add auth views (login, registration)
   Files: app/views/sessions/*.html.erb, app/views/registrations/*.html.erb
3. Add auth tests
   Files: test/controllers/sessions_controller_test.rb, test/models/user_test.rb
```

### Add Background Job
```
Tasks:
1. Create job class + model method it delegates to
   Files: app/jobs/[name]_job.rb, app/models/[model].rb
2. Add job tests
   Files: test/jobs/[name]_job_test.rb
```

### Add Mailer
```
Tasks:
1. Create mailer + views
   Files: app/mailers/[name]_mailer.rb, app/views/[name]_mailer/*.html.erb
2. Add mailer tests
   Files: test/mailers/[name]_mailer_test.rb
```

### Add Turbo/Hotwire Feature
```
Tasks:
1. Add Turbo Frame wrapping + controller turbo_stream response
   Files: app/views/[model]/*.html.erb, app/controllers/[model]_controller.rb
2. Add Stimulus controller (if interactive behavior needed)
   Files: app/javascript/controllers/[name]_controller.js
3. Add system test for real-time behavior
   Files: test/system/[feature]_test.rb
```

</domain_templates>

<known_domains>

## Known Rails Domains (Skip Research)

These domains are well-understood in Rails and don't need web research:

| Domain | Key Patterns | Research Needed? |
|--------|-------------|-----------------|
| Models & Migrations | ActiveRecord, validations, associations, concerns | No |
| Controllers & Routes | RESTful resources, before_action, strong params | No |
| Views & Templates | ERB, partials, layouts, content_for | No |
| Authentication | has_secure_password, Devise, Rails 8 auth generator | No |
| Authorization | Pundit, CanCanCan, or hand-rolled | No |
| Background Jobs | Solid Queue, ActiveJob | No |
| Email | Action Mailer, letter_opener | No |
| File Uploads | Active Storage | No |
| Real-time | Action Cable, Turbo Streams | No |
| Testing | Minitest, fixtures, system tests | No |
| API Mode | Jbuilder, API-only controllers, token auth | No |
| Caching | Fragment caching, Russian doll, Solid Cache | No |
| Search | pg_search, Ransack | Maybe (depends on complexity) |
| Payments | Stripe, Pay gem | Yes (API details change) |
| External APIs | Third-party integrations | Yes (API-specific) |
| Novel Gems | Unfamiliar libraries | Yes |
| Infrastructure | Docker, Kamal, deployment | Maybe |

**Heuristic:** If all phase requirements map to "No" domains, skip research automatically. If any requirement maps to "Yes", consider `--research` flag.

</known_domains>

</rails_conventions>
