# Verification Patterns

How to verify different types of artifacts are real implementations, not stubs or placeholders.

<core_principle>
**Existence ≠ Implementation**

A file existing does not mean the feature works. Verification must check:
1. **Exists** - File is present at expected path
2. **Substantive** - Content is real implementation, not placeholder
3. **Wired** - Connected to the rest of the system
4. **Functional** - Actually works when invoked

Levels 1-3 can be checked programmatically. Level 4 often requires human verification.
</core_principle>

<stub_detection>

## Universal Stub Patterns

These patterns indicate placeholder code regardless of file type:

**Comment-based stubs:**
```bash
# Grep patterns for stub comments
grep -E "(TODO|FIXME|XXX|HACK|PLACEHOLDER)" "$file"
grep -E "implement|add later|coming soon|will be" "$file" -i
grep -E "// \.\.\.|/\* \.\.\. \*/|# \.\.\." "$file"
```

**Placeholder text in output:**
```bash
# UI placeholder patterns
grep -E "placeholder|lorem ipsum|coming soon|under construction" "$file" -i
grep -E "sample|example|test data|dummy" "$file" -i
grep -E "\[.*\]|<.*>|\{.*\}" "$file"  # Template brackets left in
```

**Empty or trivial implementations:**
```bash
# Functions that do nothing
grep -E "return nil|return \{\}|return \[\]" "$file"
grep -E "pass$|\.\.\.|\bnothing\b|raise NotImplementedError" "$file"
grep -E "puts.*only|Rails\.logger\.(info|debug).*only" "$file"  # Log-only functions
```

**Hardcoded values where dynamic expected:**
```bash
# Hardcoded IDs, counts, or content
grep -E "id.*=.*['\"].*['\"]" "$file"  # Hardcoded string IDs
grep -E "count.*=.*\d+|length.*=.*\d+" "$file"  # Hardcoded counts
grep -E "\\\$\d+\.\d{2}|\d+ items" "$file"  # Hardcoded display values
```

</stub_detection>

<api_routes>

## Rails Controllers and API Endpoints

**Existence check:**
```bash
# Controller file exists and defines class
[ -f "$controller_path" ] && grep -E "class.*Controller < Application" "$controller_path"

# Expected actions are defined
grep -E "def (index|show|create|update|destroy|new|edit)" "$controller_path"

# Route exists in config/routes.rb
grep -E "resources :$resource_name|get.*$controller_name|post.*$controller_name" config/routes.rb
```

**Substantive check:**
```bash
# Has actual logic, not just return statement
wc -l "$controller_path"  # More than 10-15 lines suggests real implementation

# Interacts with models (ActiveRecord)
grep -E "$model_name\.(find|where|create|new|update|destroy|all|first|last)" "$controller_path"

# Has error handling
grep -E "rescue|rescue_from|begin|raise" "$controller_path"

# Returns meaningful response
grep -E "render json:|render|redirect_to|respond_to" "$controller_path" | grep -v "not implemented" -i
```

**Stub patterns specific to Rails controllers:**
```ruby
# RED FLAGS - These are stubs:
def create
  render json: { message: "Not implemented" }
end

def index
  render json: []  # Empty array with no DB query
end

def update
  head :ok  # Empty response, no persistence
end

# Log only:
def create
  Rails.logger.info(params.inspect)
  render json: { ok: true }
end
```

**Wiring check:**
```bash
# Uses strong parameters
grep -E "def .*_params|params\.require|params\.permit" "$controller_path"

# Actually uses request params (for create/update)
grep -E "params\[|params\.require|params\.permit" "$controller_path"

# Has validations via model or inline
grep -E "validates|valid\?|errors|ActiveModel" "$controller_path"
```

**Functional verification (human or automated):**
- Does index return real data from database?
- Does create actually persist a record?
- Does error response have correct status code?
- Are auth checks actually enforced (before_action)?

</api_routes>

<database_schema>

## Database Schema (ActiveRecord Migrations / schema.rb)

**Existence check:**
```bash
# Schema file exists
[ -f "db/schema.rb" ] || [ -f "db/structure.sql" ]

# Table is defined in schema
grep -E "create_table.*\"$table_name\"|create_table.*:$table_name" db/schema.rb

# Migration exists for this table
ls db/migrate/*_create_$table_name* 2>/dev/null
```

**Substantive check:**
```bash
# Has expected columns (not just id and timestamps)
grep -A 30 "create_table.*$table_name" db/schema.rb | grep -E "t\.\w+"

# Has relationships (foreign keys)
grep -E "foreign_key.*$table_name\|add_foreign_key.*$table_name\|references.*$table_name" db/schema.rb

# Has appropriate column types (not all string)
grep -A 30 "create_table.*$table_name" db/schema.rb | grep -E "t\.(integer|datetime|boolean|float|decimal|jsonb|text|bigint)"
```

**Stub patterns specific to ActiveRecord:**
```ruby
# RED FLAGS - These are stubs:
create_table :users do |t|
  # TODO: add columns
  t.timestamps
end

create_table :messages do |t|
  t.string :content  # Only one real column
  t.timestamps
end

# Missing critical columns:
create_table :orders do |t|
  # No: user reference, items, total, status
  t.timestamps
end
```

**Wiring check:**
```bash
# Migrations exist and are applied
bin/rails db:migrate:status 2>/dev/null | grep -E "up|down"

# No pending migrations
bin/rails db:migrate:status 2>/dev/null | grep -c "down"  # Should be 0
```

**Functional verification:**
```bash
# Can query the table (automated)
bin/rails dbconsole <<< "SELECT COUNT(*) FROM $table_name"
# Or via runner
bin/rails runner "puts $model_name.count"
```

</database_schema>

<ruby_classes>

## Ruby Classes and Modules

**Existence check:**
```bash
# File exists and defines class/module
[ -f "$class_path" ] && grep -E "^(class|module) " "$class_path"
```

**Substantive check:**
```bash
# Has real methods, not just stubs
grep -E "^\s+def " "$class_path" | wc -l  # Count methods
grep -E "raise NotImplementedError|# TODO|# FIXME" "$class_path"  # Stub markers

# Methods have bodies (not single-line stubs)
grep -A 3 "def " "$class_path" | grep -v "raise NotImplementedError\|nil$\|end$" | head -20
```

**Stub patterns specific to Ruby:**
```ruby
# RED FLAGS - These are stubs:
def process(data)
  raise NotImplementedError
end

def calculate
  nil  # Just returns nil
end

def perform
  # TODO: implement
end

def call
  puts "not yet implemented"
end
```

**Wiring check:**
```bash
# Class is required/used somewhere
grep -r "require.*$module_name\|$class_name\.new\|$class_name\." lib/ app/ --include="*.rb" | grep -v "$class_path"

# For modules, check includes
grep -r "include $module_name\|extend $module_name\|prepend $module_name" --include="*.rb"
```

</ruby_classes>

<rails_controllers>

## Rails Controllers and Actions

**Existence check:**
```bash
# Controller file exists and defines class
[ -f "$controller_path" ] && grep -E "class.*Controller" "$controller_path"

# Expected actions defined
grep -E "def (index|show|create|update|destroy|new|edit)" "$controller_path"
```

**Substantive check:**
```bash
# Actions have more than just render/redirect
grep -A 10 "def $action_name" "$controller_path" | grep -E "@|params|find|where|create|update|save"

# Has strong parameters
grep -E "def .*_params|params\.require|params\.permit" "$controller_path"

# Has error handling
grep -E "rescue|rescue_from|begin|raise" "$controller_path"
```

**Stub patterns specific to Rails controllers:**
```ruby
# RED FLAGS - These are stubs:
def index
  render json: []  # Empty array, no query
end

def create
  render json: { status: "ok" }  # No actual creation
end

def show
  # TODO: implement
  head :ok
end

def update
  render json: params  # Echo params, no persistence
end
```

**Wiring check:**
```bash
# Route exists for this controller
grep -E "$controller_name" config/routes.rb

# Callbacks/filters are referenced
grep -E "before_action|after_action|around_action" "$controller_path"

# Views exist (for non-API controllers)
ls "app/views/$controller_dir/$action_name"* 2>/dev/null
```

</rails_controllers>

<rails_models>

## ActiveRecord Models

**Existence check:**
```bash
# Model file exists
[ -f "$model_path" ] && grep -E "class.*< ApplicationRecord|class.*< ActiveRecord::Base" "$model_path"

# Migration exists
ls db/migrate/*_create_$table_name* 2>/dev/null
```

**Substantive check:**
```bash
# Has validations
grep -E "validates|validate " "$model_path"

# Has associations
grep -E "belongs_to|has_many|has_one|has_and_belongs_to_many" "$model_path"

# Has scopes or business logic
grep -E "scope :|def self\.|def " "$model_path"

# Schema has expected columns (check schema.rb or migration)
grep -A 30 "create_table.*$table_name" db/schema.rb | grep -E "t\.\w+"
```

**Stub patterns specific to ActiveRecord:**
```ruby
# RED FLAGS - These are stubs:
class Order < ApplicationRecord
  # Empty model, no validations or associations
end

class User < ApplicationRecord
  has_many :posts  # Association but no validations
  # No: validates, scopes, callbacks, or methods
end

class Payment < ApplicationRecord
  def process
    # TODO: integrate with payment gateway
    true
  end
end
```

**Wiring check:**
```bash
# Model is used in controllers
grep -r "$model_name\." app/controllers/ --include="*.rb"

# Associations target existing models
grep -E "belongs_to|has_many|has_one" "$model_path" | grep -oP ":\w+" | while read assoc; do
  model_file="app/models/${assoc#:}.rb"
  [ -f "$model_file" ] && echo "WIRED: $assoc" || echo "MISSING: $assoc model"
done

# Migrations are applied
bin/rails db:migrate:status 2>/dev/null | grep -E "up|down"
```

</rails_models>

<ruby_services>

## Ruby Services / POROs (Plain Old Ruby Objects)

**Existence check:**
```bash
# File exists and defines class
[ -f "$service_path" ] && grep -E "^class " "$service_path"
```

**Substantive check:**
```bash
# Has a clear entry point (call, perform, execute, run)
grep -E "def (call|perform|execute|run)" "$service_path"

# Has real logic (not just delegation)
[ $(wc -l < "$service_path") -gt 15 ]

# Has error handling
grep -E "rescue|raise|begin" "$service_path"
```

**Stub patterns specific to services:**
```ruby
# RED FLAGS - These are stubs:
class UserCreator
  def call(params)
    User.create(params)  # Just wraps create, adds nothing
  end
end

class PaymentProcessor
  def call(amount)
    puts "Processing #{amount}"  # Log-only
    true
  end
end

class NotificationService
  def call(user, message)
    # TODO: send notification
    nil
  end
end
```

**Wiring check:**
```bash
# Service is used somewhere
grep -r "$service_name" app/ lib/ --include="*.rb" | grep -v "$service_path"

# Service is called (instantiated and invoked)
grep -r "$service_name\.new\|$service_name\.call\|$service_name\.()" --include="*.rb"
```

</ruby_services>

<hooks_utilities>

## Rails Helpers, Concerns, and Utility Modules

**Existence check:**
```bash
# Helper file exists and defines module
[ -f "$helper_path" ] && grep -E "module.*Helper" "$helper_path"

# Or concern exists
[ -f "$concern_path" ] && grep -E "module.*|extend ActiveSupport::Concern" "$concern_path"

# Or service object exists
[ -f "$service_path" ] && grep -E "class " "$service_path"
```

**Substantive check:**
```bash
# Helper has real methods (not empty)
grep -E "def " "$helper_path" | wc -l  # Should be > 0

# Concern has meaningful behavior (not just empty included block)
grep -A 5 "included do" "$concern_path" | grep -E "validates|has_many|belongs_to|scope|before_action"

# More than trivial length
[ $(wc -l < "$helper_path") -gt 10 ]
```

**Stub patterns specific to helpers/concerns:**
```ruby
# RED FLAGS - These are stubs:
module AuthHelper
  def current_user
    nil  # Always returns nil
  end

  def authenticate!
    # TODO: implement
  end
end

module Authenticatable
  extend ActiveSupport::Concern

  included do
    # Nothing here
  end
end

# Hardcoded return:
module UserHelper
  def user_display_name
    "Test User"  # Hardcoded, not from model
  end
end
```

**Wiring check:**
```bash
# Helper is included in a controller or view
grep -r "include.*$helper_name\|helper.*$helper_name" app/ --include="*.rb"

# Concern is included in a model or controller
grep -r "include.*$concern_name" app/models/ app/controllers/ --include="*.rb" | grep -v "$concern_path"

# Service is instantiated or called somewhere
grep -r "$service_name\.new\|$service_name\.call" app/ lib/ --include="*.rb" | grep -v "$service_path"
```

</hooks_utilities>

<environment_config>

## Environment Variables and Configuration

**Existence check:**
```bash
# .env file exists
[ -f ".env" ] || [ -f ".env.local" ]

# Required variable is defined
grep -E "^$VAR_NAME=" .env .env.local 2>/dev/null
```

**Substantive check:**
```bash
# Variable has actual value (not placeholder)
grep -E "^$VAR_NAME=.+" .env .env.local 2>/dev/null | grep -v "your-.*-here|xxx|placeholder|TODO" -i

# Value looks valid for type:
# - URLs should start with http
# - Keys should be long enough
# - Booleans should be true/false
```

**Stub patterns specific to env:**
```bash
# RED FLAGS - These are stubs:
DATABASE_URL=your-database-url-here
STRIPE_SECRET_KEY=sk_test_xxx
API_KEY=placeholder
NEXT_PUBLIC_API_URL=http://localhost:3000  # Still pointing to localhost in prod
```

**Wiring check:**
```bash
# Variable is actually used in code
grep -r "ENV\[\"$VAR_NAME\"\]\|ENV\.fetch(\"$VAR_NAME\")\|ENV\['$VAR_NAME'\]" app/ lib/ config/ --include="*.rb"

# Variable is in credentials or application config
grep -E "$VAR_NAME" config/credentials.yml.enc 2>/dev/null  # Encrypted, check via `bin/rails credentials:show`
grep -E "$VAR_NAME" config/application.yml config/settings.yml 2>/dev/null
```

</environment_config>

<wiring_verification>

## Wiring Verification Patterns

Wiring verification checks that components actually communicate. This is where most stubs hide.

### Pattern: View → Controller

**Check:** Does the view actually submit data to the correct controller action?

```bash
# Find form actions pointing to controller
grep -E "form_with\|form_for\|form_tag\|url:.*_path\|action:.*_path" "$view_path"

# Verify link_to / button_to targets exist
grep -E "link_to.*_path\|button_to.*_path" "$view_path"

# Check Turbo Frame/Stream targets (Hotwire)
grep -E "turbo_frame_tag\|turbo_stream" "$view_path"
```

**Red flags:**
```erb
<%# Form exists but points nowhere: %>
<%= form_with url: "#" do |f| %>

<%# Link to undefined route: %>
<%= link_to "Show", "/undefined_path" %>

<%# Form action commented out: %>
<%# form_with model: @user do |f| %>
```

### Pattern: Controller → Model

**Check:** Does the controller actually query/persist via the model?

```bash
# Find model usage in controller
grep -E "$model_name\.(find|where|create|new|update|destroy|all|first|last)" "$controller_path"

# Verify result is assigned to instance variable
grep -E "@$instance_var.*=.*$model_name\." "$controller_path"

# Check result is used in response
grep -E "render.*@$instance_var\|redirect_to.*@$instance_var\|respond_with.*@$instance_var" "$controller_path"
```

**Red flags:**
```ruby
# Model queried but result unused:
def show
  User.find(params[:id])  # No assignment
  render json: { ok: true }
end

# Hardcoded instead of queried:
def index
  @users = [{ name: "Test" }]  # Not from DB
end

# Params not passed to model:
def create
  @user = User.create  # No params
  redirect_to @user
end
```

### Pattern: Form → Controller Action

**Check:** Does the form submission actually trigger persistence?

```bash
# Find form_with targeting a model or URL
grep -E "form_with.*model:|form_with.*url:" "$view_path"

# Check controller action has strong params and saves
grep -A 10 "def create\|def update" "$controller_path" | grep -E "\.save\|\.create\|\.update"

# Verify redirect or render after save
grep -A 15 "def create\|def update" "$controller_path" | grep -E "redirect_to\|render"
```

**Red flags:**
```ruby
# Controller action doesn't save:
def create
  @user = User.new(user_params)
  # Missing: @user.save
  redirect_to users_path
end

# Action only logs:
def create
  Rails.logger.info(params.inspect)
  render json: { ok: true }
end

# Empty action:
def create
  head :ok
end
```

### Pattern: Instance Variable → View

**Check:** Does the view render data from instance variables, not hardcoded content?

```bash
# Find instance variable usage in view
grep -E "@$instance_var\b" "$view_path"

# Check iteration over collections
grep -E "@$collection\.each\|@$collection\.map" "$view_path"

# Verify dynamic content (ERB interpolation)
grep -E "<%=.*@" "$view_path"
```

**Red flags:**
```erb
<%# Hardcoded instead of from instance var: %>
<p>Message 1</p>
<p>Message 2</p>

<%# Instance var exists but not rendered: %>
<%# Controller sets @messages but view shows: %>
<p>No messages</p>

<%# Wrong variable rendered: %>
<% @other_data.each do |item| %>  <%# Should be @messages %>
```

### Pattern: Rails Model → Database

**Check:** Does the model define validations and associations that match the schema?

```bash
# Check schema has expected columns
grep -A 30 "create_table.*$table_name" db/schema.rb

# Check model declares associations
grep -E "belongs_to|has_many|has_one" "$model_path"

# Check foreign keys exist in schema
grep "foreign_key.*$table_name\|$table_name.*foreign_key" db/schema.rb
```

### Pattern: Ruby Service → Dependencies

**Check:** Does the service actually use its injected or imported dependencies?

```bash
# Find initialize with dependencies
grep -A 5 "def initialize" "$service_path"

# Verify dependencies are used in methods
grep -E "@[a-z_]+\." "$service_path" | grep -v "def initialize"
```

</wiring_verification>

<verification_checklist>

## Quick Verification Checklist

For each artifact type, run through this checklist:

### Rails View Checklist
- [ ] File exists at expected path (`app/views/`)
- [ ] Renders dynamic content via instance variables (not hardcoded)
- [ ] No placeholder text in output
- [ ] Forms use `form_with` pointing to valid routes
- [ ] Partials exist if referenced (`render partial:`)
- [ ] Turbo frames/streams wired correctly (if using Hotwire)
- [ ] Layout references resolve
- [ ] Used by at least one controller action

### Rails Controller Checklist
- [ ] File exists at expected path
- [ ] Inherits from ApplicationController (or API base)
- [ ] Expected actions defined (index, show, create, etc.)
- [ ] Actions query/persist via model (not hardcoded)
- [ ] Strong parameters defined
- [ ] Callbacks/filters set up (authentication, authorization)
- [ ] Route defined in config/routes.rb
- [ ] Views exist (for non-API controllers)

### ActiveRecord Model Checklist
- [ ] File exists at expected path
- [ ] Inherits from ApplicationRecord
- [ ] Validations present for required fields
- [ ] Associations defined and match schema
- [ ] Migration exists and is applied
- [ ] Schema has expected columns and types
- [ ] Indexes defined for queried columns

### Ruby Service/PORO Checklist
- [ ] File exists at expected path
- [ ] Has clear entry point (call/perform/execute)
- [ ] Has meaningful implementation (not stub)
- [ ] Used somewhere in the app
- [ ] Error handling present
- [ ] Dependencies injected or required

### Wiring Checklist (Ruby/Rails)
- [ ] Controller → Model: actions query/persist, results assigned to instance vars
- [ ] Model → Database: validations match schema constraints, associations valid
- [ ] Service → Dependencies: injected deps are actually used in methods
- [ ] Routes → Controller: all routes resolve to existing controller actions

</verification_checklist>

<automated_verification_script>

## Automated Verification Approach

For the verification subagent, use this pattern:

```bash
# 1. Check existence
check_exists() {
  [ -f "$1" ] && echo "EXISTS: $1" || echo "MISSING: $1"
}

# 2. Check for stub patterns
check_stubs() {
  local file="$1"
  local stubs=$(grep -c -E "TODO|FIXME|placeholder|not implemented" "$file" 2>/dev/null || echo 0)
  [ "$stubs" -gt 0 ] && echo "STUB_PATTERNS: $stubs in $file"
}

# 3. Check wiring (view references controller, controller uses model)
check_wiring() {
  local source="$1"
  local target="$2"
  grep -q "$target" "$source" && echo "WIRED: $source → $target" || echo "NOT_WIRED: $source → $target"
}

# 4. Check substantive (more than N lines, has expected patterns)
check_substantive() {
  local file="$1"
  local min_lines="$2"
  local pattern="$3"
  local lines=$(wc -l < "$file" 2>/dev/null || echo 0)
  local has_pattern=$(grep -c -E "$pattern" "$file" 2>/dev/null || echo 0)
  [ "$lines" -ge "$min_lines" ] && [ "$has_pattern" -gt 0 ] && echo "SUBSTANTIVE: $file" || echo "THIN: $file ($lines lines, $has_pattern matches)"
}
```

Run these checks against each must-have artifact. Aggregate results into VERIFICATION.md.

</automated_verification_script>

<human_verification_triggers>

## When to Require Human Verification

Some things can't be verified programmatically. Flag these for human testing:

**Always human:**
- Visual appearance (does it look right?)
- User flow completion (can you actually do the thing?)
- Real-time behavior (WebSocket, SSE)
- External service integration (Stripe, email sending)
- Error message clarity (is the message helpful?)
- Performance feel (does it feel fast?)

**Human if uncertain:**
- Complex wiring that grep can't trace
- Dynamic behavior depending on state
- Edge cases and error states
- Mobile responsiveness
- Accessibility

**Format for human verification request:**
```markdown
## Human Verification Required

### 1. Chat message sending
**Test:** Type a message and click Send
**Expected:** Message appears in list, input clears
**Check:** Does message persist after refresh?

### 2. Error handling
**Test:** Disconnect network, try to send
**Expected:** Error message appears, message not lost
**Check:** Can retry after reconnect?
```

</human_verification_triggers>

<checkpoint_automation_reference>

## Pre-Checkpoint Automation

For automation-first checkpoint patterns, server lifecycle management, CLI installation handling, and error recovery protocols, see:

**@~/.claude/ariadna/references/checkpoints.md** → `<automation_reference>` section

Key principles:
- Claude sets up verification environment BEFORE presenting checkpoints
- Users never run CLI commands (visit URLs only)
- Server lifecycle: start before checkpoint, handle port conflicts, keep running for duration
- CLI installation: auto-install where safe, checkpoint for user choice otherwise
- Error handling: fix broken environment before checkpoint, never present checkpoint with failed setup

</checkpoint_automation_reference>
