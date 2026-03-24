---
name: rails-security
description: Ruby on Rails security conventions — authentication, authorization, OWASP protections, CSRF, input validation. Use when implementing auth, handling sensitive data, or reviewing security.
---

# Rails Security Conventions

Opinionated security conventions for Rails applications. Covers the most critical OWASP risks and Rails-specific pitfalls. For a full audit checklist with grep patterns, see [AUDIT.md](AUDIT.md).

---

## Part 1: Input Handling & Injection

### SQL Injection — Always parameterize

Never interpolate or concatenate user input into SQL. ActiveRecord's hash and placeholder syntax handles this automatically.

**UNSAFE:**
```ruby
User.where("name = '#{params[:name]}'")
User.order("#{params[:sort]} #{params[:direction]}")
ActiveRecord::Base.connection.execute("UPDATE users SET name = '#{name}'")
```

**SAFE:**
```ruby
User.where(name: params[:name])
User.where("name = ?", params[:name])
ActiveRecord::Base.connection.exec_query("UPDATE users SET name = $1", "SQL", [name])
```

For `order`/`group`, allowlist the column before use:

```ruby
ALLOWED_SORT_COLUMNS = %w[name created_at updated_at].freeze

scope :sorted_by, ->(col) {
  order(ALLOWED_SORT_COLUMNS.include?(col) ? col : :created_at)
}
```

### XSS — Rails escapes by default; do not bypass it

ERB auto-escapes `<%= %>`. Never call `.html_safe` or `raw()` on user-supplied or database content.

**UNSAFE:**
```erb
<%= params[:query].html_safe %>
<%= raw(@user.bio) %>
<%= @card.description.to_s.html_safe %>
<script>var data = <%= @data.to_json %>;</script>
```

**SAFE:**
```erb
<%= params[:query] %>
<%= sanitize(@user.bio) %>
<%= @card.description %>
<script>var data = <%= json_escape(@data.to_json) %>;</script>
```

Validate URL protocols before rendering user-supplied links:
```erb
<%= link_to "Website", @user.website_url if @user.website_url&.match?(%r{\Ahttps?://}) %>
```

Use `\A` / `\z` in regex validations — not `^` / `$` (line vs. string boundaries):
```ruby
validates :slug, format: { with: /\A[a-z0-9-]+\z/ }  # SAFE
validates :slug, format: { with: /^[a-z0-9-]+$/ }    # UNSAFE — allows newline injection
```

### Command Injection — Use array form for shell calls

```ruby
# UNSAFE — single string passes through the shell
system("convert #{params[:file]} output.png")

# SAFE — array form bypasses shell interpretation
system("convert", uploaded_file.path, "output.png")
stdout, _s = Open3.capture2("grep", "-r", query, "/data")

# If a shell string is unavoidable, escape the argument
system("tar -czf archive.tar.gz #{Shellwords.escape(directory)}")
```

---

## Part 2: Request Integrity

### CSRF — Never skip `verify_authenticity_token` for browser controllers

Rails enables CSRF protection by default via `ApplicationController`. Only API controllers using token-based auth should opt out.

```ruby
# UNSAFE — disables CSRF on a browser controller
class PaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token
end

# SAFE — inherits CSRF from ApplicationController
class PaymentsController < ApplicationController
end

# Correct — ActionController::API excludes CSRF; authenticate with tokens instead
class Api::V1::BaseController < ActionController::API
  before_action :authenticate_api_token
end
```

Always use `form_with` (never hand-craft `<form>` tags without CSRF token). State-changing actions must use non-GET HTTP methods:

```ruby
# UNSAFE
get "posts/:id/publish", to: "posts#publish"

# SAFE
resource :publication, only: [:create, :destroy]
```

### Strong Parameters — Always allowlist, never permit!

```ruby
# UNSAFE
@user = User.create(params[:user])
@user.update(params.permit!)

# SAFE
def user_params
  params.require(:user).permit(:name, :email)
end
```

Never include privilege-escalation attributes (`admin`, `role`, `account_id`, `verified`) in permit lists — set them explicitly with authorization checks. Scope nested attributes:

```ruby
def project_params
  params.require(:project).permit(:name,
    tasks_attributes: [:id, :title, :done, :_destroy])
end
```

### Open Redirects — Validate redirect targets

```ruby
# UNSAFE
redirect_to params[:return_to]

# SAFE — only allow same-host redirects
def safe_redirect?(url)
  uri = URI.parse(url.to_s)
  uri.host.nil? || uri.host == request.host
rescue URI::InvalidURIError
  false
end

# For external redirects, use an explicit allowlist
ALLOWED_REDIRECT_HOSTS = %w[accounts.example.com auth.example.com].freeze
```

---

## Part 3: Authentication & Authorization

### Authentication — Required by default, opt-out explicitly

Every controller inheriting from `ApplicationController` must require authentication. Use `allow_unauthenticated_access` only for intentionally public actions.

```ruby
# ApplicationController
class ApplicationController < ActionController::Base
  before_action :authenticate
end

# Only public actions opt out explicitly
class SessionsController < ApplicationController
  allow_unauthenticated_access only: [:new, :create]
end
```

**Password storage:** Always use `has_secure_password` (bcrypt). Never MD5, SHA1, or plain text.

**Token comparison:** Use `ActiveSupport::SecurityUtils.secure_compare` to prevent timing attacks:
```ruby
if ActiveSupport::SecurityUtils.secure_compare(actual_token, expected_token)
  process_webhook
end
```

**Rate limiting on auth endpoints:**
```ruby
class SessionsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_session_path, alert: "Try again later." }
end
```

### Authorization & IDOR — Always scope through the current user/account

Never look up records by raw ID without scoping:

```ruby
# UNSAFE — any user can access any board
@board = Board.find(params[:id])

# SAFE — scoped through current user
@board = Current.user.boards.find(params[:id])
@card  = Current.user.accessible_cards.find_by!(number: params[:card_id])
```

For multi-tenant applications, scope through `Current.account` at every query layer — including model scopes:

```ruby
class Card < ApplicationRecord
  scope :recent, -> {
    where(account: Current.account).order(created_at: :desc).limit(10)
  }
end
```

Nested resource controllers must chain the scope to the parent — never look up child records globally:

```ruby
# UNSAFE — any comment, not scoped to card
@comment = Comment.find(params[:id])

# SAFE
@card    = Current.user.accessible_cards.find_by!(number: params[:card_id])
@comment = @card.comments.find(params[:id])
```

Destructive actions need explicit authorization checks beyond authentication:

```ruby
def destroy
  @board = Current.user.boards.find(params[:id])
  if Current.user.can_administer_board?(@board)
    @board.destroy
  else
    head :forbidden
  end
end
```

### Session Security

```ruby
# Regenerate session after login to prevent session fixation
def create
  if user = User.authenticate_by(email: params[:email], password: params[:password])
    reset_session
    session[:user_id] = user.id
  end
end
```

Production session store configuration:
```ruby
Rails.application.config.session_store :cookie_store,
  key: "_app_session",
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax,
  expire_after: 12.hours
```

---

## Part 4: Data Protection

### Secrets — Never hardcode; always use Rails credentials or ENV

```ruby
# UNSAFE
API_KEY = "sk_live_abc123xyz"

# SAFE
API_KEY = Rails.application.credentials.stripe[:api_key]
# Or: ENV.fetch("STRIPE_API_KEY")
```

Production secret_key_base must come from credentials or env — never from the development value.

### Log Filtering — Filter all sensitive fields

```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :password, :password_confirmation,
  :token, :api_key, :secret,
  :credit_card, :card_number, :cvv,
  :ssn, :social_security
]
```

Never log user PII, tokens, or payment data. Log IDs, not values:
```ruby
Rails.logger.info "User login: user_id=#{user.id}"  # SAFE
Rails.logger.info "User login: #{user.email}, token: #{user.auth_token}"  # UNSAFE
```

### File Uploads — Validate type, size, and storage location

```ruby
class Document < ApplicationRecord
  has_one_attached :file

  validates :file,
    content_type: %w[application/pdf image/png image/jpeg],
    size: { less_than: 10.megabytes }

  validate :reject_dangerous_content_types

  private
    def reject_dangerous_content_types
      dangerous = %w[text/html application/javascript application/x-httpd-php]
      errors.add(:file, "type not allowed") if file.attached? && dangerous.include?(file.content_type)
    end
end
```

Use ActiveStorage (files stored outside `public/`). Never store uploads directly in `public/uploads/`. Prevent path traversal in download endpoints:

```ruby
def download
  filename = File.basename(params[:filename])
  path = Rails.root.join("uploads", filename)
  path.to_s.start_with?(Rails.root.join("uploads").to_s) ? send_file(path) : head(:forbidden)
end
```

---

## Part 5: Infrastructure Security

### Force SSL and configure security headers

```ruby
# config/environments/production.rb
config.force_ssl = true  # Enables HSTS, redirects HTTP→HTTPS, marks cookies as secure
```

Content Security Policy (avoid `unsafe-inline`/`unsafe-eval`):
```ruby
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src  :self
    policy.style_src   :self, :unsafe_inline
    policy.img_src     :self, :data, "https://storage.example.com"
    policy.connect_src :self
  end
  config.content_security_policy_nonce_generator = ->(req) { req.session.id.to_s }
end
```

Additional headers:
```ruby
# config/initializers/default_headers.rb
Rails.application.config.action_dispatch.default_headers.merge!(
  "Referrer-Policy"   => "strict-origin-when-cross-origin",
  "Permissions-Policy" => "camera=(), microphone=(), geolocation=()",
  "X-Content-Type-Options" => "nosniff"
)
```

### API Security

Token authentication on the base API controller, tenant-scoped responses:

```ruby
class Api::V1::BaseController < ActionController::API
  before_action :authenticate_api_token

  private
    def authenticate_api_token
      token = request.headers["Authorization"]&.remove("Bearer ")
      head :unauthorized unless token && ApiToken.active.exists?(token: token)
    end
end
```

Rate-limit API endpoints via Rails built-in or Rack::Attack:
```ruby
# Rails built-in (7.1+)
rate_limit to: 100, within: 1.minute

# Rack::Attack
Rack::Attack.throttle("api/requests", limit: 100, period: 1.minute) do |req|
  req.env["HTTP_AUTHORIZATION"]&.remove("Bearer ") if req.path.start_with?("/api/")
end
```

### Dependency Auditing

Run in CI on every build:
```bash
bundle audit check --update  # Ruby gems
yarn audit                   # JavaScript packages
brakeman --no-pager -q       # Static analysis
```

---

## Quick Reference: Severity Map

| Risk | Severity | Convention |
|---|---|---|
| SQL string interpolation | Critical | Use parameterized queries |
| XSS via `.html_safe` | Critical | Never bypass ERB escaping |
| CSRF disabled | Critical | Never skip `verify_authenticity_token` |
| `params.permit!` | Critical | Always allowlist params |
| Unscoped `find(params[:id])` | Critical | Scope through current user/account |
| Force SSL off | Critical | `config.force_ssl = true` in production |
| Hardcoded secrets | Critical | Use Rails credentials or ENV |
| Path traversal in uploads | Critical | Use ActiveStorage; never user-controlled paths |
| Command injection | Critical | Array form for shell calls |
| No rate limiting on auth | High | `rate_limit` on sessions controller |
| Timing attacks on tokens | High | `secure_compare` not `==` |
| Session fixation | High | `reset_session` before login |

For the full checklist with grep patterns and file globs, see [AUDIT.md](AUDIT.md).
