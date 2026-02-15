# Performance Guide for Rails Code Review

**Agent-Oriented Performance Checklist for Automated Code Verification**

This guide provides a structured checklist for verifying code performance after each development phase. Each section contains named CHECK items with severity levels, file glob patterns, and UNSAFE/SAFE code examples so an agent can systematically scan changed files and report findings.

Unlike informational performance documentation, this guide is **action-oriented** — every check tells you what to look for, where to look, and how to fix it.

**Related guides:**
- [Backend Patterns](backend.md) — Architecture, models, controllers, jobs, style guide
- [Testing Patterns](testing.md) — Testing philosophy, model/controller/job test patterns
- [Security Guide](security.md) — Agent-oriented security checklist for code review
- [Frontend Patterns](frontend.md) — Presenter pattern, view layer conventions

## Table of Contents

- [Part 1: Database Query Performance](#part-1-database-query-performance)
  - [1.1 N+1 Queries](#11-n1-queries)
  - [1.2 Inefficient Queries](#12-inefficient-queries)
  - [1.3 Batch Processing](#13-batch-processing)
  - [1.4 Query Placement](#14-query-placement)
- [Part 2: Database Indexing](#part-2-database-indexing)
  - [2.1 Missing Indexes](#21-missing-indexes)
  - [2.2 Index Anti-Patterns](#22-index-anti-patterns)
- [Part 3: Caching](#part-3-caching)
  - [3.1 Cache Store Configuration](#31-cache-store-configuration)
  - [3.2 Fragment & Collection Caching](#32-fragment--collection-caching)
  - [3.3 Application-Level Caching](#33-application-level-caching)
- [Part 4: Memory & Resource Management](#part-4-memory--resource-management)
  - [4.1 Memory-Intensive Operations](#41-memory-intensive-operations)
  - [4.2 Background Job Offloading](#42-background-job-offloading)
  - [4.3 Unnecessary Object Allocation](#43-unnecessary-object-allocation)
- [Part 5: View & Response Performance](#part-5-view--response-performance)
  - [5.1 Collection Rendering](#51-collection-rendering)
  - [5.2 Asset & Frontend Performance](#52-asset--frontend-performance)
- [Part 6: Deployment & Configuration](#part-6-deployment--configuration)
  - [6.1 Server Tuning](#61-server-tuning)
  - [6.2 Production Settings](#62-production-settings)
- [Part 7: Performance Verification Checklist](#part-7-performance-verification-checklist)
  - [7.1 Agent Check Protocol](#71-agent-check-protocol)
  - [7.2 Quick-Reference Checklist](#72-quick-reference-checklist)

---

# Part 1: Database Query Performance

Database queries are the most common source of performance problems in Rails applications. These checks cover N+1 queries, inefficient query patterns, batch processing, and proper query placement.

## 1.1 N+1 Queries

N+1 queries occur when code loads a collection and then executes a separate query for each item's association. This turns a single query into dozens or hundreds.

### CHECK 1.1a: Eager load associations accessed in loops

> **What to look for:** Iterating over a collection and accessing an association (e.g., `post.author`, `order.line_items`) without a preceding `includes`, `eager_load`, or `preload` call
> **Where to look:** `app/controllers/**/*.rb`, `app/views/**/*.erb`, `app/models/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
# Controller
def index
  @posts = Post.all
end
```

```erb
<%# View — triggers N+1: one query per post for author %>
<% @posts.each do |post| %>
  <p><%= post.author.name %></p>
<% end %>
```

**SAFE:**

```ruby
# Controller
def index
  @posts = Post.includes(:author)
end
```

```erb
<%# View — author already loaded, no extra queries %>
<% @posts.each do |post| %>
  <p><%= post.author.name %></p>
<% end %>
```

### CHECK 1.1b: Nested association eager loading

> **What to look for:** Views or serializers that access deeply nested associations (e.g., `post.comments.map(&:author)`) without nested `includes`
> **Where to look:** `app/controllers/**/*.rb`, `app/views/**/*.erb`
> **Severity:** High

**UNSAFE:**

```ruby
def show
  @post = Post.includes(:comments).find(params[:id])
  # comment.author triggers N+1 inside the view
end
```

**SAFE:**

```ruby
def show
  @post = Post.includes(comments: :author).find(params[:id])
end
```

### CHECK 1.1c: Counter cache for association counts

> **What to look for:** Calling `.count` or `.size` on an association inside a loop without a `counter_cache` column
> **Where to look:** `app/views/**/*.erb`, `app/models/**/*.rb`
> **Severity:** Medium

**UNSAFE:**

```erb
<% @boards.each do |board| %>
  <span><%= board.cards.count %> cards</span>
<% end %>
```

**SAFE:**

```ruby
# Migration
add_column :boards, :cards_count, :integer, default: 0, null: false

# Model
class Card < ApplicationRecord
  belongs_to :board, counter_cache: true
end
```

```erb
<% @boards.each do |board| %>
  <span><%= board.cards_count %> cards</span>
<% end %>
```

---

## 1.2 Inefficient Queries

These patterns produce correct results but waste database resources by fetching more data than needed or executing queries that could be optimized.

### CHECK 1.2a: Select only needed columns

> **What to look for:** Queries that load full ActiveRecord objects when only one or two columns are needed; missing `select` or `pluck` for data extraction
> **Where to look:** `app/models/**/*.rb`, `app/controllers/**/*.rb`
> **Severity:** Medium

**UNSAFE:**

```ruby
# Loads all columns for every user just to get emails
emails = User.where(active: true).map(&:email)

# Loads full objects to get IDs
ids = Order.where(status: "pending").map(&:id)
```

**SAFE:**

```ruby
# Pluck returns plain arrays — no ActiveRecord objects allocated
emails = User.where(active: true).pluck(:email)

# IDs shortcut
ids = Order.where(status: "pending").ids
```

### CHECK 1.2b: Use exists? instead of present? for existence checks

> **What to look for:** `.present?`, `.any?`, or `.count > 0` on ActiveRecord relations when only existence is being checked
> **Where to look:** `app/models/**/*.rb`, `app/controllers/**/*.rb`, `app/views/**/*.erb`
> **Severity:** Medium

**UNSAFE:**

```ruby
# Loads all matching records into memory, then checks if array is non-empty
if user.orders.where(status: "pending").present?
  show_pending_banner
end

# Counts all rows just to compare with zero
if Comment.where(post_id: post.id).count > 0
  show_comments_section
end
```

**SAFE:**

```ruby
# SELECT 1 ... LIMIT 1 — stops at first match
if user.orders.where(status: "pending").exists?
  show_pending_banner
end

if Comment.where(post_id: post.id).exists?
  show_comments_section
end
```

### CHECK 1.2c: Avoid loading records just to count them

> **What to look for:** `.length` or `.size` called on relations that haven't been loaded, or `.count` called inside loops triggering repeated COUNT queries
> **Where to look:** `app/views/**/*.erb`, `app/controllers/**/*.rb`
> **Severity:** Medium

**UNSAFE:**

```ruby
# .length loads all records then counts the array
total = Project.where(archived: false).length

# .count inside a loop fires a COUNT query per iteration
@categories.each do |category|
  puts "#{category.name}: #{category.products.count}"
end
```

**SAFE:**

```ruby
# .count fires a single COUNT query
total = Project.where(archived: false).count

# Preload counts in a single query
counts = Product.group(:category_id).count
@categories.each do |category|
  puts "#{category.name}: #{counts[category.id] || 0}"
end
```

---

## 1.3 Batch Processing

Loading an entire table into memory crashes applications with large datasets. Batch processing methods stream records in configurable chunks.

### CHECK 1.3a: Use find_each for large iterations

> **What to look for:** `.all.each`, `.where(...).each`, or `.order(...).each` iterating over unbounded or potentially large result sets without `find_each` or `find_in_batches`
> **Where to look:** `app/models/**/*.rb`, `app/jobs/**/*.rb`, `lib/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
# Loads ALL users into memory at once
User.all.each do |user|
  UserMailer.weekly_digest(user).deliver_later
end

# Large result set loaded entirely
Order.where("created_at < ?", 1.year.ago).each do |order|
  order.archive!
end
```

**SAFE:**

```ruby
# Loads 1000 records at a time
User.find_each do |user|
  UserMailer.weekly_digest(user).deliver_later
end

# Batched with custom size
Order.where("created_at < ?", 1.year.ago).find_each(batch_size: 500) do |order|
  order.archive!
end
```

### CHECK 1.3b: Use find_in_batches for batch operations

> **What to look for:** Collecting large result sets into arrays for bulk operations instead of using `find_in_batches` or `in_batches`
> **Where to look:** `app/jobs/**/*.rb`, `lib/tasks/**/*.rake`, `lib/**/*.rb`
> **Severity:** Medium

**UNSAFE:**

```ruby
# Loads all records, then slices — peak memory holds entire table
Product.where(discontinued: true).to_a.each_slice(100) do |batch|
  ProductIndex.bulk_delete(batch)
end
```

**SAFE:**

```ruby
# Never holds more than 100 records in memory
Product.where(discontinued: true).find_in_batches(batch_size: 100) do |batch|
  ProductIndex.bulk_delete(batch)
end
```

---

## 1.4 Query Placement

Sorting, filtering, and aggregating in Ruby instead of SQL wastes both memory and CPU. The database is optimized for these operations.

### CHECK 1.4a: Sort and filter at the database level

> **What to look for:** Ruby `sort_by`, `select`, `reject`, `min_by`, `max_by`, `group_by` called on ActiveRecord collections that could use SQL `ORDER BY`, `WHERE`, `MIN`, `MAX`, `GROUP BY`
> **Where to look:** `app/models/**/*.rb`, `app/controllers/**/*.rb`
> **Severity:** Medium

**UNSAFE:**

```ruby
# Loads all records then sorts in Ruby
@users = User.all.sort_by(&:created_at).reverse

# Filters in Ruby after loading everything
active_users = User.all.select { |u| u.active? && u.confirmed? }

# Aggregates in Ruby
total = Order.all.sum(&:total_price)
```

**SAFE:**

```ruby
# Database handles sorting
@users = User.order(created_at: :desc)

# Database handles filtering
active_users = User.where(active: true, confirmed: true)

# Database handles aggregation
total = Order.sum(:total_price)
```

### CHECK 1.4b: Avoid Ruby computation on large datasets

> **What to look for:** `map`, `flat_map`, `reduce`, `inject`, `each_with_object` on ActiveRecord relations that could be replaced with SQL operations
> **Where to look:** `app/models/**/*.rb`, `app/controllers/**/*.rb`
> **Severity:** Medium

**UNSAFE:**

```ruby
# Loads all orders into Ruby to extract unique statuses
statuses = Order.all.map(&:status).uniq

# Ruby-side grouping
grouped = Transaction.all.group_by { |t| t.created_at.to_date }
```

**SAFE:**

```ruby
# Single query, returns array of strings
statuses = Order.distinct.pluck(:status)

# Database-side grouping
grouped = Transaction.group("DATE(created_at)").count
```

---

# Part 2: Database Indexing

Missing or poorly designed indexes are the most common cause of slow queries in production. These checks verify that the schema supports the queries the application makes.

## 2.1 Missing Indexes

### CHECK 2.1a: Foreign key columns indexed

> **What to look for:** `belongs_to` associations or `_id` columns in migrations without a corresponding database index
> **Where to look:** `db/migrate/**/*.rb`, `db/schema.rb`
> **Severity:** High

**UNSAFE:**

```ruby
class CreateComments < ActiveRecord::Migration[7.1]
  def change
    create_table :comments do |t|
      t.references :post, foreign_key: true, index: false
      t.integer :user_id  # No index
      t.text :body
      t.timestamps
    end
  end
end
```

**SAFE:**

```ruby
class CreateComments < ActiveRecord::Migration[7.1]
  def change
    create_table :comments do |t|
      t.references :post, foreign_key: true  # index: true is default
      t.references :user, foreign_key: true
      t.text :body
      t.timestamps
    end
  end
end
```

### CHECK 2.1b: Frequently queried columns indexed

> **What to look for:** Columns used in `where`, `order`, `group`, or `find_by` clauses that lack indexes — especially `status`, `type`, `slug`, `email`, and date columns
> **Where to look:** `db/migrate/**/*.rb`, `db/schema.rb`, `app/models/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
# Model uses scopes on status and slug, but no indexes exist
class Article < ApplicationRecord
  scope :published, -> { where(status: "published") }
  scope :by_slug, ->(slug) { find_by!(slug: slug) }
end

# schema.rb shows no index on status or slug
```

**SAFE:**

```ruby
class AddIndexesToArticles < ActiveRecord::Migration[7.1]
  def change
    add_index :articles, :status
    add_index :articles, :slug, unique: true
  end
end
```

### CHECK 2.1c: Composite indexes for multi-column queries

> **What to look for:** Queries with multiple `WHERE` conditions or `WHERE` + `ORDER BY` that use separate single-column indexes instead of a composite index
> **Where to look:** `db/migrate/**/*.rb`, `db/schema.rb`, `app/models/**/*.rb`
> **Severity:** Medium

**UNSAFE:**

```ruby
# Frequent query pattern
Order.where(user_id: user.id, status: "pending").order(:created_at)

# Only single-column indexes exist
add_index :orders, :user_id
add_index :orders, :status
```

**SAFE:**

```ruby
# Composite index matches the query pattern
add_index :orders, [:user_id, :status, :created_at]
```

---

## 2.2 Index Anti-Patterns

### CHECK 2.2a: Concurrent index creation in production

> **What to look for:** `add_index` in migrations without `algorithm: :concurrently` for large production tables; missing `disable_ddl_transaction!`
> **Where to look:** `db/migrate/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
class AddIndexToOrdersStatus < ActiveRecord::Migration[7.1]
  def change
    # Locks the entire orders table during index creation
    add_index :orders, :status
  end
end
```

**SAFE:**

```ruby
class AddIndexToOrdersStatus < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :orders, :status, algorithm: :concurrently
  end
end
```

### CHECK 2.2b: Partial indexes for scoped queries

> **What to look for:** Full-table indexes on columns where queries always include a filtering condition (e.g., only active records, only non-null values)
> **Where to look:** `db/migrate/**/*.rb`, `app/models/**/*.rb`
> **Severity:** Low

**UNSAFE:**

```ruby
# Full index when queries always filter for active
add_index :users, :email

# But the query is always:
User.where(active: true).find_by(email: email)
```

**SAFE:**

```ruby
# Partial index — smaller, faster, only covers active users
add_index :users, :email, where: "active = true", unique: true
```

---

# Part 3: Caching

Caching reduces redundant computation and database queries. These checks verify that caching is properly configured and applied where it matters most.

## 3.1 Cache Store Configuration

### CHECK 3.1a: Production cache store is not file or memory

> **What to look for:** `config.cache_store` set to `:file_store` or `:memory_store` in production; missing cache store configuration for production
> **Where to look:** `config/environments/production.rb`
> **Severity:** High

**UNSAFE:**

```ruby
# config/environments/production.rb
config.cache_store = :file_store, "/tmp/cache"

# Or worse — default memory store in production
# (no config.cache_store set at all)
```

**SAFE:**

```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, {
  url: ENV.fetch("REDIS_URL"),
  expires_in: 1.hour
}

# Or Memcached:
config.cache_store = :mem_cache_store, ENV.fetch("MEMCACHED_URL")

# Or Rails 8+ Solid Cache:
config.cache_store = :solid_cache_store
```

---

## 3.2 Fragment & Collection Caching

### CHECK 3.2a: Cache expensive view partials

> **What to look for:** Partials that execute queries or expensive computations rendered without `cache` blocks; missing cache keys on frequently rendered partials
> **Where to look:** `app/views/**/*.erb`
> **Severity:** Medium

**UNSAFE:**

```erb
<%# Rendered on every request, executes queries each time %>
<%= render partial: "dashboard/stats" %>
```

**SAFE:**

```erb
<% cache("dashboard/stats", expires_in: 5.minutes) do %>
  <%= render partial: "dashboard/stats" %>
<% end %>

<%# Or with record-based cache key: %>
<% cache(@project) do %>
  <%= render partial: "projects/detail", locals: { project: @project } %>
<% end %>
```

### CHECK 3.2b: Collection rendering with caching

> **What to look for:** `render collection:` without the `cached: true` option on collections that don't change frequently
> **Where to look:** `app/views/**/*.erb`
> **Severity:** Medium

**UNSAFE:**

```erb
<%# Renders each partial individually, no caching %>
<%= render partial: "products/product", collection: @products %>
```

**SAFE:**

```erb
<%# Multi-fetch caching — reads all cache keys in one round-trip %>
<%= render partial: "products/product", collection: @products, cached: true %>
```

---

## 3.3 Application-Level Caching

### CHECK 3.3a: Cache expensive computations

> **What to look for:** Repeated expensive computations (API calls, complex aggregations, report generation) without `Rails.cache.fetch`
> **Where to look:** `app/models/**/*.rb`, `app/controllers/**/*.rb`, `lib/**/*.rb`
> **Severity:** Medium

**UNSAFE:**

```ruby
class Dashboard
  def stats
    # Runs complex aggregation on every call
    {
      total_revenue: Order.where(status: "completed").sum(:total),
      active_users: User.where("last_sign_in_at > ?", 30.days.ago).count,
      conversion_rate: calculate_conversion_rate
    }
  end
end
```

**SAFE:**

```ruby
class Dashboard
  def stats
    Rails.cache.fetch("dashboard/stats", expires_in: 15.minutes) do
      {
        total_revenue: Order.where(status: "completed").sum(:total),
        active_users: User.where("last_sign_in_at > ?", 30.days.ago).count,
        conversion_rate: calculate_conversion_rate
      }
    end
  end
end
```

### CHECK 3.3b: Memoization for per-request computation

> **What to look for:** Methods called multiple times per request that perform database queries or computations without memoization
> **Where to look:** `app/models/**/*.rb`, `app/controllers/**/*.rb`, `app/helpers/**/*.rb`
> **Severity:** Low

**UNSAFE:**

```ruby
class User < ApplicationRecord
  def active_subscription
    # Queries the database every time this is called
    subscriptions.where(active: true).order(created_at: :desc).first
  end
end
```

**SAFE:**

```ruby
class User < ApplicationRecord
  def active_subscription
    @active_subscription ||= subscriptions.where(active: true).order(created_at: :desc).first
  end
end
```

---

# Part 4: Memory & Resource Management

These checks prevent excessive memory usage, ensure expensive operations run in the background, and reduce unnecessary object allocation.

## 4.1 Memory-Intensive Operations

### CHECK 4.1a: Avoid loading full result sets for partial data

> **What to look for:** Loading full ActiveRecord objects when only specific columns are needed; `.all` or `.where(...)` followed by `.map` to extract attributes
> **Where to look:** `app/models/**/*.rb`, `app/controllers/**/*.rb`, `app/jobs/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
# Loads full User objects (all columns) just to get names
names = User.where(role: "admin").map(&:name)

# Loads all orders into memory to sum a column
total = Order.where(user_id: user.id).map(&:total_price).sum
```

**SAFE:**

```ruby
# Returns plain array of strings — no ActiveRecord objects
names = User.where(role: "admin").pluck(:name)

# Single SQL SUM — no records loaded
total = Order.where(user_id: user.id).sum(:total_price)
```

### CHECK 4.1b: Stream large file exports

> **What to look for:** CSV or file exports that build the entire file in memory before sending; `CSV.generate` on unbounded datasets
> **Where to look:** `app/controllers/**/*.rb`, `lib/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
def export
  csv = CSV.generate do |csv|
    csv << ["Name", "Email", "Created"]
    User.all.each do |user|
      csv << [user.name, user.email, user.created_at]
    end
  end
  send_data csv, filename: "users.csv"
end
```

**SAFE:**

```ruby
def export
  headers["Content-Disposition"] = 'attachment; filename="users.csv"'
  headers["Content-Type"] = "text/csv"

  response.status = 200
  self.response_body = Enumerator.new do |yielder|
    yielder << CSV.generate_line(["Name", "Email", "Created"])
    User.find_each do |user|
      yielder << CSV.generate_line([user.name, user.email, user.created_at])
    end
  end
end
```

---

## 4.2 Background Job Offloading

### CHECK 4.2a: Expensive work not in request cycle

> **What to look for:** Email delivery, PDF generation, API calls to external services, image processing, or report generation executed synchronously in controller actions
> **Where to look:** `app/controllers/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
class OrdersController < ApplicationController
  def create
    @order = Order.create!(order_params)
    OrderMailer.confirmation(@order).deliver_now      # Blocks response
    PdfGenerator.generate_invoice(@order)             # Blocks response
    InventoryApi.reserve_items(@order.line_items)     # Blocks response
    redirect_to @order
  end
end
```

**SAFE:**

```ruby
class OrdersController < ApplicationController
  def create
    @order = Order.create!(order_params)
    OrderMailer.confirmation(@order).deliver_later         # Background job
    GenerateInvoiceJob.perform_later(@order)               # Background job
    ReserveInventoryJob.perform_later(@order.line_items)   # Background job
    redirect_to @order
  end
end
```

### CHECK 4.2b: Use deliver_later for emails

> **What to look for:** `deliver_now` in controller actions or model callbacks; synchronous email delivery in the request cycle
> **Where to look:** `app/controllers/**/*.rb`, `app/models/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
UserMailer.welcome(user).deliver_now
NotificationMailer.alert(admin).deliver_now
```

**SAFE:**

```ruby
UserMailer.welcome(user).deliver_later
NotificationMailer.alert(admin).deliver_later
```

---

## 4.3 Unnecessary Object Allocation

### CHECK 4.3a: Freeze string literals used as constants

> **What to look for:** String literals assigned to constants or used repeatedly without freezing; missing `# frozen_string_literal: true` pragma
> **Where to look:** `app/**/*.rb`, `lib/**/*.rb`
> **Severity:** Low

**UNSAFE:**

```ruby
class PaymentProcessor
  DEFAULT_CURRENCY = "usd"           # Allocates a new string every access
  SUPPORTED_TYPES = ["card", "bank"] # Allocates new array and strings

  def process(amount)
    currency = "usd"  # New string object every call
    # ...
  end
end
```

**SAFE:**

```ruby
# frozen_string_literal: true

class PaymentProcessor
  DEFAULT_CURRENCY = "usd"
  SUPPORTED_TYPES = %w[card bank].freeze

  def process(amount)
    # String literals are frozen by the pragma
    # ...
  end
end
```

### CHECK 4.3b: Avoid repeated allocations in loops

> **What to look for:** Object creation (strings, arrays, hashes, regex) inside loops where the object could be extracted to a constant or local variable
> **Where to look:** `app/**/*.rb`, `lib/**/*.rb`
> **Severity:** Low

**UNSAFE:**

```ruby
users.each do |user|
  if user.name.match?(/\A[A-Z]/)       # Regex compiled every iteration
    tags = user.bio.split(",").map(&:strip)
    formatted = "User: #{user.name}"    # Fine with frozen_string_literal
  end
end
```

**SAFE:**

```ruby
STARTS_WITH_CAPITAL = /\A[A-Z]/

users.each do |user|
  if user.name.match?(STARTS_WITH_CAPITAL)
    tags = user.bio.split(",").map(&:strip)
    formatted = "User: #{user.name}"
  end
end
```

---

# Part 5: View & Response Performance

These checks cover efficient rendering of collections and frontend asset delivery.

## 5.1 Collection Rendering

### CHECK 5.1a: Use render collection instead of loops

> **What to look for:** Manual `each` loops in views rendering the same partial repeatedly instead of `render collection:`
> **Where to look:** `app/views/**/*.erb`
> **Severity:** Medium

**UNSAFE:**

```erb
<% @products.each do |product| %>
  <%= render partial: "products/product", locals: { product: product } %>
<% end %>
```

**SAFE:**

```erb
<%= render partial: "products/product", collection: @products, as: :product %>

<%# Or shorthand: %>
<%= render @products %>
```

### CHECK 5.1b: Efficient JSON serialization

> **What to look for:** Calling `.to_json` on full ActiveRecord objects or collections; rendering JSON without selecting specific attributes
> **Where to look:** `app/controllers/**/*.rb`, `app/controllers/api/**/*.rb`
> **Severity:** Medium

**UNSAFE:**

```ruby
def index
  @users = User.all
  render json: @users.to_json
end
```

**SAFE:**

```ruby
def index
  @users = User.select(:id, :name, :email)
  render json: @users.as_json(only: [:id, :name, :email])
end

# Or with jbuilder for complex responses:
# app/views/api/users/index.json.jbuilder
```

---

## 5.2 Asset & Frontend Performance

### CHECK 5.2a: Pagination for large collections

> **What to look for:** Controller actions that load unbounded collections for display in views; missing pagination on index actions
> **Where to look:** `app/controllers/**/*.rb`
> **Severity:** High

**UNSAFE:**

```ruby
def index
  @orders = Order.all
end
```

**SAFE:**

```ruby
def index
  @orders = Order.order(created_at: :desc).page(params[:page]).per(25)
end

# Or with cursor-based pagination:
def index
  @orders = Order.where("id < ?", params[:cursor] || Float::INFINITY)
                 .order(id: :desc)
                 .limit(25)
end
```

### CHECK 5.2b: Turbo Frame lazy loading for heavy sections

> **What to look for:** Page sections that load expensive data on every full page load when they could be deferred with Turbo Frames
> **Where to look:** `app/views/**/*.erb`
> **Severity:** Low

**UNSAFE:**

```erb
<%# Stats section loads on every page visit, even if user doesn't scroll to it %>
<div id="stats">
  <%= render "dashboard/heavy_stats" %>
</div>
```

**SAFE:**

```erb
<%# Loaded lazily only when the frame enters the viewport %>
<%= turbo_frame_tag "stats", src: dashboard_stats_path, loading: :lazy do %>
  <p>Loading stats...</p>
<% end %>
```

---

# Part 6: Deployment & Configuration

These checks verify that production environments are tuned for performance.

## 6.1 Server Tuning

### CHECK 6.1a: Puma threads and workers configured

> **What to look for:** Default Puma configuration in production; missing or improperly sized `threads` and `workers` settings
> **Where to look:** `config/puma.rb`
> **Severity:** High

**UNSAFE:**

```ruby
# config/puma.rb — defaults, not tuned for production
threads_count = 5
threads threads_count, threads_count
```

**SAFE:**

```ruby
# config/puma.rb
max_threads = ENV.fetch("RAILS_MAX_THREADS", 5).to_i
min_threads = ENV.fetch("RAILS_MIN_THREADS", max_threads).to_i
threads min_threads, max_threads

workers ENV.fetch("WEB_CONCURRENCY", 2).to_i
preload_app!
```

### CHECK 6.1b: YJIT enabled in production

> **What to look for:** Ruby 3.2+ applications not enabling YJIT; missing `RUBY_YJIT_ENABLE` or `--yjit` flag
> **Where to look:** `config/puma.rb`, `Dockerfile`, `.ruby-version`
> **Severity:** Medium

**UNSAFE:**

```dockerfile
# Dockerfile — YJIT not enabled
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

**SAFE:**

```dockerfile
# Dockerfile — YJIT enabled via environment variable
ENV RUBY_YJIT_ENABLE=1
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

```ruby
# Or in config/puma.rb:
if defined?(RubyVM::YJIT) && RubyVM::YJIT.respond_to?(:enable)
  RubyVM::YJIT.enable
end
```

---

## 6.2 Production Settings

### CHECK 6.2a: Cache classes and eager load enabled

> **What to look for:** `config.cache_classes = false` or `config.eager_load = false` in production environment
> **Where to look:** `config/environments/production.rb`
> **Severity:** High

**UNSAFE:**

```ruby
# config/environments/production.rb
config.cache_classes = false     # Reloads code on every request
config.eager_load = false        # Lazy loads, causing slow first requests
```

**SAFE:**

```ruby
# config/environments/production.rb
config.cache_classes = true
config.eager_load = true
```

### CHECK 6.2b: Asset compression and digests enabled

> **What to look for:** Missing asset compression or digest fingerprinting in production; uncompressed CSS and JavaScript
> **Where to look:** `config/environments/production.rb`
> **Severity:** Medium

**UNSAFE:**

```ruby
# config/environments/production.rb
config.assets.compile = true     # On-the-fly compilation in production
config.assets.digest = false     # No cache-busting fingerprints
```

**SAFE:**

```ruby
# config/environments/production.rb
config.assets.compile = false
config.assets.digest = true
config.assets.css_compressor = :sass
```

---

# Part 7: Performance Verification Checklist

## 7.1 Agent Check Protocol

When verifying performance after a development phase, follow this protocol to map changed files to relevant checks.

### Step 1: Identify changed files

```bash
git diff --name-only HEAD~1
# Or for a phase: git diff <phase-start-sha>..HEAD --name-only
```

### Step 2: Map files to check sections

| Changed file pattern | Applicable sections |
|---|---|
| `app/models/**/*.rb` | 1.1 (N+1), 1.2 (inefficient queries), 1.4 (query placement), 3.3 (caching), 4.1 (memory) |
| `app/controllers/**/*.rb` | 1.1a (eager loading), 1.2b (exists?), 4.2 (background jobs), 5.1b (JSON), 5.2a (pagination) |
| `app/views/**/*.erb` | 1.1a (N+1 in views), 1.1c (counter cache), 3.2 (fragment caching), 5.1a (collection rendering), 5.2b (lazy loading) |
| `app/jobs/**/*.rb` | 1.3 (batch processing), 4.1 (memory) |
| `db/migrate/**/*.rb` | 2.1 (missing indexes), 2.2 (index anti-patterns) |
| `db/schema.rb` | 2.1 (missing indexes) |
| `config/puma.rb` | 6.1 (server tuning) |
| `config/environments/production.rb` | 3.1 (cache store), 6.2 (production settings) |
| `lib/**/*.rb` | 1.3 (batch processing), 4.1 (memory), 4.3 (object allocation) |
| `Dockerfile` | 6.1b (YJIT) |

### Step 3: Run applicable checks

For each applicable section, scan the changed files using the "Where to look" glob pattern and "What to look for" pattern. Report findings as:

```
PASS: CHECK 1.1a — Eager load associations (scanned 3 files)
FAIL: CHECK 1.3a — User.all.each in app/jobs/digest_job.rb:12
SKIP: CHECK 2.1a — No migration changes in this phase
```

---

## 7.2 Quick-Reference Checklist

All checks from Parts 1-6 in a single table for quick scanning.

| Check | Name | Severity | Grep pattern | Files |
|---|---|---|---|---|
| 1.1a | Eager load associations in loops | High | `\.includes\|\.eager_load\|\.preload` | `app/controllers/**/*.rb` |
| 1.1b | Nested association eager loading | High | `\.includes\(.*:` | `app/controllers/**/*.rb` |
| 1.1c | Counter cache for counts | Medium | `\.count\b` in loops | `app/views/**/*.erb` |
| 1.2a | Select only needed columns | Medium | `\.map\(&:` after query | `app/models/**/*.rb` |
| 1.2b | exists? instead of present? | Medium | `\.present?\|\.any?\|\.count > 0` | `app/**/*.rb` |
| 1.2c | Avoid load-to-count | Medium | `\.length` on relation | `app/**/*.rb` |
| 1.3a | find_each for large iterations | High | `\.all\.each\|\.where.*\.each` | `app/jobs/**/*.rb`, `lib/**/*.rb` |
| 1.3b | find_in_batches for bulk ops | Medium | `\.to_a\.each_slice` | `app/jobs/**/*.rb`, `lib/**/*.rb` |
| 1.4a | Sort/filter at database level | Medium | `\.sort_by\|\.select \{` on AR | `app/models/**/*.rb` |
| 1.4b | Avoid Ruby compute on large sets | Medium | `\.all\.map\|\.all\.reduce` | `app/models/**/*.rb` |
| 2.1a | Foreign key columns indexed | High | `t\.integer.*_id` without index | `db/migrate/**/*.rb` |
| 2.1b | Frequently queried columns indexed | High | `add_column` without `add_index` | `db/migrate/**/*.rb` |
| 2.1c | Composite indexes for multi-column | Medium | `\.where.*\.where\|\.where.*\.order` | `app/models/**/*.rb` |
| 2.2a | Concurrent index in production | High | `add_index` without `concurrently` | `db/migrate/**/*.rb` |
| 2.2b | Partial indexes for scoped queries | Low | `add_index.*where:` | `db/migrate/**/*.rb` |
| 3.1a | Production cache store | High | `cache_store.*:file_store\|:memory_store` | `config/environments/production.rb` |
| 3.2a | Cache expensive view partials | Medium | `render partial:` without `cache` | `app/views/**/*.erb` |
| 3.2b | Collection caching | Medium | `render.*collection:` without `cached` | `app/views/**/*.erb` |
| 3.3a | Cache expensive computations | Medium | `Rails\.cache\.fetch` | `app/models/**/*.rb`, `lib/**/*.rb` |
| 3.3b | Memoization for per-request | Low | `@.*\|\|=` | `app/models/**/*.rb` |
| 4.1a | Avoid full loads for partial data | High | `\.map\(&:` after `.where` | `app/models/**/*.rb`, `app/jobs/**/*.rb` |
| 4.1b | Stream large file exports | High | `CSV\.generate.*\.all` | `app/controllers/**/*.rb` |
| 4.2a | Expensive work in background | High | `deliver_now\|\.generate.*\.render` | `app/controllers/**/*.rb` |
| 4.2b | deliver_later for emails | High | `deliver_now` | `app/controllers/**/*.rb` |
| 4.3a | Freeze string literals | Low | `frozen_string_literal` | `app/**/*.rb` |
| 4.3b | No repeated allocs in loops | Low | `Regexp\.new\|/.*/ inside \.each` | `app/**/*.rb`, `lib/**/*.rb` |
| 5.1a | render collection vs loops | Medium | `\.each.*render partial:` | `app/views/**/*.erb` |
| 5.1b | Efficient JSON serialization | Medium | `\.to_json` on AR objects | `app/controllers/**/*.rb` |
| 5.2a | Pagination for large collections | High | `\.all` without `.page\|.limit` | `app/controllers/**/*.rb` |
| 5.2b | Turbo Frame lazy loading | Low | `turbo_frame_tag.*loading: :lazy` | `app/views/**/*.erb` |
| 6.1a | Puma threads/workers configured | High | `workers\|threads` | `config/puma.rb` |
| 6.1b | YJIT enabled | Medium | `RUBY_YJIT_ENABLE\|yjit` | `Dockerfile`, `config/puma.rb` |
| 6.2a | cache_classes and eager_load | High | `cache_classes.*false\|eager_load.*false` | `config/environments/production.rb` |
| 6.2b | Asset compression and digests | Medium | `assets\.compile.*true\|assets\.digest.*false` | `config/environments/production.rb` |

---

**Document Version**: 1.0
**Last Updated**: 2026-02-15
**Maintainer**: Development Team
