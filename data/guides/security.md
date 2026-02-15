# Security Guide for Rails Code Review

**Agent-Oriented Security Checklist for Automated Code Verification**

This guide provides a structured checklist for verifying code security after each development phase. Each section contains named CHECK items with severity levels, file glob patterns, and UNSAFE/SAFE code examples so an agent can systematically scan changed files and report findings.

Unlike informational security documentation, this guide is **action-oriented** — every check tells you what to look for, where to look, and how to fix it.

**Related guides:**
- [Backend Patterns](backend.md) — Architecture, models, controllers, jobs, style guide
- [Frontend Patterns](frontend.md) — Presenter pattern, view layer conventions
- [Testing Patterns](testing.md) — Testing philosophy, model/controller/job test patterns

## Table of Contents

- [Part 1: Input Handling & Injection](#part-1-input-handling--injection)
  - [1.1 SQL Injection](#11-sql-injection)
  - [1.2 Cross-Site Scripting / XSS](#12-cross-site-scripting--xss)
  - [1.3 Command Injection](#13-command-injection)
  - [1.4 Regular Expression Safety](#14-regular-expression-safety)
- [Part 2: Request Integrity](#part-2-request-integrity)
  - [2.1 CSRF Protection](#21-csrf-protection)
  - [2.2 Mass Assignment & Strong Parameters](#22-mass-assignment--strong-parameters)
  - [2.3 Redirect Security](#23-redirect-security)
- [Part 3: Authentication & Authorization](#part-3-authentication--authorization)
  - [3.1 Authentication](#31-authentication)
  - [3.2 Authorization & IDOR](#32-authorization--idor)
  - [3.3 Session Security](#33-session-security)
- [Part 4: Data Protection](#part-4-data-protection)
  - [4.1 Secrets Management](#41-secrets-management)
  - [4.2 Logging & Parameter Filtering](#42-logging--parameter-filtering)
  - [4.3 File Upload Security](#43-file-upload-security)
- [Part 5: Infrastructure Security](#part-5-infrastructure-security)
  - [5.1 HTTP Security Headers](#51-http-security-headers)
  - [5.2 API Security](#52-api-security)
  - [5.3 Dependency Auditing](#53-dependency-auditing)
- [Part 6: Security Verification Checklist](#part-6-security-verification-checklist)
  - [6.1 Agent Check Protocol](#61-agent-check-protocol)
  - [6.2 Quick-Reference Checklist](#62-quick-reference-checklist)

---

# Part 1: Input Handling & Injection

Injection attacks exploit untrusted input that reaches interpreters (SQL, HTML, shell) without proper sanitization. These checks cover the most common injection vectors in Rails applications.

## 1.1 SQL Injection

SQL injection occurs when user input is interpolated directly into SQL queries. Rails' ActiveRecord API is safe by default, but raw SQL and string interpolation bypass those protections.

### CHECK 1.1a: No string interpolation in SQL

> **What to look for:** String interpolation (`#{}`) or concatenation (`+`) inside `.where()`, `.order()`, `.joins()`, `.group()`, `.having()`, `.from()`, `.select()`, `.pluck()`, or raw SQL strings
> **Where to look:** `app/models/**/*.rb`, `app/controllers/**/*.rb`
> **Severity:** Critical

**UNSAFE:**

```ruby
User.where("name = '#{params[:name]}'")
User.where("role = '" + params[:role] + "'")
User.order("#{params[:sort]} #{params[:direction]}")
```

**SAFE:**

```ruby
User.where(name: params[:name])
User.where("name = ?", params[:name])
User.order(Arel.sql("name")) # only for known-safe static strings
```

### CHECK 1.1b: Parameterized raw SQL

> **What to look for:** `execute()`, `exec_query()`, `find_by_sql()`, `select_all()` calls without bind parameters
> **Where to look:** `app/models/**/*.rb`, `lib/**/*.rb`
> **Severity:** Critical

**UNSAFE:**

```ruby
ActiveRecord::Base.connection.execute(
  "UPDATE users SET name = '#{name}' WHERE id = #{id}"
)
```

**SAFE:**

```ruby
ActiveRecord::Base.connection.exec_query(
  "UPDATE users SET name = $1 WHERE id = $2",
  "SQL", [name, id]
)
```

### CHECK 1.1c: Safe column names in order/group

> **What to look for:** User-controlled values passed to `.order()` or `.group()` without allowlist validation
> **Where to look:** `app/controllers/**/*.rb`, `app/models/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
scope :sorted_by, ->(column) { order(column) }

# Controller
@users = User.order(params[:sort])
```

**SAFE:**

```ruby
ALLOWED_SORT_COLUMNS = %w[name created_at updated_at].freeze

scope :sorted_by, ->(column) do
  if ALLOWED_SORT_COLUMNS.include?(column)
    order(column)
  else
    order(:created_at)
  end
end
```

### CHECK 1.1d: No unscoped find for user-facing lookups

> **What to look for:** `Model.find(params[:id])` without tenant or ownership scoping
> **Where to look:** `app/controllers/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
def show
  @card = Card.find(params[:id])
end
```

**SAFE:**

```ruby
def show
  @card = Current.user.accessible_cards.find_by!(number: params[:id])
end
```

---

## 1.2 Cross-Site Scripting / XSS

XSS attacks inject malicious scripts into pages viewed by other users. Rails auto-escapes output in ERB by default, but several patterns bypass this protection.

### CHECK 1.2a: No raw/html_safe on user input

> **What to look for:** `.html_safe`, `raw()`, or `<%== %>` applied to user-supplied data or database content that originates from user input
> **Where to look:** `app/views/**/*.erb`, `app/helpers/**/*.rb`, `app/models/**/*.rb`
> **Severity:** Critical

**UNSAFE:**

```erb
<%= params[:query].html_safe %>
<%= raw(@user.bio) %>
<%== comment.body %>
```

**SAFE:**

```erb
<%= params[:query] %>
<%= sanitize(@user.bio) %>
<%= comment.body %>
```

### CHECK 1.2b: Sanitized rich text output

> **What to look for:** Rich text or markdown rendered without sanitization; use of `.to_s` on ActionText content bypassing built-in sanitization
> **Where to look:** `app/views/**/*.erb`, `app/helpers/**/*.rb`
> **Severity:** High

**UNSAFE:**

```erb
<%= @card.description.to_s.html_safe %>
<div><%= raw(markdown_to_html(@post.body)) %></div>
```

**SAFE:**

```erb
<%= @card.description %>
<div><%= sanitize(markdown_to_html(@post.body)) %></div>
```

### CHECK 1.2c: Safe link_to href values

> **What to look for:** `link_to` or `<a href>` where the URL comes from user input or database fields without protocol validation
> **Where to look:** `app/views/**/*.erb`, `app/helpers/**/*.rb`
> **Severity:** High

**UNSAFE:**

```erb
<%= link_to "Website", @user.website_url %>
<a href="<%= params[:return_to] %>">Back</a>
```

**SAFE:**

```erb
<%= link_to "Website", @user.website_url if @user.website_url&.match?(%r{\Ahttps?://}) %>
```

### CHECK 1.2d: JSON output escaped in script tags

> **What to look for:** Inline `<script>` blocks that interpolate Ruby data without `json_escape` or the `j` helper
> **Where to look:** `app/views/**/*.erb`
> **Severity:** High

**UNSAFE:**

```erb
<script>
  var data = <%= @data.to_json %>;
</script>
```

**SAFE:**

```erb
<script>
  var data = <%= json_escape(@data.to_json) %>;
</script>

<!-- Or better: use data attributes -->
<div data-config="<%= @data.to_json %>">
```

### CHECK 1.2e: Content-Type set for non-HTML responses

> **What to look for:** Controller actions rendering user-supplied content (CSV, text, SVG) without setting an explicit Content-Type
> **Where to look:** `app/controllers/**/*.rb`
> **Severity:** Medium

**UNSAFE:**

```ruby
def export
  render plain: @data.to_csv
end
```

**SAFE:**

```ruby
def export
  send_data @data.to_csv, type: "text/csv", disposition: "attachment"
end
```

---

## 1.3 Command Injection

Command injection occurs when user input reaches shell functions without sanitization.

### CHECK 1.3a: No user input in shell calls

> **What to look for:** `system()`, backticks, `%x()`, `IO.popen()`, `Open3.capture2()`, `Open3.capture3()`, or `Kernel.spawn()` with string interpolation or concatenation of user input
> **Where to look:** `app/**/*.rb`, `lib/**/*.rb`
> **Severity:** Critical

**UNSAFE:**

```ruby
# Vulnerable: single-string form passes through shell
system("convert #{params[:file]} output.png")
result = `grep -r #{params[:query]} /data`
```

**SAFE:**

```ruby
# Safe: array form bypasses shell interpretation
system("convert", uploaded_file.path, "output.png")
stdout, status = Open3.capture2("grep", "-r", query, "/data")
```

### CHECK 1.3b: Shellwords escaping for unavoidable shell use

> **What to look for:** Cases where shell invocation with a single string is unavoidable — verify `Shellwords.escape()` or array form is used
> **Where to look:** `app/**/*.rb`, `lib/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
system("tar -czf archive.tar.gz #{directory}")
```

**SAFE:**

```ruby
# Prefer array form:
system("tar", "-czf", "archive.tar.gz", directory)
# If shell string is required:
system("tar -czf archive.tar.gz #{Shellwords.escape(directory)}")
```

---

## 1.4 Regular Expression Safety

Ruby's `^` and `$` anchors match line boundaries, not string boundaries. This can allow bypass of regex-based validations.

### CHECK 1.4a: Use \A and \z instead of ^ and $

> **What to look for:** Regex validations using `^` (start of line) and `$` (end of line) instead of `\A` (start of string) and `\z` (end of string)
> **Where to look:** `app/models/**/*.rb`, `app/validators/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
validates :slug, format: { with: /^[a-z0-9-]+$/ }
# Allows "valid-slug\n<script>alert(1)</script>"
```

**SAFE:**

```ruby
validates :slug, format: { with: /\A[a-z0-9-]+\z/ }
```

---

# Part 2: Request Integrity

These checks verify that requests are authentic, properly scoped, and cannot be manipulated to perform unintended actions.

## 2.1 CSRF Protection

Cross-Site Request Forgery tricks authenticated users into submitting unwanted requests. Rails includes CSRF protection by default, but it can be accidentally disabled.

### CHECK 2.1a: CSRF protection enabled

> **What to look for:** `skip_before_action :verify_authenticity_token` or `protect_from_forgery` disabled in controllers that handle browser requests
> **Where to look:** `app/controllers/**/*.rb`
> **Severity:** Critical

**UNSAFE:**

```ruby
class PaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token
end
```

**SAFE:**

```ruby
class PaymentsController < ApplicationController
  # CSRF protection inherited from ApplicationController
end

# Only skip for stateless API endpoints with token auth:
class Api::V1::BaseController < ActionController::API
  # ActionController::API does not include CSRF (correct for token-auth APIs)
end
```

### CHECK 2.1b: Authenticity token in forms

> **What to look for:** Hand-crafted `<form>` tags without `<%= csrf_meta_tags %>` in layout or `authenticity_token` in the form; JavaScript fetch/XHR without CSRF token header
> **Where to look:** `app/views/**/*.erb`, `app/javascript/**/*.js`
> **Severity:** High

**UNSAFE:**

```html
<form action="/transfer" method="post">
  <input name="amount" value="1000">
</form>
```

**SAFE:**

```erb
<%= form_with url: transfer_path do |f| %>
  <%= f.number_field :amount %>
<% end %>
```

### CHECK 2.1c: State-changing actions use non-GET methods

> **What to look for:** Routes that perform state changes (create, update, delete) mapped to GET requests
> **Where to look:** `config/routes.rb`
> **Severity:** High

**UNSAFE:**

```ruby
get "users/:id/delete", to: "users#destroy"
get "posts/:id/publish", to: "posts#publish"
```

**SAFE:**

```ruby
resources :users, only: [:destroy]
resource :publication, only: [:create, :destroy]
```

---

## 2.2 Mass Assignment & Strong Parameters

Mass assignment occurs when user-supplied parameters are passed directly to model create/update methods, allowing attackers to set unintended attributes.

### CHECK 2.2a: Strong parameters in controllers

> **What to look for:** `params.permit!`, `Model.create(params)`, `Model.update(params)`, or `Model.new(params)` without strong parameter filtering
> **Where to look:** `app/controllers/**/*.rb`
> **Severity:** Critical

**UNSAFE:**

```ruby
def create
  @user = User.create(params[:user])
end

def update
  @user.update(params.permit!)
end
```

**SAFE:**

```ruby
def create
  @user = User.create(user_params)
end

private
  def user_params
    params.require(:user).permit(:name, :email)
  end
```

### CHECK 2.2b: No admin/role attributes in permit lists

> **What to look for:** Sensitive attributes (`admin`, `role`, `account_id`, `user_id`, `verified`, `approved`) in strong parameter permit lists
> **Where to look:** `app/controllers/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
def user_params
  params.require(:user).permit(:name, :email, :admin, :role)
end
```

**SAFE:**

```ruby
def user_params
  params.require(:user).permit(:name, :email)
end

# Admin attributes set explicitly with authorization check:
def promote
  authorize! :manage, @user
  @user.update(role: params[:user][:role])
end
```

### CHECK 2.2c: Nested attributes allowlisted

> **What to look for:** `accepts_nested_attributes_for` without corresponding strong parameter scoping, or overly permissive nested attribute configs
> **Where to look:** `app/models/**/*.rb`, `app/controllers/**/*.rb`
> **Severity:** Medium

**UNSAFE:**

```ruby
class Project < ApplicationRecord
  accepts_nested_attributes_for :tasks, allow_destroy: true
end

# Controller permits all nested attributes
def project_params
  params.require(:project).permit!
end
```

**SAFE:**

```ruby
class Project < ApplicationRecord
  accepts_nested_attributes_for :tasks, allow_destroy: true,
    reject_if: :all_blank
end

def project_params
  params.require(:project).permit(:name,
    tasks_attributes: [:id, :title, :done, :_destroy])
end
```

---

## 2.3 Redirect Security

Open redirects allow attackers to send users to malicious sites while appearing to link from a trusted domain.

### CHECK 2.3a: No open redirects from user input

> **What to look for:** `redirect_to params[:url]`, `redirect_to params[:return_to]`, or any redirect target sourced from user input without validation
> **Where to look:** `app/controllers/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
def callback
  redirect_to params[:return_to]
end
```

**SAFE:**

```ruby
def callback
  redirect_to params[:return_to] if safe_redirect?(params[:return_to])
end

private
  def safe_redirect?(url)
    uri = URI.parse(url.to_s)
    uri.host.nil? || uri.host == request.host
  rescue URI::InvalidURIError
    false
  end
```

### CHECK 2.3b: Redirect allowlists for external URLs

> **What to look for:** Redirects to external domains without an explicit allowlist
> **Where to look:** `app/controllers/**/*.rb`
> **Severity:** Medium

**UNSAFE:**

```ruby
def sso_callback
  redirect_to params[:redirect_uri], allow_other_host: true
end
```

**SAFE:**

```ruby
ALLOWED_REDIRECT_HOSTS = %w[accounts.example.com auth.example.com].freeze

def sso_callback
  uri = URI.parse(params[:redirect_uri])
  if ALLOWED_REDIRECT_HOSTS.include?(uri.host)
    redirect_to params[:redirect_uri], allow_other_host: true
  else
    redirect_to root_path
  end
end
```

---

# Part 3: Authentication & Authorization

These checks verify that users are properly identified and can only access resources they are permitted to use.

## 3.1 Authentication

### CHECK 3.1a: Authentication required on all controllers

> **What to look for:** Controllers that inherit from `ApplicationController` but skip or lack authentication before_action; public-facing controllers without explicit `allow_unauthenticated_access`
> **Where to look:** `app/controllers/**/*.rb`
> **Severity:** Critical

**UNSAFE:**

```ruby
class AdminController < ApplicationController
  skip_before_action :authenticate
  # All admin actions now publicly accessible
end
```

**SAFE:**

```ruby
class AdminController < ApplicationController
  # Inherits authenticate from ApplicationController
  before_action :require_admin
end

# Only skip auth intentionally for public pages:
class SessionsController < ApplicationController
  allow_unauthenticated_access only: [:new, :create]
end
```

### CHECK 3.1b: Secure password handling

> **What to look for:** Passwords stored in plain text, weak hashing (MD5, SHA1), or custom password hashing instead of `has_secure_password` or bcrypt
> **Where to look:** `app/models/**/*.rb`, `db/migrate/**/*.rb`
> **Severity:** Critical

**UNSAFE:**

```ruby
class User < ApplicationRecord
  def password=(value)
    self.password_hash = Digest::MD5.hexdigest(value)
  end
end
```

**SAFE:**

```ruby
class User < ApplicationRecord
  has_secure_password
  # Uses bcrypt via ActiveModel::SecurePassword
end
```

### CHECK 3.1c: Timing-safe comparisons for tokens

> **What to look for:** Token or secret comparison using `==` instead of `ActiveSupport::SecurityUtils.secure_compare`
> **Where to look:** `app/controllers/**/*.rb`, `app/models/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
def verify_webhook
  if request.headers["X-Signature"] == compute_signature(request.body)
    process_webhook
  end
end
```

**SAFE:**

```ruby
def verify_webhook
  expected = compute_signature(request.body.read)
  actual = request.headers["X-Signature"].to_s
  if ActiveSupport::SecurityUtils.secure_compare(actual, expected)
    process_webhook
  end
end
```

### CHECK 3.1d: Rate limiting on authentication endpoints

> **What to look for:** Login, password reset, and token verification endpoints without rate limiting
> **Where to look:** `app/controllers/sessions_controller.rb`, `app/controllers/passwords_controller.rb`, `config/routes.rb`
> **Severity:** High

**UNSAFE:**

```ruby
class SessionsController < ApplicationController
  def create
    if user = User.authenticate_by(email: params[:email], password: params[:password])
      start_session(user)
    end
  end
end
```

**SAFE:**

```ruby
class SessionsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_session_path, alert: "Try again later." }

  def create
    if user = User.authenticate_by(email: params[:email], password: params[:password])
      start_session(user)
    end
  end
end
```

---

## 3.2 Authorization & IDOR

Insecure Direct Object Reference (IDOR) occurs when users can access resources belonging to other users or tenants by manipulating identifiers.

### CHECK 3.2a: Scoped resource lookups

> **What to look for:** `Model.find(params[:id])` without scoping through the current user or account; direct model lookups that bypass tenant isolation
> **Where to look:** `app/controllers/**/*.rb`
> **Severity:** Critical

**UNSAFE:**

```ruby
def show
  @board = Board.find(params[:id])
end

def update
  @card = Card.find(params[:card_id])
  @card.update(card_params)
end
```

**SAFE:**

```ruby
def show
  @board = Current.user.boards.find(params[:id])
end

def update
  @card = Current.user.accessible_cards.find_by!(number: params[:card_id])
  @card.update(card_params)
end
```

### CHECK 3.2b: Authorization checks on destructive actions

> **What to look for:** Create, update, and destroy actions that lack explicit authorization checks beyond authentication
> **Where to look:** `app/controllers/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
class BoardsController < ApplicationController
  def destroy
    @board = Current.user.boards.find(params[:id])
    @board.destroy
  end
end
```

**SAFE:**

```ruby
class BoardsController < ApplicationController
  def destroy
    @board = Current.user.boards.find(params[:id])
    if Current.user.can_administer_board?(@board)
      @board.destroy
    else
      head :forbidden
    end
  end
end
```

### CHECK 3.2c: Tenant isolation in queries

> **What to look for:** Queries that do not scope through `Current.account` or a user's tenant-scoped association; cross-tenant data leakage in joins or subqueries
> **Where to look:** `app/models/**/*.rb`, `app/controllers/**/*.rb`
> **Severity:** Critical

**UNSAFE:**

```ruby
def index
  @users = User.where(role: "admin")
end

class Card < ApplicationRecord
  scope :recent, -> { order(created_at: :desc).limit(10) }
end
```

**SAFE:**

```ruby
def index
  @users = Current.account.users.where(role: "admin")
end

class Card < ApplicationRecord
  scope :recent, -> {
    where(account: Current.account).order(created_at: :desc).limit(10)
  }
end
```

### CHECK 3.2d: Nested resource authorization

> **What to look for:** Nested resource controllers that verify the parent resource but not the child's association to the parent
> **Where to look:** `app/controllers/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
class Cards::CommentsController < ApplicationController
  def update
    @card = Current.user.accessible_cards.find_by!(number: params[:card_id])
    @comment = Comment.find(params[:id])  # Any comment, not scoped to card
    @comment.update(comment_params)
  end
end
```

**SAFE:**

```ruby
class Cards::CommentsController < ApplicationController
  def update
    @card = Current.user.accessible_cards.find_by!(number: params[:card_id])
    @comment = @card.comments.find(params[:id])
    @comment.update(comment_params)
  end
end
```

---

## 3.3 Session Security

### CHECK 3.3a: Session regeneration after login

> **What to look for:** Authentication flows that do not call `reset_session` before setting the new session to prevent session fixation attacks
> **Where to look:** `app/controllers/sessions_controller.rb`, `app/models/session.rb`
> **Severity:** High

**UNSAFE:**

```ruby
def create
  if user = User.authenticate_by(email: params[:email], password: params[:password])
    session[:user_id] = user.id
  end
end
```

**SAFE:**

```ruby
def create
  if user = User.authenticate_by(email: params[:email], password: params[:password])
    reset_session
    session[:user_id] = user.id
  end
end
```

### CHECK 3.3b: Secure cookie configuration

> **What to look for:** Session cookies without `secure`, `httponly`, or `same_site` flags in production
> **Where to look:** `config/environments/production.rb`, `config/initializers/session_store.rb`
> **Severity:** High

**UNSAFE:**

```ruby
Rails.application.config.session_store :cookie_store,
  key: "_app_session"
```

**SAFE:**

```ruby
Rails.application.config.session_store :cookie_store,
  key: "_app_session",
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax
```

### CHECK 3.3c: Session expiration configured

> **What to look for:** Sessions without expiration or idle timeout; long-lived sessions that never expire
> **Where to look:** `config/initializers/session_store.rb`, `app/models/session.rb`
> **Severity:** Medium

**UNSAFE:**

```ruby
# No expiration set — session lives forever
Rails.application.config.session_store :cookie_store,
  key: "_app_session"
```

**SAFE:**

```ruby
Rails.application.config.session_store :cookie_store,
  key: "_app_session",
  expire_after: 12.hours
```

---

# Part 4: Data Protection

These checks verify that sensitive data is properly managed, filtered from logs, and protected at rest and in transit.

## 4.1 Secrets Management

### CHECK 4.1a: No hardcoded secrets

> **What to look for:** API keys, passwords, tokens, or secret strings hardcoded in source files; credentials in non-encrypted config files
> **Where to look:** `app/**/*.rb`, `config/**/*.rb`, `lib/**/*.rb`, `config/**/*.yml`
> **Severity:** Critical

**UNSAFE:**

```ruby
class StripeService
  API_KEY = "sk_live_abc123xyz"
end
```

```yaml
# config/database.yml
production:
  password: "super_secret_password"
```

**SAFE:**

```ruby
class StripeService
  API_KEY = Rails.application.credentials.stripe[:api_key]
end
```

```yaml
# config/database.yml
production:
  password: <%= ENV["DATABASE_PASSWORD"] %>
```

### CHECK 4.1b: Credentials encrypted

> **What to look for:** Sensitive configuration in unencrypted YAML files or `.env` files committed to version control
> **Where to look:** `config/**/*.yml`, `.env*`, `.gitignore`
> **Severity:** High

**UNSAFE:**

```yaml
# config/secrets.yml (committed to git)
production:
  secret_key_base: "abc123..."
  smtp_password: "password123"
```

**SAFE:**

```bash
# Use Rails encrypted credentials
bin/rails credentials:edit

# .gitignore includes:
# .env
# config/credentials/*.key
```

### CHECK 4.1c: Secret key base configured

> **What to look for:** Missing or weak `secret_key_base` in production; default development secret used in production
> **Where to look:** `config/environments/production.rb`, `config/credentials.yml.enc`
> **Severity:** Critical

**UNSAFE:**

```ruby
# config/environments/production.rb
config.secret_key_base = "development_secret_do_not_use"
```

**SAFE:**

```ruby
# config/environments/production.rb
config.secret_key_base = Rails.application.credentials.secret_key_base
# Or via environment variable:
config.secret_key_base = ENV.fetch("SECRET_KEY_BASE")
```

---

## 4.2 Logging & Parameter Filtering

### CHECK 4.2a: Sensitive parameters filtered

> **What to look for:** Password, token, credit card, and other sensitive fields not listed in `filter_parameters`
> **Where to look:** `config/initializers/filter_parameter_logging.rb`
> **Severity:** High

**UNSAFE:**

```ruby
# Only filtering password — missing other sensitive fields
Rails.application.config.filter_parameters += [:password]
```

**SAFE:**

```ruby
Rails.application.config.filter_parameters += [
  :password, :password_confirmation,
  :token, :api_key, :secret,
  :credit_card, :card_number, :cvv,
  :ssn, :social_security
]
```

### CHECK 4.2b: No sensitive data in logs

> **What to look for:** `Rails.logger`, `logger.info`, `puts`, or `p` statements that output user data, tokens, or PII
> **Where to look:** `app/**/*.rb`, `lib/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
Rails.logger.info "User login: #{user.email}, token: #{user.auth_token}"
Rails.logger.debug "Payment params: #{params.inspect}"
```

**SAFE:**

```ruby
Rails.logger.info "User login: user_id=#{user.id}"
Rails.logger.debug "Payment processed for user_id=#{user.id}"
```

---

## 4.3 File Upload Security

### CHECK 4.3a: Content type validation

> **What to look for:** File uploads accepted without content type validation; relying solely on file extension for type checking
> **Where to look:** `app/models/**/*.rb`, `app/controllers/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
class Document < ApplicationRecord
  has_one_attached :file
  # No content type validation
end
```

**SAFE:**

```ruby
class Document < ApplicationRecord
  has_one_attached :file

  validates :file, content_type: %w[
    application/pdf
    image/png
    image/jpeg
  ]
end
```

### CHECK 4.3b: File size limits

> **What to look for:** File uploads without size limits; missing `size` validation on ActiveStorage attachments
> **Where to look:** `app/models/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
class Document < ApplicationRecord
  has_one_attached :file
  # No size limit — users can upload arbitrarily large files
end
```

**SAFE:**

```ruby
class Document < ApplicationRecord
  has_one_attached :file

  validates :file, size: { less_than: 10.megabytes }
end
```

### CHECK 4.3c: Safe file storage path

> **What to look for:** User-controlled filenames used directly in file paths; directory traversal via `../` in filenames
> **Where to look:** `app/controllers/**/*.rb`, `lib/**/*.rb`
> **Severity:** Critical

**UNSAFE:**

```ruby
def download
  send_file Rails.root.join("uploads", params[:filename])
  # params[:filename] = "../../etc/passwd" allows path traversal
end
```

**SAFE:**

```ruby
def download
  filename = File.basename(params[:filename])
  path = Rails.root.join("uploads", filename)
  if path.to_s.start_with?(Rails.root.join("uploads").to_s)
    send_file path
  else
    head :forbidden
  end
end
```

### CHECK 4.3d: No executable uploads in public directory

> **What to look for:** File uploads stored in `public/` directory where they could be served directly by the web server; executable file types not blocked
> **Where to look:** `config/storage.yml`, `app/controllers/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
def upload
  path = Rails.root.join("public", "uploads", file.original_filename)
  File.open(path, "wb") { |f| f.write(file.read) }
end
```

**SAFE:**

```ruby
# Use ActiveStorage — files stored outside public directory
class Document < ApplicationRecord
  has_one_attached :file

  validate :reject_dangerous_content_types

  private
    def reject_dangerous_content_types
      dangerous = %w[text/html application/javascript application/x-httpd-php]
      if file.attached? && dangerous.include?(file.content_type)
        errors.add(:file, "type not allowed")
      end
    end
end
```

---

# Part 5: Infrastructure Security

These checks cover HTTP-level protections, API security, and dependency management.

## 5.1 HTTP Security Headers

### CHECK 5.1a: Force SSL in production

> **What to look for:** `force_ssl` not enabled in production; HSTS not configured
> **Where to look:** `config/environments/production.rb`
> **Severity:** Critical

**UNSAFE:**

```ruby
# config/environments/production.rb
# config.force_ssl = true  (commented out or missing)
```

**SAFE:**

```ruby
# config/environments/production.rb
config.force_ssl = true
# Enables HSTS, redirects HTTP to HTTPS, marks cookies as secure
```

### CHECK 5.1b: Content Security Policy configured

> **What to look for:** Missing Content-Security-Policy header; overly permissive CSP with `unsafe-inline` or `unsafe-eval`
> **Where to look:** `config/initializers/content_security_policy.rb`
> **Severity:** High

**UNSAFE:**

```ruby
# No CSP configured, or:
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.script_src :unsafe_inline, :unsafe_eval, "*"
  end
end
```

**SAFE:**

```ruby
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src  :self
    policy.style_src   :self, :unsafe_inline
    policy.img_src     :self, :data, "https://storage.example.com"
    policy.connect_src :self
  end

  config.content_security_policy_nonce_generator = ->(request) {
    request.session.id.to_s
  }
end
```

### CHECK 5.1c: Referrer-Policy and permissions headers

> **What to look for:** Missing `Referrer-Policy`, `Permissions-Policy`, or `X-Content-Type-Options` headers
> **Where to look:** `config/initializers/**/*.rb`, `app/controllers/application_controller.rb`
> **Severity:** Medium

**UNSAFE:**

```ruby
# No additional security headers configured
```

**SAFE:**

```ruby
# config/initializers/default_headers.rb
Rails.application.config.action_dispatch.default_headers.merge!(
  "Referrer-Policy" => "strict-origin-when-cross-origin",
  "Permissions-Policy" => "camera=(), microphone=(), geolocation=()",
  "X-Content-Type-Options" => "nosniff"
)
```

---

## 5.2 API Security

### CHECK 5.2a: API authentication on all endpoints

> **What to look for:** API controllers without authentication; endpoints that accept requests without valid tokens
> **Where to look:** `app/controllers/api/**/*.rb`
> **Severity:** Critical

**UNSAFE:**

```ruby
class Api::V1::CardsController < ActionController::API
  def index
    @cards = Card.all
  end
end
```

**SAFE:**

```ruby
class Api::V1::BaseController < ActionController::API
  before_action :authenticate_api_token

  private
    def authenticate_api_token
      token = request.headers["Authorization"]&.remove("Bearer ")
      head :unauthorized unless token && ApiToken.active.exists?(token: token)
    end
end

class Api::V1::CardsController < Api::V1::BaseController
  def index
    @cards = Current.account.cards.all
  end
end
```

### CHECK 5.2b: API response scoping

> **What to look for:** API responses that return data outside the authenticated user's tenant or permission scope
> **Where to look:** `app/controllers/api/**/*.rb`, `app/serializers/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
def show
  @user = User.find(params[:id])
  render json: @user, include: [:sessions, :identity]
end
```

**SAFE:**

```ruby
def show
  @user = Current.account.users.find(params[:id])
  render json: @user, only: [:id, :name, :email, :role]
end
```

### CHECK 5.2c: API rate limiting

> **What to look for:** API endpoints without rate limiting; missing throttling for expensive operations
> **Where to look:** `app/controllers/api/**/*.rb`, `config/initializers/rack_attack.rb`
> **Severity:** Medium

**UNSAFE:**

```ruby
# No rate limiting configured
class Api::V1::SearchController < Api::V1::BaseController
  def index
    @results = Card.search(params[:q])
  end
end
```

**SAFE:**

```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle("api/requests", limit: 100, period: 1.minute) do |req|
  req.env["HTTP_AUTHORIZATION"]&.remove("Bearer ") if req.path.start_with?("/api/")
end

# Or use Rails built-in rate limiting:
class Api::V1::SearchController < Api::V1::BaseController
  rate_limit to: 30, within: 1.minute
end
```

---

## 5.3 Dependency Auditing

### CHECK 5.3a: No known vulnerable gems

> **What to look for:** Gems with known CVEs; outdated gems with security patches available
> **Where to look:** `Gemfile`, `Gemfile.lock`
> **Severity:** High

**Verification command:**

```bash
bundle audit check --update
```

**UNSAFE:**

```
# bundle audit reports vulnerabilities
# Gemfile.lock contains gems with known CVEs
```

**SAFE:**

```
# bundle audit reports: No vulnerabilities found
# All gems patched to versions without known CVEs
```

### CHECK 5.3b: JavaScript dependencies audited

> **What to look for:** npm/yarn packages with known vulnerabilities
> **Where to look:** `package.json`, `yarn.lock`, `package-lock.json`
> **Severity:** High

**Verification command:**

```bash
yarn audit
# Or: npm audit
```

**UNSAFE:**

```
# yarn audit reports critical or high severity vulnerabilities
```

**SAFE:**

```
# yarn audit reports 0 vulnerabilities
# Or all remaining advisories have been reviewed and accepted
```

---

# Part 6: Security Verification Checklist

## 6.1 Agent Check Protocol

When verifying security after a development phase, follow this protocol to map changed files to relevant checks.

### Step 1: Identify changed files

```bash
git diff --name-only HEAD~1
# Or for a phase: git diff <phase-start-sha>..HEAD --name-only
```

### Step 2: Map files to check sections

| Changed file pattern | Applicable sections |
|---|---|
| `app/models/**/*.rb` | 1.1 (SQL), 2.2 (mass assignment), 3.2 (IDOR), 4.1 (secrets), 4.3 (uploads) |
| `app/controllers/**/*.rb` | 1.1d (unscoped find), 1.2e (content-type), 2.1 (CSRF), 2.2 (strong params), 2.3 (redirects), 3.1 (auth), 3.2 (authz) |
| `app/views/**/*.erb` | 1.2 (XSS), 2.1b (CSRF tokens) |
| `app/controllers/api/**/*.rb` | 5.2 (API security) |
| `config/routes.rb` | 2.1c (GET state changes), 2.3 (redirects) |
| `config/environments/**/*.rb` | 4.1c (secret key), 5.1a (SSL), 5.1b (CSP) |
| `config/initializers/**/*.rb` | 3.3b (cookies), 4.2a (param filtering), 5.1 (headers) |
| `db/migrate/**/*.rb` | 3.1b (password storage) |
| `lib/**/*.rb` | 1.1b (raw SQL), 1.3 (command injection) |
| `Gemfile` | 5.3a (vulnerable gems) |
| `package.json` / `yarn.lock` | 5.3b (JS dependencies) |
| `app/javascript/**/*.js` | 1.2d (XSS), 2.1b (CSRF token in fetch) |

### Step 3: Run applicable checks

For each applicable section, scan the changed files using the "Where to look" glob pattern and "What to look for" pattern. Report findings as:

```
PASS: CHECK 1.1a — No string interpolation in SQL (scanned 3 files)
FAIL: CHECK 3.2a — Unscoped find in app/controllers/boards_controller.rb:15
SKIP: CHECK 4.3a — No file upload changes in this phase
```

### Step 4: Run automated tools

```bash
# Dependency audit
bundle audit check --update
yarn audit

# Static analysis (if Brakeman is available)
brakeman --no-pager -q

# Check for secrets in git history
git log --diff-filter=A --name-only -- "*.key" "*.pem" ".env*"
```

---

## 6.2 Quick-Reference Checklist

All checks from Parts 1-5 in a single table for quick scanning.

| Check | Name | Severity | Grep pattern | Files |
|---|---|---|---|---|
| 1.1a | No string interpolation in SQL | Critical | `\.where\(["'].*#\{` | `app/models/**/*.rb` |
| 1.1b | Parameterized raw SQL | Critical | `\.execute\(["'].*#\{` | `app/models/**/*.rb`, `lib/**/*.rb` |
| 1.1c | Safe column names in order | High | `\.order\(params` | `app/controllers/**/*.rb` |
| 1.1d | Scoped find for user lookups | High | `\.find\(params\[` | `app/controllers/**/*.rb` |
| 1.2a | No raw/html_safe on user input | Critical | `\.html_safe\|raw(` | `app/views/**/*.erb` |
| 1.2b | Sanitized rich text | High | `\.to_s\.html_safe` | `app/views/**/*.erb` |
| 1.2c | Safe link_to href values | High | `link_to.*params\[` | `app/views/**/*.erb` |
| 1.2d | JSON escaped in script tags | High | `<script>.*to_json` | `app/views/**/*.erb` |
| 1.2e | Content-Type for non-HTML | Medium | `render plain:` | `app/controllers/**/*.rb` |
| 1.3a | No user input in shell calls | Critical | `system\(["'].*#\{` | `app/**/*.rb`, `lib/**/*.rb` |
| 1.3b | Shellwords for shell use | High | `Shellwords\.escape` | `app/**/*.rb`, `lib/**/*.rb` |
| 1.4a | \\A and \\z in regex | High | `format:.*\/\^` | `app/models/**/*.rb` |
| 2.1a | CSRF protection enabled | Critical | `skip_before_action :verify_authenticity` | `app/controllers/**/*.rb` |
| 2.1b | Authenticity token in forms | High | `<form[^>]*method` | `app/views/**/*.erb` |
| 2.1c | Non-GET for state changes | High | `get.*destroy\|get.*delete\|get.*create` | `config/routes.rb` |
| 2.2a | Strong parameters | Critical | `params\.permit!` | `app/controllers/**/*.rb` |
| 2.2b | No admin attrs in permit | High | `permit.*:admin\|permit.*:role` | `app/controllers/**/*.rb` |
| 2.2c | Nested attributes scoped | Medium | `accepts_nested_attributes_for` | `app/models/**/*.rb` |
| 2.3a | No open redirects | High | `redirect_to params\[` | `app/controllers/**/*.rb` |
| 2.3b | Redirect allowlists | Medium | `allow_other_host: true` | `app/controllers/**/*.rb` |
| 3.1a | Auth on all controllers | Critical | `skip_before_action :authenticate` | `app/controllers/**/*.rb` |
| 3.1b | Secure password handling | Critical | `Digest::MD5\|Digest::SHA1` | `app/models/**/*.rb` |
| 3.1c | Timing-safe comparison | High | `==.*token\|==.*secret` | `app/controllers/**/*.rb` |
| 3.1d | Rate limiting on auth | High | `rate_limit` | `app/controllers/sessions_controller.rb` |
| 3.2a | Scoped resource lookups | Critical | `Model\.find\(params` | `app/controllers/**/*.rb` |
| 3.2b | Authz on destructive actions | High | `def destroy` | `app/controllers/**/*.rb` |
| 3.2c | Tenant isolation | Critical | `Current\.account` | `app/models/**/*.rb` |
| 3.2d | Nested resource authz | High | `find\(params\[:id\]\)` | `app/controllers/**/*.rb` |
| 3.3a | Session regeneration | High | `reset_session` | `app/controllers/sessions_controller.rb` |
| 3.3b | Secure cookie config | High | `session_store.*secure` | `config/**/*.rb` |
| 3.3c | Session expiration | Medium | `expire_after` | `config/**/*.rb` |
| 4.1a | No hardcoded secrets | Critical | `API_KEY\|SECRET\|password.*=.*["']` | `app/**/*.rb`, `config/**/*.rb` |
| 4.1b | Credentials encrypted | High | `credentials\.yml\.enc` | `config/**/*.yml` |
| 4.1c | Secret key base configured | Critical | `secret_key_base` | `config/environments/production.rb` |
| 4.2a | Sensitive params filtered | High | `filter_parameters` | `config/initializers/**/*.rb` |
| 4.2b | No sensitive data in logs | High | `logger.*token\|logger.*password` | `app/**/*.rb` |
| 4.3a | Content type validation | High | `content_type:` | `app/models/**/*.rb` |
| 4.3b | File size limits | High | `size:.*less_than` | `app/models/**/*.rb` |
| 4.3c | Safe file storage path | Critical | `send_file.*params` | `app/controllers/**/*.rb` |
| 4.3d | No executable uploads | High | `public.*uploads` | `config/storage.yml` |
| 5.1a | Force SSL in production | Critical | `force_ssl` | `config/environments/production.rb` |
| 5.1b | CSP configured | High | `content_security_policy` | `config/initializers/**/*.rb` |
| 5.1c | Security headers set | Medium | `Referrer-Policy\|Permissions-Policy` | `config/initializers/**/*.rb` |
| 5.2a | API authentication | Critical | `before_action.*authenticate` | `app/controllers/api/**/*.rb` |
| 5.2b | API response scoping | High | `Current\.account` | `app/controllers/api/**/*.rb` |
| 5.2c | API rate limiting | Medium | `rate_limit\|Rack::Attack` | `app/controllers/api/**/*.rb` |
| 5.3a | No vulnerable gems | High | `bundle audit` | `Gemfile.lock` |
| 5.3b | JS dependencies audited | High | `yarn audit\|npm audit` | `package.json` |

---

**Document Version**: 1.0
**Last Updated**: 2026-02-15
**Maintainer**: Development Team
