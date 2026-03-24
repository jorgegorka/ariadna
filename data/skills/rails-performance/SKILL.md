---
name: rails-performance
description: Ruby on Rails performance conventions — N+1 prevention, caching, database tuning, benchmarking. Use when optimizing queries, adding caching, or profiling performance.
---

# Rails Performance Skill

Opinionated conventions for Rails performance. Every pattern has a clear unsafe anti-pattern and safe fix.

**Sub-files:**
- [PROFILING.md](PROFILING.md) — Profiling, benchmarking, and measurement workflows

---

## N+1 Query Prevention

Always eager load associations accessed in loops:

```ruby
@posts = Post.includes(:author)                        # single association
@post  = Post.includes(comments: :author).find(id)    # nested
```

Counter caches instead of `.count` in loops:

```ruby
# Model: belongs_to :board, counter_cache: true
# Migration: add_column :boards, :cards_count, :integer, default: 0, null: false
board.cards_count   # reads column — no query
board.cards.count   # fires COUNT — N+1 in loops
```

---

## Efficient Queries

```ruby
# pluck returns plain arrays — no AR objects allocated
emails = User.where(active: true).pluck(:email)
ids    = Order.where(status: "pending").ids

# exists? → SELECT 1 LIMIT 1 (not .present?, .any?, .count > 0)
user.orders.where(status: "pending").exists?

# SQL aggregation — never load records to compute in Ruby
User.order(created_at: :desc)           # NOT .all.sort_by(&:created_at).reverse
Order.distinct.pluck(:status)           # NOT .all.map(&:status).uniq
Order.sum(:total_price)                 # NOT .all.sum(&:total_price)
Product.group(:category_id).count       # preload all counts in one query
```

**Batch processing for large result sets:**

```ruby
User.find_each { |u| process(u) }                              # 1000 at a time
Order.where("created_at < ?", 1.year.ago).find_each(&:archive!)
Product.where(discontinued: true).find_in_batches(batch_size: 100) do |batch|
  Index.bulk_delete(batch)
end
```

---

## Database Indexing

Index every FK column and every column used in `where`, `order`, `find_by`:

```ruby
# t.references adds index by default
create_table :comments do |t|
  t.references :post, foreign_key: true
  t.references :user, foreign_key: true
end

add_index :articles, :status
add_index :articles, :slug, unique: true
add_index :users,    :email, where: "active = true", unique: true   # partial

# Composite for multi-column queries
add_index :orders, [:user_id, :status, :created_at]
```

Concurrent index creation on live tables:

```ruby
class AddIndexToOrdersStatus < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!
  def change
    add_index :orders, :status, algorithm: :concurrently
  end
end
```

---

## Caching

**Production cache store — Redis, Memcached, or Solid Cache. Never `:file_store` or `:memory_store`:**

```ruby
# config/environments/production.rb
config.cache_store = :redis_cache_store, { url: ENV.fetch("REDIS_URL"), expires_in: 1.hour }
```

**Fragment caching with auto cache-busting via `cache_key_with_version`:**

```erb
<% cache(@project) do %>
  <%= render "projects/detail", project: @project %>
<% end %>

<%# Collection multi-fetch — one Redis round-trip %>
<%= render partial: "products/product", collection: @products, cached: true %>
```

**Application-level caching and per-request memoization:**

```ruby
def stats
  Rails.cache.fetch("dashboard/stats", expires_in: 15.minutes) do
    { revenue: Order.sum(:total), active: User.where("last_sign_in_at > ?", 30.days.ago).count }
  end
end

def active_subscription
  @active_subscription ||= subscriptions.where(active: true).order(created_at: :desc).first
end
```

---

## Memory Management

Stream large exports — never build in memory:

```ruby
def export
  headers["Content-Disposition"] = 'attachment; filename="users.csv"'
  headers["Content-Type"] = "text/csv"
  response.status = 200
  self.response_body = Enumerator.new do |y|
    y << CSV.generate_line(["Name", "Email"])
    User.find_each { |u| y << CSV.generate_line([u.name, u.email]) }
  end
end
```

Always use `deliver_later` and background jobs for slow work:

```ruby
OrderMailer.confirmation(@order).deliver_later    # NOT deliver_now
GenerateInvoiceJob.perform_later(@order)          # NOT inline PDF generation
```

Freeze string literals; extract regex constants out of loops:

```ruby
# frozen_string_literal: true
CAPITAL = /\A[A-Z]/
users.each { |u| u.name.match?(CAPITAL) }
```

---

## View & Response

```erb
<%# Single render call with collection caching %>
<%= render partial: "products/product", collection: @products, cached: true %>

<%# Lazy-load expensive sections %>
<%= turbo_frame_tag "stats", src: dashboard_stats_path, loading: :lazy do %>
  <p>Loading...</p>
<% end %>
```

Always paginate index actions:

```ruby
def index
  @orders = Order.order(created_at: :desc).page(params[:page]).per(25)
end
```

---

## Production Configuration

```ruby
# config/puma.rb
threads ENV.fetch("RAILS_MIN_THREADS", 5).to_i, ENV.fetch("RAILS_MAX_THREADS", 5).to_i
workers ENV.fetch("WEB_CONCURRENCY", 2).to_i
preload_app!
RubyVM::YJIT.enable if defined?(RubyVM::YJIT) && RubyVM::YJIT.respond_to?(:enable)

# config/environments/production.rb
config.cache_classes = true
config.eager_load    = true
config.assets.compile = false
config.assets.digest  = true
```

---

## Check-to-File Mapping

| Changed files | Priority checks |
|---|---|
| `app/controllers/**/*.rb` | N+1 includes, `exists?`, pagination, `deliver_later` |
| `app/models/**/*.rb` | `pluck` vs `map`, SQL aggregation, memoization |
| `app/views/**/*.erb` | Fragment caching, `render collection:`, lazy frames |
| `app/jobs/**/*.rb` | `find_each`, `find_in_batches`, memory |
| `db/migrate/**/*.rb` | FK indexes, concurrent index, composite indexes |
| `config/environments/production.rb` | Cache store, `eager_load`, assets |
| `config/puma.rb` | Threads/workers, YJIT |

See [PROFILING.md](PROFILING.md) for measurement, benchmarking, and query analysis.
