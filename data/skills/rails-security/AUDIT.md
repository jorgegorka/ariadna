---
name: rails-security-audit
description: Security audit checklist with grep patterns and file globs for systematic code review. Referenced from SKILL.md.
---

# Rails Security Audit Checklist

Systematic checklist for verifying security after each development phase. Each check includes a severity, grep pattern, and file scope so an agent or reviewer can scan changed files methodically.

---

## How to Use

### Step 1: Identify changed files

```bash
git diff --name-only HEAD~1
# For a full phase: git diff <phase-start-sha>..HEAD --name-only
```

### Step 2: Map files to applicable checks

| Changed file pattern | Applicable checks |
|---|---|
| `app/models/**/*.rb` | 1.1a, 1.1b, 1.4a, 2.2c, 3.1b, 3.2c, 4.3a, 4.3b |
| `app/controllers/**/*.rb` | 1.1c, 1.1d, 1.2e, 2.1a, 2.2a, 2.2b, 2.3a, 3.1a, 3.1c, 3.2a, 3.2b, 3.2d, 3.3a |
| `app/views/**/*.erb` | 1.2a, 1.2b, 1.2c, 1.2d, 2.1b |
| `app/controllers/api/**/*.rb` | 5.2a, 5.2b, 5.2c |
| `config/routes.rb` | 2.1c, 2.3a |
| `config/environments/production.rb` | 4.1c, 5.1a |
| `config/initializers/**/*.rb` | 3.3b, 3.3c, 4.2a, 5.1b, 5.1c |
| `app/models/session.rb` | 3.3a, 3.3c |
| `db/migrate/**/*.rb` | 3.1b |
| `lib/**/*.rb` | 1.1b, 1.3a, 1.3b |
| `Gemfile` / `Gemfile.lock` | 5.3a |
| `package.json` / `yarn.lock` | 5.3b |
| `app/javascript/**/*.js` | 1.2d, 2.1b |

### Step 3: Report format

```
PASS: CHECK 1.1a — No string interpolation in SQL (scanned 3 files)
FAIL: CHECK 3.2a — Unscoped find in app/controllers/boards_controller.rb:15
SKIP: CHECK 4.3a — No file upload changes in this phase
```

---

## Full Checklist

| Check | Name | Severity | Grep pattern | Files |
|---|---|---|---|---|
| **1.1a** | No SQL string interpolation | Critical | `\.where\(["'].*#\{` | `app/models/**/*.rb`, `app/controllers/**/*.rb` |
| **1.1b** | Parameterized raw SQL | Critical | `\.execute\(["'].*#\{` | `app/models/**/*.rb`, `lib/**/*.rb` |
| **1.1c** | Allowlisted order/group columns | High | `\.order\(params` | `app/controllers/**/*.rb` |
| **1.1d** | Scoped find for user lookups | High | `\.find\(params\[` | `app/controllers/**/*.rb` |
| **1.2a** | No raw/html_safe on user input | Critical | `\.html_safe\|raw(` | `app/views/**/*.erb`, `app/helpers/**/*.rb` |
| **1.2b** | Sanitized rich text output | High | `\.to_s\.html_safe` | `app/views/**/*.erb` |
| **1.2c** | Safe link_to href values | High | `link_to.*params\[` | `app/views/**/*.erb` |
| **1.2d** | JSON escaped in script tags | High | `<script>.*to_json` | `app/views/**/*.erb` |
| **1.2e** | Content-Type for non-HTML responses | Medium | `render plain:` | `app/controllers/**/*.rb` |
| **1.3a** | No user input in shell calls | Critical | `system\(["'].*#\{` | `app/**/*.rb`, `lib/**/*.rb` |
| **1.3b** | Shellwords for unavoidable shell use | High | `Shellwords\.escape` | `app/**/*.rb`, `lib/**/*.rb` |
| **1.4a** | `\A`/`\z` not `^`/`$` in regex | High | `format:.*\/\^` | `app/models/**/*.rb`, `app/validators/**/*.rb` |
| **2.1a** | CSRF protection enabled | Critical | `skip_before_action :verify_authenticity` | `app/controllers/**/*.rb` |
| **2.1b** | Authenticity token in forms | High | `<form[^>]*method` | `app/views/**/*.erb` |
| **2.1c** | Non-GET for state-changing routes | High | `get.*destroy\|get.*delete\|get.*create` | `config/routes.rb` |
| **2.2a** | Strong parameters — no permit! | Critical | `params\.permit!` | `app/controllers/**/*.rb` |
| **2.2b** | No admin/role attrs in permit | High | `permit.*:admin\|permit.*:role` | `app/controllers/**/*.rb` |
| **2.2c** | Nested attributes scoped | Medium | `accepts_nested_attributes_for` | `app/models/**/*.rb` |
| **2.3a** | No open redirects from params | High | `redirect_to params\[` | `app/controllers/**/*.rb` |
| **2.3b** | External redirect allowlists | Medium | `allow_other_host: true` | `app/controllers/**/*.rb` |
| **3.1a** | Auth required on all controllers | Critical | `skip_before_action :authenticate` | `app/controllers/**/*.rb` |
| **3.1b** | Secure password storage | Critical | `Digest::MD5\|Digest::SHA1` | `app/models/**/*.rb` |
| **3.1c** | Timing-safe token comparison | High | `==.*token\|==.*secret` | `app/controllers/**/*.rb`, `app/models/**/*.rb` |
| **3.1d** | Rate limiting on auth endpoints | High | `rate_limit` | `app/controllers/sessions_controller.rb` |
| **3.2a** | Scoped resource lookups | Critical | `\.find\(params\[:id\]\)` | `app/controllers/**/*.rb` |
| **3.2b** | Authz check on destructive actions | High | `def destroy` | `app/controllers/**/*.rb` |
| **3.2c** | Tenant isolation in queries | Critical | `Current\.account` | `app/models/**/*.rb`, `app/controllers/**/*.rb` |
| **3.2d** | Nested resource scoped to parent | High | `Comment\.find\|\.find\(params\[:id\]\)` | `app/controllers/**/*.rb` |
| **3.3a** | Session regeneration after login | High | `reset_session` | `app/controllers/sessions_controller.rb` |
| **3.3b** | Secure cookie configuration | High | `session_store.*secure` | `config/environments/production.rb`, `config/initializers/**/*.rb` |
| **3.3c** | Session expiration configured | Medium | `expire_after` | `config/initializers/**/*.rb`, `app/models/session.rb` |
| **4.1a** | No hardcoded secrets | Critical | `API_KEY\|SECRET\|password.*=.*["']` | `app/**/*.rb`, `config/**/*.rb` |
| **4.1b** | Credentials encrypted, not committed | High | `secrets\.yml\|\.env` | `config/**/*.yml`, `.gitignore` |
| **4.1c** | Secret key base from credentials/env | Critical | `secret_key_base` | `config/environments/production.rb` |
| **4.2a** | All sensitive params filtered | High | `filter_parameters` | `config/initializers/filter_parameter_logging.rb` |
| **4.2b** | No PII/tokens in logs | High | `logger.*token\|logger.*password\|logger.*email` | `app/**/*.rb`, `lib/**/*.rb` |
| **4.3a** | File upload content type validated | High | `content_type:` | `app/models/**/*.rb` |
| **4.3b** | File upload size limited | High | `size:.*less_than` | `app/models/**/*.rb` |
| **4.3c** | Safe file download path | Critical | `send_file.*params` | `app/controllers/**/*.rb` |
| **4.3d** | No uploads in public directory | High | `public.*uploads` | `app/controllers/**/*.rb`, `config/storage.yml` |
| **5.1a** | Force SSL enabled in production | Critical | `force_ssl` | `config/environments/production.rb` |
| **5.1b** | CSP configured and restrictive | High | `content_security_policy` | `config/initializers/**/*.rb` |
| **5.1c** | Security headers set | Medium | `Referrer-Policy\|Permissions-Policy` | `config/initializers/**/*.rb` |
| **5.2a** | API authentication on all endpoints | Critical | `before_action.*authenticate` | `app/controllers/api/**/*.rb` |
| **5.2b** | API responses tenant-scoped | High | `Current\.account` | `app/controllers/api/**/*.rb` |
| **5.2c** | API rate limiting configured | Medium | `rate_limit\|Rack::Attack` | `app/controllers/api/**/*.rb`, `config/initializers/**/*.rb` |
| **5.3a** | No vulnerable gems | High | `bundle audit check --update` | `Gemfile.lock` |
| **5.3b** | No vulnerable JS packages | High | `yarn audit` | `package.json`, `yarn.lock` |

---

## Step 4: Automated Tools

Run after manual checks:

```bash
# Dependency audits
bundle audit check --update
yarn audit

# Static analysis
brakeman --no-pager -q

# Check for accidentally committed secrets/keys
git log --diff-filter=A --name-only -- "*.key" "*.pem" ".env*"
```
