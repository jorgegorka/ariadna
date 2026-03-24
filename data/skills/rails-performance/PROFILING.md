# Profiling & Benchmarking

Measure first, optimize second. Profile in the production Ruby version with production-sized data.

---

## Finding N+1 Queries in Development

```ruby
# Gemfile
gem "bullet", group: :development

# config/environments/development.rb
config.after_initialize do
  Bullet.enable       = true
  Bullet.rails_logger = true
  Bullet.add_footer   = true
end
```

Check `log/bullet.log` after exercising a feature. Bullet reports N+1 alerts and unused eager loads.

Enable query log tags to trace queries to their source in staging:

```ruby
# config/application.rb
config.active_record.query_log_tags_enabled = true
config.active_record.query_log_tags = [:controller, :action]
```

---

## Benchmarking with `benchmark-ips`

Compare two implementations before choosing one:

```ruby
require "benchmark/ips"

Benchmark.ips do |x|
  x.warmup = 2
  x.time   = 5
  x.report("pluck") { User.where(active: true).pluck(:email) }
  x.report("map")   { User.where(active: true).map(&:email) }
  x.compare!
end
```

Always call `.compare!`. Always warm up. Test with representative data volume.

---

## Rack Mini Profiler

```ruby
# Gemfile — development and staging only
gem "rack-mini-profiler"
gem "stackprof"         # CPU flamegraphs
gem "memory_profiler"   # allocation profiling
```

Append `?pp=flamegraph` for CPU flamegraph. Use `?pp=profile-memory` for allocations.

---

## Query Analysis with EXPLAIN

```ruby
# rails console
puts Order.where(user_id: 1, status: "pending").order(:created_at).explain

# PostgreSQL — actual execution stats
ActiveRecord::Base.connection.execute(
  "EXPLAIN (ANALYZE, BUFFERS) #{Order.where(user_id: 1).to_sql}"
).each { |r| puts r["QUERY PLAN"] }
```

Warning signs: `Seq Scan` on large tables (missing index), `rows=` estimate vs actual mismatch (run `ANALYZE`), `Sort` without an index.

---

## Memory Profiling

```ruby
require "memory_profiler"

report = MemoryProfiler.report { User.where(active: true).map(&:email) }
report.pretty_print(to_file: "/tmp/mem.txt")
# Review: allocated_memory_by_gem, allocated_objects_by_location
```

Allocation reduction checklist:
- `# frozen_string_literal: true` on every file
- Extract regex to constants outside loops
- `pluck` instead of AR objects when only scalars are needed
- `User.select(:id, :email).find_each` to limit columns in batch jobs

---

## Review Thresholds

| Scenario | Target |
|---|---|
| Index page (dev, seeded data) | < 10 queries, < 50ms DB time |
| Show page | < 5 queries, < 20ms DB time |
| Batch job over 10k records | Uses `find_each`, < 256MB peak RSS |
