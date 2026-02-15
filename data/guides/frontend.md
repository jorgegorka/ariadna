# Frontend Patterns

**View Layer Conventions for Rails Applications**

This guide covers the frontend and view layer patterns used in Rails applications. Currently focused on the Presenter Pattern, with future sections planned for Turbo, Stimulus, and view templates.

**Related guides:**
- [Backend Patterns](backend.md) — Architecture, models, controllers, jobs, style guide
- [Testing Patterns](testing.md) — Testing philosophy, model/controller/job test patterns
- [Security Guide](security.md) — Agent-oriented security checklist for code review
- See `data/guides/style-guide.md` for CSS architecture and design tokens

## Table of Contents

- [1. Presenter Pattern](#1-presenter-pattern)
  - [1.1 Philosophy](#11-philosophy)
  - [1.2 When to Create a Presenter](#12-when-to-create-a-presenter)
  - [1.3 Anatomy of a Presenter](#13-anatomy-of-a-presenter)
  - [1.4 Generating HTML in Presenters](#14-generating-html-in-presenters)
  - [1.5 Nested Presenters](#15-nested-presenters)
  - [1.6 Instantiation Patterns](#16-instantiation-patterns)
  - [1.7 View Usage](#17-view-usage)
  - [1.8 Testing Presenters](#18-testing-presenters)
  - [1.9 Real Examples](#19-real-examples)
- [2. Turbo Streams & Turbo Frames](#2-turbo-streams--turbo-frames) *(planned)*
- [3. Stimulus Controllers](#3-stimulus-controllers) *(planned)*
- [4. View Templates & Partials](#4-view-templates--partials) *(planned)*

---

# 1. Presenter Pattern

It uses presenter classes to encapsulate complex view logic. Unlike typical Rails apps, presenters don't live in an `app/presenters/` directory—they live in `app/models/` organized by domain, aligning with "vanilla Rails" philosophy.

## 1.1 Philosophy

Presenters are plain Ruby classes that:
- Package data and display logic for views
- Transform domain objects into view-ready formats
- Encapsulate conditional display logic
- Provide cache keys for fragment caching

**Why models layer?** Presenters are domain objects that know about business rules. They fit naturally alongside concerns like `User::Filtering` and `Event::Description`. No separate presenter infrastructure is needed.

## 1.2 When to Create a Presenter

**Create a presenter when:**
- A view needs complex conditional logic (3+ conditions)
- Multiple related values need to be computed together
- You need to transform data into HTML or formatted text
- The same display logic is needed in multiple views
- You want to cache complex view fragments

**Don't create a presenter when:**
- Simple delegation would suffice (use helpers)
- You only need one or two computed values
- The logic is purely formatting (use view helpers)

## 1.3 Anatomy of a Presenter

**File**: `app/models/user/filtering.rb`

```ruby
class User::Filtering
  attr_reader :user, :filter, :expanded

  delegate :as_params, :single_board, to: :filter
  delegate :only_closed?, to: :filter

  def initialize(user, filter, expanded: false)
    @user, @filter, @expanded = user, filter, expanded
  end

  # Memoized collections (lazy-loaded)
  def boards
    @boards ||= user.boards.ordered_by_recently_accessed
  end

  def tags
    @tags ||= account.tags.all.alphabetically
  end

  def users
    @users ||= account.users.active.alphabetically
  end

  # Boolean methods for conditional display
  def expanded?
    @expanded
  end

  def any?
    filter.used?(ignore_boards: true)
  end

  def show_tags?
    return unless Tag.any?
    filter.tags.any?
  end

  def show_assignees?
    filter.assignees.any?
  end

  # Cache key for fragment caching
  def cache_key
    ActiveSupport::Cache.expand_cache_key(
      [ user, filter, expanded?, boards, tags, users, filters ],
      "user-filtering"
    )
  end

  private
    def account
      user.account
    end
end
```

**Pattern breakdown:**

1. **Plain Ruby class** - No framework, no gem, no inheritance
2. **Explicit dependencies** - All inputs via constructor
3. **Memoization** - `@var ||=` for lazy-loaded collections
4. **Boolean methods** - `show_tags?`, `expanded?` for conditional display
5. **Cache key** - Composite key for fragment caching
6. **Private helpers** - Keep the interface clean

## 1.4 Generating HTML in Presenters

When presenters need to generate HTML, include ActionView helpers:

**File**: `app/models/event/description.rb`

```ruby
class Event::Description
  include ActionView::Helpers::TagHelper  # ← For tag.span, etc.
  include ERB::Util                       # ← For h() escaping

  attr_reader :event, :user

  def initialize(event, user)
    @event = event
    @user = user
  end

  def to_html
    to_sentence(creator_tag, card_title_tag).html_safe
  end

  def to_plain_text
    to_sentence(creator_name, quoted(card.title))
  end

  private
    def creator_tag
      tag.span data: { creator_id: event.creator.id } do
        tag.span("You", data: { only_visible_to_you: true }) +
        tag.span(event.creator.name, data: { only_visible_to_others: true })
      end
    end

    def card_title_tag
      tag.span card.title, class: "txt-underline"
    end

    # ... action-specific sentence methods ...
end
```

**Key patterns:**
- `to_html` / `to_plain_text` for multiple output formats
- Include only the helpers you need
- Use `h()` for escaping user content
- Keep HTML generation in private methods

## 1.5 Nested Presenters

Presenters can create other presenters for sub-components:

**File**: `app/models/user/day_timeline.rb`

```ruby
class User::DayTimeline
  def added_column
    @added_column ||= build_column(:added, "Added", 1,
      events.where(action: %w[card_published card_reopened]))
  end

  def updated_column
    @updated_column ||= build_column(:updated, "Updated", 2,
      events.where.not(action: %w[card_published card_closed card_reopened]))
  end

  def closed_column
    @closed_column ||= build_column(:closed, "Done", 3,
      events.where(action: "card_closed"))
  end

  private
    def build_column(id, base_title, index, events)
      Column.new(self, id, base_title, index, events)  # ← Nested presenter
    end
end
```

**File**: `app/models/user/day_timeline/column.rb`

```ruby
class User::DayTimeline::Column
  include ActionView::Helpers::TagHelper, ActionView::Helpers::OutputSafetyHelper

  def title
    date_tag = local_datetime_tag(day_timeline.day, style: :agoorweekday)
    parts = [ base_title, date_tag ]
    parts << tag.span("(#{full_events_count})", class: "font-weight-normal") if full_events_count > 0
    safe_join(parts, " ")
  end

  def events_by_hour
    limited_events.group_by { it.created_at.hour }
  end

  def has_more_events?
    limited_events.count < full_events_count
  end
end
```

## 1.6 Instantiation Patterns

### Pattern 1: Controller Concerns

For presenters used across multiple controllers, create a concern:

**File**: `app/controllers/concerns/filter_scoped.rb`

```ruby
module FilterScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_filter
    before_action :set_user_filtering
  end

  private
    def set_filter
      if params[:filter_id].present?
        @filter = Current.user.filters.find(params[:filter_id])
      else
        @filter = Current.user.filters.from_params filter_params
      end
    end

    def set_user_filtering
      @user_filtering = User::Filtering.new(Current.user, @filter, expanded: expanded_param)
    end
end
```

**Usage in controllers:**

```ruby
class CardsController < ApplicationController
  include FilterScoped  # ← Sets @user_filtering automatically

  def index
    # @user_filtering is available
  end
end
```

### Pattern 2: Factory Methods on Models

For presenters tied to a specific model, add a factory method:

**File**: `app/models/event.rb`

```ruby
class Event < ApplicationRecord
  def description_for(user)
    Event::Description.new(self, user)
  end
end
```

**Usage in views:**

```erb
<%= event.description_for(Current.user).to_html %>
```

This keeps the API discoverable and maintains the object-oriented style.

## 1.7 View Usage

**With controller-instantiated presenter:**

```erb
<%# @user_filtering set by FilterScoped concern %>

<% if @user_filtering.show_tags? %>
  <div class="filter-tags">
    <% @user_filtering.tags.each do |tag| %>
      <%= render "tag", tag: tag %>
    <% end %>
  </div>
<% end %>

<% if @user_filtering.show_assignees? %>
  <!-- assignees UI -->
<% end %>
```

**With factory method:**

```erb
<% @events.each do |event| %>
  <div class="event-description">
    <%= event.description_for(Current.user).to_html %>
  </div>
<% end %>
```

**With fragment caching:**

```erb
<% cache @user_filtering.cache_key do %>
  <!-- expensive view rendering -->
<% end %>
```

## 1.8 Testing Presenters

Test presenters like any Ruby class:

```ruby
require "test_helper"

class User::FilteringTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
    @user = users(:david)
    @filter = Filter.new
  end

  test "boards returns user's boards ordered by access" do
    filtering = User::Filtering.new(@user, @filter)

    assert_equal @user.boards.ordered_by_recently_accessed, filtering.boards
  end

  test "show_tags? returns false when no tags selected" do
    filtering = User::Filtering.new(@user, @filter)

    assert_not filtering.show_tags?
  end

  test "show_tags? returns true when tags present" do
    @filter.tags = [ tags(:bug) ]
    filtering = User::Filtering.new(@user, @filter)

    assert filtering.show_tags?
  end

  test "cache_key changes when filter changes" do
    filtering1 = User::Filtering.new(@user, @filter)
    key1 = filtering1.cache_key

    @filter.tags = [ tags(:bug) ]
    filtering2 = User::Filtering.new(@user, @filter)
    key2 = filtering2.cache_key

    assert_not_equal key1, key2
  end
end
```

For presenters that generate HTML:

```ruby
class Event::DescriptionTest < ActiveSupport::TestCase
  test "to_html includes creator name" do
    event = events(:card_closed)
    description = Event::Description.new(event, users(:david))

    assert_includes description.to_html, event.creator.name
  end

  test "to_plain_text is safe for notifications" do
    event = events(:card_closed)
    description = Event::Description.new(event, users(:david))

    # No HTML tags in plain text
    assert_no_match /<[^>]+>/, description.to_plain_text
  end
end
```

## 1.9 Real Examples

| Presenter | File | Purpose |
|-----------|------|---------|
| `User::Filtering` | `app/models/user/filtering.rb` | Filter UI state and collections |
| `Event::Description` | `app/models/event/description.rb` | Event → human-readable text |
| `User::DayTimeline` | `app/models/user/day_timeline.rb` | Timeline organization |
| `User::DayTimeline::Column` | `app/models/user/day_timeline/column.rb` | Timeline column with HTML generation |

### Summary

Presenter pattern:
- **Plain Ruby classes** in `app/models/` (no special directory)
- **Domain-organized** (`User::Filtering`, not `FilteringPresenter`)
- **Include ActionView helpers** when generating HTML
- **Factory methods** on models for discoverable APIs
- **Controller concerns** for cross-controller instantiation
- **Memoization** for lazy-loaded collections
- **Boolean methods** for conditional display
- **Cache keys** for fragment caching

---

# 2. Turbo Streams & Turbo Frames

*Section planned. Will cover Turbo Stream actions, Turbo Frame conventions, broadcast patterns, and real-time update strategies.*

---

# 3. Stimulus Controllers

*Section planned. Will cover Stimulus controller conventions, naming patterns, data attribute usage, and common controller patterns.*

---

# 4. View Templates & Partials

*Section planned. Will cover ERB template conventions, partial extraction rules, layout patterns, and component-like partial usage.*

---

**Document Version**: 1.0
**Last Updated**: 2026-02-15
**Maintainer**: Development Team
