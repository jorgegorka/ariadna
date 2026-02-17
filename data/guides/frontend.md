# Frontend Patterns

**View Layer Conventions for Rails Applications**

This guide covers the frontend and view layer patterns used in Rails applications: the Presenter Pattern, Turbo (Drive, Frames, Streams), Stimulus controllers, and view template conventions.

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
- [2. Turbo Streams & Turbo Frames](#2-turbo-streams--turbo-frames)
  - [2.1 Turbo Drive Essentials](#21-turbo-drive-essentials)
  - [2.2 Turbo Frames](#22-turbo-frames)
  - [2.3 Turbo Streams](#23-turbo-streams)
  - [2.4 Optimistic UI](#24-optimistic-ui)
  - [2.5 HTTP Response Conventions](#25-http-response-conventions)
  - [2.6 View Transitions](#26-view-transitions)
- [3. Stimulus Controllers](#3-stimulus-controllers)
  - [3.1 Controller Architecture](#31-controller-architecture)
  - [3.2 Lifecycle](#32-lifecycle)
  - [3.3 Values (Reactive State)](#33-values-reactive-state)
  - [3.4 Targets (DOM References)](#34-targets-dom-references)
  - [3.5 Outlets (Controller-to-Controller Communication)](#35-outlets-controller-to-controller-communication)
  - [3.6 Actions & Parameters](#36-actions--parameters)
  - [3.7 Common Patterns](#37-common-patterns)
- [4. View Templates & Partials](#4-view-templates--partials)
  - [4.1 ERB Conventions](#41-erb-conventions)
  - [4.2 Partial Extraction Rules](#42-partial-extraction-rules)
  - [4.3 Turbo Frame Wrapping in Views](#43-turbo-frame-wrapping-in-views)
  - [4.4 Template-Based DOM Patterns](#44-template-based-dom-patterns)
  - [4.5 Cache-Safe Views](#45-cache-safe-views)

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

## 2.1 Turbo Drive Essentials

**Turbo Drive** intercepts link clicks and form submissions, replacing full page loads with fetch requests and DOM swaps. These lifecycle events are the integration points.

**`turbo:submit-start`** / **`turbo:submit-end`** — Form activity indicators:

```javascript
document.addEventListener("turbo:submit-start", (event) => {
  const btn = event.target.querySelector("[type=submit]")
  btn.disabled = true
  btn.textContent = "Saving..."
})
```

**`turbo:before-render`** — Intercept rendering. **Pausable** via `preventDefault()` + `detail.resume()`. Always guard against `data-turbo-preview` to skip animations on cached snapshots:

```javascript
document.addEventListener("turbo:before-render", (event) => {
  if (document.documentElement.hasAttribute("data-turbo-preview")) return
  event.preventDefault()
  document.documentElement.classList.add("page-leaving")
  document.documentElement.addEventListener("animationend", () => event.detail.resume(), { once: true })
})
```

**`turbo:before-cache`** — Clean transient UI before Turbo snapshots the page. Reset widgets, close dropdowns, clear flash messages:

```javascript
document.addEventListener("turbo:before-cache", () => {
  document.querySelectorAll("[data-dropdown-open]").forEach((el) => el.removeAttribute("data-dropdown-open"))
  document.querySelectorAll(".flash-message").forEach((el) => el.remove())
})
```

**`turbo:load`** — Page fully loaded and rendered. Equivalent to `DOMContentLoaded` for Turbo navigations.

**Progress bar** — Reuse Turbo's built-in bar; style with CSS:

```css
.turbo-progress-bar { height: 3px; background-color: var(--color-accent); }
```

## 2.2 Turbo Frames

A **Turbo Frame** (`<turbo-frame>`) scopes navigation to a region of the page. Only the matching frame swaps on navigation.

**Wrapping conventions** — Scope frame boundaries to the **smallest rerenderable unit**. Use `dom_id` for IDs:

```erb
<turbo-frame id="<%= dom_id(card) %>">
  <%= render "cards/card", card: card %>
</turbo-frame>
```

**Lazy loading** — Set `loading="lazy"` with `src` to defer until the frame enters the viewport:

```erb
<turbo-frame id="activity_feed" src="<%= activity_feed_path %>" loading="lazy">
  <p class="loading-placeholder">Loading activity...</p>
</turbo-frame>
```

**Tabbed navigation** — Drive a content frame from nav links with `data-turbo-frame` and `data-turbo-action="advance"` for history:

```erb
<a href="<%= project_tab_path(@project, tab) %>"
   data-turbo-frame="tab_content"
   data-turbo-action="advance">
  <%= tab.titlecase %>
</a>

<turbo-frame id="tab_content"><%= yield %></turbo-frame>
```

Update active state on **`turbo:frame-load`** (NOT `turbo:click` — click fires before the response):

```javascript
document.addEventListener("turbo:frame-load", (event) => {
  if (event.target.id !== "tab_content") return
  document.querySelectorAll("[data-turbo-frame='tab_content']").forEach((link) => {
    link.classList.toggle("active", link.href === event.target.src)
  })
})
```

**Pagination with history** — Add `data-turbo-action="advance"` to pagination links so page numbers push to browser history.

**Forms in frames** — HTTP status determines behavior:
- **422** — Turbo swaps the response into the frame (validation errors rendered in place)
- **303** — Turbo follows the redirect

```ruby
def create
  if @card.save
    redirect_to @card, status: :see_other
  else
    render :new, status: :unprocessable_entity
  end
end
```

**External form controls** — Use the HTML `form` attribute on inputs outside the `<form>` tag:

```erb
<form id="search_form" action="<%= search_path %>">
  <input type="text" name="query">
</form>
<select name="category" form="search_form">...</select>
```

**Loading states** — Style with the `[busy]` attribute Turbo adds automatically:

```css
turbo-frame[busy] { opacity: 0.5; pointer-events: none; }
```

## 2.3 Turbo Streams

**Turbo Streams** deliver targeted DOM updates via `<turbo-stream>` elements.

**Default actions** — Prefer the 8 built-in actions before writing custom ones: `append`, `prepend`, `replace`, `update`, `remove`, `before`, `after`, `refresh` (Turbo 8 morph).

**Custom stream actions** — Register on `StreamActions`. Inside the function, **`this`** is the `<turbo-stream>` element:

```javascript
import { StreamActions } from "@hotwired/turbo"

StreamActions.flash = function () {
  const flash = document.createElement("div")
  flash.className = `flash flash--${this.getAttribute("type") || "notice"}`
  flash.textContent = this.getAttribute("message")
  document.getElementById("flash_container").appendChild(flash)
}
```

**Inline stream tags** — A `<turbo-stream>` appended to the DOM **executes immediately and self-removes**. Store in a `<template>` to prevent premature execution; clone + modify + append:

```html
<template id="optimistic_card_template">
  <turbo-stream action="append" target="cards">
    <template>
      <div id="card_PLACEHOLDER" class="card card--optimistic">
        <span data-title></span>
      </div>
    </template>
  </turbo-stream>
</template>
```

```javascript
function appendOptimisticCard(id, title) {
  const stream = document.getElementById("optimistic_card_template").content.cloneNode(true)
  stream.querySelector("[id^='card_']").id = `card_${id}`
  stream.querySelector("[data-title]").textContent = title
  document.body.appendChild(stream)
}
```

**Broadcast patterns** — Use `after_create_commit` callbacks with broadcast helpers:

```ruby
class Card < ApplicationRecord
  after_create_commit -> { broadcast_append_to board, target: "cards" }
  after_update_commit -> { broadcast_replace_to board }
  after_destroy_commit -> { broadcast_remove_to board }
end
```

**Turbo 8 morphing** — `turbo_stream.refresh` triggers a full-page morph reconciling the DOM with the server. Use after optimistic UI:

```ruby
format.turbo_stream { render turbo_stream: turbo_stream.refresh }
```

## 2.4 Optimistic UI

Render the expected outcome on the client before server confirmation, then reconcile.

**Pattern:** Store markup in a `<template>` containing `<turbo-stream>`. On `turbo:submit-start`, clone and append. Server responds with `turbo_stream.refresh` to correct discrepancies.

```javascript
document.addEventListener("turbo:submit-start", (event) => {
  if (event.target.id !== "new_card_form") return
  const title = event.target.querySelector("[name='card[title]']").value
  appendOptimisticCard(generateULID(), title)
  event.target.reset()
})
```

**Client-side ULID generation** for optimistic record IDs (time-ordered, collision-resistant):

```javascript
function generateULID() {
  const time = Date.now().toString(36).padStart(10, "0")
  const rand = Array.from(crypto.getRandomValues(new Uint8Array(10)))
    .map((b) => b.toString(36).padStart(2, "0")).join("").slice(0, 16)
  return (time + rand).toUpperCase()
}
```

**Reconciliation** — Turbo 8 diffs server-rendered DOM against client state. Matching optimistic elements are preserved; mismatches are corrected.

## 2.5 HTTP Response Conventions

- **422 Unprocessable Entity** — Validation failures. Turbo re-renders the form frame with errors.
- **303 See Other** — Successful submissions. Turbo follows redirect with GET.
- **Never return 200** for form submissions expecting a redirect.
- **Always use 303** (not 301/302) — guarantees GET follow-up, prevents resubmission.

```ruby
def update
  if @card.update(card_params)
    redirect_to @card, status: :see_other
  else
    render :edit, status: :unprocessable_entity
  end
end
```

## 2.6 View Transitions

Use the **View Transitions API** with Turbo for animated page transitions. Enable globally:

```erb
<meta name="view-transition" content="same-origin">
```

```css
::view-transition-old(root) { animation: fade-out 150ms ease-in; }
::view-transition-new(root) { animation: fade-in 150ms ease-out; }
```

**Direction-aware transitions** — Capture direction in `turbo:click`, apply in `turbo:before-render`, clean up in `turbo:load`:

```javascript
let direction = "forward"

document.addEventListener("turbo:click", (event) => {
  direction = event.target.closest("[data-direction]")?.dataset.direction || "forward"
})

document.addEventListener("turbo:before-render", (event) => {
  if (document.documentElement.hasAttribute("data-turbo-preview")) return
  document.documentElement.dataset.transitionDirection = direction
})

document.addEventListener("turbo:load", () => {
  delete document.documentElement.dataset.transitionDirection
})
```

```css
[data-transition-direction="forward"]::view-transition-old(root)  { animation: slide-out-left 200ms ease-in; }
[data-transition-direction="forward"]::view-transition-new(root)  { animation: slide-in-right 200ms ease-out; }
[data-transition-direction="backward"]::view-transition-old(root) { animation: slide-out-right 200ms ease-in; }
[data-transition-direction="backward"]::view-transition-new(root) { animation: slide-in-left 200ms ease-out; }
```

### Summary

- **Turbo Drive events** — `turbo:before-cache` for cleanup, `turbo:before-render` for animations (pausable), guard against `data-turbo-preview`
- **Frame boundaries** match the smallest rerenderable unit; use `dom_id` for IDs
- **Lazy frames** defer with `loading="lazy"` + `src`; post-load setup via `turbo:frame-load`
- **Tabs and pagination** use `data-turbo-frame` + `data-turbo-action="advance"` for history
- **HTTP status codes** — 422 for errors, 303 for redirects, never 200 for redirect-expecting forms
- **Prefer built-in stream actions** before custom; register custom actions on `StreamActions`
- **Inline streams** execute on DOM insertion and self-remove; store in `<template>` to control timing
- **Optimistic UI** clones stream templates on `turbo:submit-start`, uses ULIDs, reconciles via morph
- **Broadcasts** use `after_create_commit` + `broadcast_append_to` / `broadcast_replace_to`
- **View Transitions** integrate through `turbo:before-render` with direction-aware CSS

---

# 3. Stimulus Controllers

## 3.1 Controller Architecture

**File naming** follows the Stimulus convention: `app/javascript/controllers/{name}_controller.js`. Multi-word names use kebab-case in filenames and camelCase in class names:

| File | Class | Identifier |
|------|-------|------------|
| `upload_preview_controller.js` | `UploadPreviewController` | `upload-preview` |
| `broadcast_channel_controller.js` | `BroadcastChannelController` | `broadcast-channel` |
| `media_player_controller.js` | `MediaPlayerController` | `media-player` |

**Registration** is automatic via `esbuild` or `importmap` conventions. Controllers placed in `app/javascript/controllers/` are auto-discovered and registered. No manual `application.register()` calls needed.

**Contract-first declaration** means every controller declares its full interface at the top, before any methods. This makes controllers self-documenting and lets agents understand the API without reading implementation:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values  = { url: String, refreshInterval: Number, active: Boolean }
  static targets = ["output", "spinner", "emptyState"]
  static outlets = ["filter", "notification"]
  static classes = ["loading", "hidden"]

  // Lifecycle methods
  connect() { }
  disconnect() { }

  // Action methods
  refresh() { }
  toggle() { }
}
```

**Single-purpose controllers.** Each controller owns one behavior. A `clipboard_controller.js` copies text. A `toggle_controller.js` shows/hides elements. Compose multiple controllers on the same element rather than building one large controller:

```html
<div data-controller="clipboard toggle tooltip"
     data-clipboard-text-value="https://example.com/share/abc123"
     data-toggle-class="hidden">
  <button data-action="clipboard#copy toggle#toggle">Copy Link</button>
  <span data-toggle-target="content" class="hidden">Copied!</span>
</div>
```

## 3.2 Lifecycle

**Symmetric setup and teardown.** Every resource acquired in `connect()` must be released in `disconnect()`. Turbo navigations and morphs trigger these repeatedly, so leaks accumulate fast:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { channel: String }

  connect() {
    this.broadcast = new BroadcastChannel(this.channelValue)
    this.broadcast.onmessage = this.handleMessage.bind(this)

    this.resizeObserver = new ResizeObserver(this.handleResize.bind(this))
    this.resizeObserver.observe(this.element)

    this.refreshTimer = setInterval(() => this.refresh(), 30000)
  }

  disconnect() {
    this.broadcast.close()

    this.resizeObserver.disconnect()

    clearInterval(this.refreshTimer)
  }
}
```

**Common teardown checklist:**

| Resource | Setup | Teardown |
|----------|-------|----------|
| BroadcastChannel | `new BroadcastChannel()` | `.close()` |
| Blob URL | `URL.createObjectURL()` | `URL.revokeObjectURL()` |
| Third-party player | `WaveSurfer.create()` | `.destroy()` |
| Timer | `setInterval()` / `setTimeout()` | `clearInterval()` / `clearTimeout()` |
| Observer | `.observe()` | `.disconnect()` |
| EventListener (window/document) | `addEventListener()` | `removeEventListener()` |

**Guard `valueChanged` callbacks.** Value callbacks can fire before `connect()` completes, which means targets or instance properties may not exist yet. Always guard:

```javascript
export default class extends Controller {
  static values  = { url: String }
  static targets = ["frame"]

  urlValueChanged(url) {
    // Guard — target may not be connected yet
    this.frameTarget?.src = url
  }
}
```

Alternatively, use an early return:

```javascript
urlValueChanged(url) {
  if (!this.hasFrameTarget) return
  this.frameTarget.src = url
}
```

## 3.3 Values (Reactive State)

**Declaration** uses `static values` with type constructors. Stimulus handles serialization, type coercion, and default values:

```javascript
export default class extends Controller {
  static values = {
    url:       String,     // default: ""
    count:     Number,     // default: 0
    active:    Boolean,    // default: false
    filters:   Object,     // default: {}
    items:     Array,      // default: []
  }
}
```

```html
<div data-controller="dashboard"
     data-dashboard-url-value="/api/stats"
     data-dashboard-count-value="42"
     data-dashboard-active-value="true"
     data-dashboard-filters-value='{"status":"open"}'>
</div>
```

**React with `{name}ValueChanged` callbacks.** These fire whenever the value changes, including the initial set from HTML attributes:

```javascript
export default class extends Controller {
  static values  = { page: Number }
  static targets = ["list", "counter"]

  pageValueChanged(current, previous) {
    if (previous !== undefined) {
      this.fetchPage(current)
    }
    this.counterTarget.textContent = `Page ${current}`
  }

  next() {
    this.pageValue++   // Triggers pageValueChanged automatically
  }
}
```

**Bridge third-party libraries through value callbacks.** The value becomes the single source of truth. The callback translates it into library-specific API calls:

```javascript
import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

export default class extends Controller {
  static values  = { type: String, data: Object, options: Object }
  static targets = ["canvas"]

  connect() {
    this.chart = new Chart(this.canvasTarget, {
      type: this.typeValue,
      data: this.dataValue,
      options: this.optionsValue
    })
  }

  dataValueChanged(data) {
    if (!this.chart) return
    this.chart.data = data
    this.chart.update()
  }

  optionsValueChanged(options) {
    if (!this.chart) return
    this.chart.options = options
    this.chart.update()
  }

  disconnect() {
    this.chart.destroy()
  }
}
```

**Values as the single source of truth.** Never duplicate state in DOM attributes, instance variables, or dataset entries alongside values. If a controller needs state, declare a value. Read state from `this.{name}Value`, mutate via `this.{name}Value = x`, and react in the callback. This keeps the data flow unidirectional and predictable.

## 3.4 Targets (DOM References)

**Declaration** registers named references to child elements:

```javascript
export default class extends Controller {
  static targets = ["input", "output", "submitButton"]
}
```

```html
<form data-controller="search">
  <input data-search-target="input" type="text">
  <div data-search-target="output"></div>
  <button data-search-target="submitButton">Search</button>
</form>
```

Access via `this.inputTarget` (first match), `this.inputTargets` (all matches), and `this.hasInputTarget` (existence check).

**Target callbacks** fire when the DOM changes. These are essential for Turbo Stream integration — when elements are appended or removed, the controller reacts automatically:

```javascript
export default class extends Controller {
  static targets = ["item", "counter", "emptyState"]

  itemTargetConnected(element) {
    this.updateCount()
    element.animate([{ opacity: 0 }, { opacity: 1 }], { duration: 200 })
  }

  itemTargetDisconnected(element) {
    this.updateCount()
  }

  updateCount() {
    this.counterTarget.textContent = this.itemTargets.length
    this.emptyStateTarget.hidden = this.itemTargets.length > 0
  }
}
```

**Keep target callbacks idempotent.** Turbo morphs and reconnections can trigger `TargetConnected` multiple times for the same element. Avoid additive side effects:

```javascript
// Bad — adds duplicate listeners on reconnect
itemTargetConnected(element) {
  element.addEventListener("click", this.handleClick)
}

// Good — safe across repeated connect/disconnect cycles
itemTargetConnected(element) {
  element.handleClick ||= this.handleClick.bind(this)
  element.removeEventListener("click", element.handleClick)
  element.addEventListener("click", element.handleClick)
}
```

**Derive computed state from targets** rather than tracking counts or flags in separate values:

```javascript
get isEmpty() {
  return this.itemTargets.length === 0
}

get selectedItems() {
  return this.itemTargets.filter(el => el.dataset.selected === "true")
}

get selectedCount() {
  return this.selectedItems.length
}
```

## 3.5 Outlets (Controller-to-Controller Communication)

**Outlets** let one controller access another controller's instance directly. Declare with `static outlets`:

```javascript
// dashboard_controller.js
export default class extends Controller {
  static outlets = ["chart", "filter"]

  apply() {
    const filters = this.filterOutlet.currentFilters
    this.chartOutlets.forEach(chart => chart.reload(filters))
  }
}
```

```html
<div data-controller="dashboard"
     data-dashboard-chart-outlet=".chart-widget"
     data-dashboard-filter-outlet="#main-filter">

  <div id="main-filter" data-controller="filter">...</div>
  <div class="chart-widget" data-controller="chart">...</div>
  <div class="chart-widget" data-controller="chart">...</div>
</div>
```

**Access patterns:**

| Accessor | Returns | Throws if missing |
|----------|---------|-------------------|
| `this.chartOutlet` | First matching controller | Yes |
| `this.chartOutlets` | Array of all matching controllers | No (empty array) |
| `this.hasChartOutlet` | Boolean | No |

**Outlet callbacks** notify when outlets connect or disconnect:

```javascript
export default class extends Controller {
  static outlets = ["player"]

  playerOutletConnected(controller, element) {
    controller.mute()  // Direct method call on connected controller
  }

  playerOutletDisconnected(controller, element) {
    // Cleanup references
  }
}
```

**Prefer outlets** over `this.application.getControllerForElementAndIdentifier()` or custom events for direct controller-to-controller communication. Outlets are declarative, observable, and automatically managed by Stimulus.

## 3.6 Actions & Parameters

**Action parameters** pass data from HTML to action methods without manual `dataset` parsing. Declare parameters with `data-{controller}-{param}-param`:

```html
<div data-controller="cart">
  <button data-action="cart#add"
          data-cart-id-param="42"
          data-cart-name-param="Widget"
          data-cart-price-param="19.99">
    Add to Cart
  </button>
</div>
```

```javascript
export default class extends Controller {
  add({ params: { id, name, price } }) {
    // id = 42 (Number), name = "Widget" (String), price = 19.99 (Number)
    // Types are automatically inferred from the value
    this.addItem(id, name, price)
  }
}
```

**Keyboard filters** let you bind actions to specific key combinations:

```html
<div data-controller="editor">
  <textarea data-action="keydown.ctrl+s->editor#save
                         keydown.meta+s->editor#save
                         keydown.esc->editor#cancel
                         keydown.ctrl+enter->editor#submit">
  </textarea>
</div>
```

**Supported keyboard filters:**

| Category | Filters |
|----------|---------|
| Modifiers | `ctrl`, `alt`, `shift`, `meta` |
| Navigation | `enter`, `tab`, `esc`, `space`, `up`, `down`, `left`, `right` |
| Letters | `a` through `z` |
| Numbers | `0` through `9` |
| Combinations | `ctrl+s`, `shift+enter`, `meta+k`, `ctrl+shift+p` |

**Non-focusable elements** need `tabindex="0"` to receive keyboard events:

```html
<div data-controller="shortcuts"
     data-action="keydown.ctrl+z->shortcuts#undo"
     tabindex="0">
  <!-- Content that needs keyboard shortcuts -->
</div>
```

## 3.7 Common Patterns

### Image Upload Preview

Use `URL.createObjectURL()` for instant client-side previews. Always revoke the URL after the image loads to free memory:

```javascript
export default class extends Controller {
  static targets = ["input", "preview"]

  preview() {
    const file = this.inputTarget.files[0]
    if (!file) return

    const url = URL.createObjectURL(file)
    this.previewTarget.src = url
    this.previewTarget.onload = () => URL.revokeObjectURL(url)
    this.previewTarget.hidden = false
  }
}
```

```html
<div data-controller="upload-preview">
  <input type="file" accept="image/*"
         data-upload-preview-target="input"
         data-action="change->upload-preview#preview">
  <img data-upload-preview-target="preview" hidden>
</div>
```

### Inter-Tab Communication

**BroadcastChannel** API enables communication across browser tabs. Create in `connect()`, close in `disconnect()`, and scope channels by purpose:

```javascript
export default class extends Controller {
  static values = { channel: { type: String, default: "notifications" } }

  connect() {
    this.channel = new BroadcastChannel(this.channelValue)
    this.channel.onmessage = this.handleMessage.bind(this)
  }

  handleMessage({ data }) {
    if (data.type === "logout") {
      window.location.href = "/session/new"
    }
  }

  broadcast(type, payload = {}) {
    this.channel.postMessage({ type, ...payload })
  }

  disconnect() {
    this.channel.close()
  }
}
```

### Intersection Observer

Use `stimulus-use` `useIntersection` for viewport-based behavior like lazy loading or picture-in-picture triggers:

```javascript
import { Controller } from "@hotwired/stimulus"
import { useIntersection } from "stimulus-use"

export default class extends Controller {
  static values = { loaded: Boolean }

  connect() {
    useIntersection(this, { threshold: 0.25 })
  }

  appear() {
    if (this.loadedValue) return
    this.loadedValue = true
    this.element.src = this.element.dataset.lazySrc
  }
}
```

### MutationObserver

Watch DOM attribute changes for reactivity. Useful for observing Turbo Frame `busy` attribute changes:

```javascript
export default class extends Controller {
  static targets = ["frame", "spinner"]

  connect() {
    this.observer = new MutationObserver(this.handleMutation.bind(this))
    this.observer.observe(this.frameTarget, { attributes: true, attributeFilter: ["busy"] })
  }

  handleMutation(mutations) {
    const isBusy = this.frameTarget.hasAttribute("busy")
    this.spinnerTarget.hidden = !isBusy
  }

  disconnect() {
    this.observer.disconnect()
  }
}
```

### Feature Detection

Always check browser API availability before exposing functionality. Hide or disable UI that depends on unsupported APIs:

```javascript
export default class extends Controller {
  static targets = ["pipButton", "shareButton"]
  static classes = ["unsupported"]

  connect() {
    if (!document.pictureInPictureEnabled) {
      this.pipButtonTarget.hidden = true
    }

    if (!navigator.share) {
      this.shareButtonTarget.hidden = true
    }

    if (!("mediaSession" in navigator)) {
      this.element.classList.add(this.unsupportedClass)
    }
  }
}
```

## Summary

Stimulus controller conventions:

- **Contract-first** — declare `static values`, `targets`, `outlets`, `classes` before any methods
- **Single-purpose** — one behavior per controller, compose via multiple `data-controller` bindings
- **Symmetric lifecycle** — every `connect()` setup has a matching `disconnect()` teardown
- **Guard value callbacks** — use optional chaining or `hasTarget` checks since callbacks fire before `connect()`
- **Values as single source of truth** — bridge third-party libraries through `{name}ValueChanged` callbacks
- **Target callbacks for Turbo** — use `TargetConnected` / `TargetDisconnected` to react to DOM changes from Turbo Streams
- **Outlets over events** — prefer declared outlets for direct controller communication
- **Action parameters over dataset** — use `data-{controller}-{param}-param` to pass typed data to actions
- **Feature detection** — check API availability before exposing UI that depends on browser capabilities
- **Idempotent callbacks** — target and outlet callbacks must be safe across repeated connect/disconnect cycles

---

# 4. View Templates & Partials

## 4.1 ERB Conventions

**Templates are rendering surfaces, not logic containers.** Keep them thin by delegating decisions to presenters or model methods. A template should read like a layout blueprint: structure and data slots, nothing more.

**Rules:**
- No conditionals deeper than one level in a template
- No query calls (`where`, `find`, `count`) in ERB — use presenters
- Use `content_for` to inject section-specific content into layouts
- Prefer `tag.div` helpers inside presenters over inline ERB for complex HTML

### `content_for` for Section-Specific Content

Use `content_for` to push page-specific content into layout slots:

```erb
<%# app/views/messages/show.html.erb %>
<% content_for :title, @message.subject %>
<% content_for :head do %>
  <%= javascript_include_tag "trix" %>
<% end %>

<div class="message">
  <%= render partial: "message", locals: { message: @message } %>
</div>
```

```erb
<%# app/views/layouts/application.html.erb %>
<head>
  <title><%= content_for(:title) || "App" %></title>
  <%= yield :head %>
</head>
```

### Delegating Logic to Presenters

When a template starts accumulating conditionals, extract them:

```erb
<%# Bad — logic in template %>
<% if user.avatar.attached? && user.avatar.variable? %>
  <%= image_tag user.avatar.variant(resize_to_limit: [100, 100]) %>
<% else %>
  <%= image_tag "default_avatar.png" %>
<% end %>

<%# Good — delegate to presenter %>
<%= presenter.avatar_tag %>
```

## 4.2 Partial Extraction Rules

**Extract a partial when:** the same markup appears in 2+ templates, or you identify a clear UI component boundary (card, form group, nav item). A partial is the smallest reusable rendering unit.

### Naming and Organization

- Name with a leading underscore: `_card.html.erb`
- Place cross-controller partials in `app/views/shared/`: `shared/_flash.html.erb`
- Name partials after the UI concept, not the model: `_card.html.erb`, not `_message_display.html.erb`

### Pass Data Explicitly

**Never rely on instance variables inside partials.** Always pass data via `locals:`:

```erb
<%# Good — explicit locals %>
<%= render partial: "messages/card", locals: { message: message, show_actions: true } %>

<%# Also good — short form for collections %>
<%= render partial: "messages/message", collection: @messages, as: :message %>

<%# Bad — instance variable dependency %>
<%= render partial: "messages/card" %>
<%# partial internally references @message — fragile and implicit %>
```

### Cross-Controller Partials

For UI components shared across controllers, use the `shared/` directory:

```erb
<%# From any controller %>
<%= render partial: "shared/empty_state", locals: { message: "No results found", icon: "search" } %>
<%= render partial: "shared/pagination", locals: { pagy: @pagy } %>
```

## 4.3 Turbo Frame Wrapping in Views

**Wrap the rerenderable unit, not the entire page.** A Turbo Frame defines the boundary of what gets swapped on navigation or form submission. Frame IDs must match between the source page and the server response.

### Frame ID Conventions

Use `dom_id` for consistent, collision-free frame and target IDs:

```erb
<%# app/views/messages/show.html.erb %>
<%= turbo_frame_tag dom_id(message) do %>
  <h2><%= message.subject %></h2>
  <p><%= message.body %></p>
  <%= link_to "Edit", edit_message_path(message) %>
<% end %>

<%# app/views/messages/edit.html.erb %>
<%= turbo_frame_tag dom_id(message) do %>
  <%= render "form", message: message %>
<% end %>
```

The frame IDs match (`message_123`), so clicking "Edit" swaps only the frame content.

### Lazy-Loaded Frames

Use the `src` attribute to load frame content on demand:

```erb
<%= turbo_frame_tag "comments", src: message_comments_path(message), loading: :lazy do %>
  <p>Loading comments...</p>
<% end %>
```

The frame renders placeholder content immediately, then fetches and replaces it when the frame enters the viewport.

## 4.4 Template-Based DOM Patterns

**Store Turbo Stream markup in `<template>` elements** to prevent premature execution by the browser. This is essential for optimistic UI patterns where you prepare stream actions in the DOM and dispatch them from Stimulus controllers.

### Clone-and-Append Pattern

```html
<%# Embed a hidden template in the page %>
<template data-optimistic-stream>
  <turbo-stream action="append" target="messages">
    <template>
      <div class="message message--pending" id="pending_message">
        <p data-placeholder>Sending...</p>
      </div>
    </template>
  </turbo-stream>
</template>
```

```javascript
// app/javascript/controllers/optimistic_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template"]

  submit() {
    const template = this.templateTarget.content.cloneNode(true)
    const id = `pending_${Date.now()}`
    template.querySelector(".message").id = id
    document.body.append(template)
  }
}
```

The `<template>` element prevents the `<turbo-stream>` from executing on page load. Cloning and appending triggers the stream action on demand.

## 4.5 Cache-Safe Views

**Turbo caches pages before navigating away.** If transient UI states (open dropdowns, flash messages, active modals) are cached, they reappear as stale artifacts on restoration visits. Clean them up before the cache snapshot.

### Cleaning Transient UI

```javascript
// app/javascript/controllers/cache_cleanup_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    document.addEventListener("turbo:before-cache", this.cleanup)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.cleanup)
  }

  cleanup = () => {
    // Close dropdowns
    this.element.querySelectorAll("[data-expanded]").forEach(el => {
      el.removeAttribute("data-expanded")
    })
    // Clear flash messages
    this.element.querySelectorAll(".flash").forEach(el => el.remove())
    // Reset form states
    this.element.querySelectorAll("form").forEach(form => form.reset())
  }
}
```

### Guard Against Preview Rendering

When Turbo restores a cached page, it adds `data-turbo-preview` to the `<html>` element. Use this to guard rendering that depends on fresh data:

```erb
<% unless request.headers["Purpose"] == "preview" %>
  <div class="live-metrics" data-controller="polling">
    <%= render partial: "dashboard/metrics", locals: { stats: @stats } %>
  </div>
<% end %>
```

### Fragment Caching with Presenter Keys

Use presenter cache keys to invalidate fragments when underlying data changes:

```erb
<% cache presenter.cache_key do %>
  <div class="filtering-panel">
    <%= render partial: "filters/tags", locals: { tags: presenter.tags } %>
    <%= render partial: "filters/users", locals: { users: presenter.users } %>
  </div>
<% end %>
```

### Summary

View templates and partials:
- **Keep templates thin** — delegate conditionals and queries to presenters
- **Use `content_for`** to inject page-specific content into layouts
- **Extract partials** when markup repeats or a clear component boundary exists
- **Pass data via `locals:`** — never rely on instance variables in partials
- **Use `dom_id`** for Turbo Frame IDs to ensure consistency between page and response
- **Lazy-load frames** with `src` for deferred content
- **Store Turbo Streams in `<template>` elements** to prevent premature execution
- **Clean transient UI** in `turbo:before-cache` to avoid stale cached states
- **Guard preview rendering** with `data-turbo-preview` checks
- **Use presenter cache keys** for fragment caching invalidation

---

**Document Version**: 2.0
**Last Updated**: 2026-02-17
**Maintainer**: Development Team
