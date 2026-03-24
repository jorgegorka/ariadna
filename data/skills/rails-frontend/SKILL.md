---
name: rails-frontend
description: Ruby on Rails frontend conventions — Hotwire, Turbo, Stimulus, views, components, assets. Use when implementing frontend features, building views, or working with JavaScript/CSS.
---

# Rails Frontend

Core conventions for Rails frontend work using the Hotwire stack: Turbo Drive, Turbo Frames, Turbo Streams, and Stimulus controllers.

## Sub-files

- [VIEWS.md](VIEWS.md) — ERB conventions, layouts, partials, Turbo Frame wrapping
- [COMPONENTS.md](COMPONENTS.md) — Stimulus controllers, presenter pattern, component composition
- [ASSETS.md](ASSETS.md) — CSS architecture, design tokens, asset pipeline

---

## Stack

- **Turbo Drive** — replaces full page loads with fetch + DOM swap
- **Turbo Frames** — scope navigation to a region; swap on response
- **Turbo Streams** — targeted DOM mutations via `<turbo-stream>` elements
- **Stimulus** — lightweight JS controllers bound to DOM elements
- **No React/Vue** — Hotwire is the default; reach for Stimulus before any SPA framework

---

## Turbo Essentials

### HTTP Status Codes

Always use these — Turbo depends on them:

| Status | Meaning | When to Use |
|--------|---------|-------------|
| `303 See Other` | Redirect after success | After any create/update/destroy |
| `422 Unprocessable Entity` | Validation failure | Re-render form in frame |
| Never `200` | For redirect-expecting forms | — |

```ruby
def create
  if @card.save
    redirect_to @card, status: :see_other
  else
    render :new, status: :unprocessable_entity
  end
end
```

### Turbo Frames

Scope to the **smallest rerenderable unit**. Always use `dom_id` for IDs:

```erb
<turbo-frame id="<%= dom_id(card) %>">
  <%= render "cards/card", card: card %>
</turbo-frame>
```

Lazy loading with placeholder:

```erb
<turbo-frame id="activity_feed" src="<%= activity_feed_path %>" loading="lazy">
  <p>Loading...</p>
</turbo-frame>
```

Style the loading state with the auto-added `[busy]` attribute:

```css
turbo-frame[busy] { opacity: 0.5; pointer-events: none; }
```

### Turbo Streams

Prefer the 8 built-in actions: `append`, `prepend`, `replace`, `update`, `remove`, `before`, `after`, `refresh`.

Broadcast from model callbacks:

```ruby
class Card < ApplicationRecord
  after_create_commit  -> { broadcast_append_to board, target: "cards" }
  after_update_commit  -> { broadcast_replace_to board }
  after_destroy_commit -> { broadcast_remove_to board }
end
```

Custom stream actions register on `StreamActions`; `this` is the `<turbo-stream>` element:

```javascript
import { StreamActions } from "@hotwired/turbo"

StreamActions.flash = function () {
  const flash = document.createElement("div")
  flash.className = `flash flash--${this.getAttribute("type") || "notice"}`
  flash.textContent = this.getAttribute("message")
  document.getElementById("flash_container").appendChild(flash)
}
```

### Turbo Drive Events

| Event | Use For |
|-------|---------|
| `turbo:before-cache` | Clean transient UI (close dropdowns, remove flashes) |
| `turbo:before-render` | Page transition animations — **pausable** via `preventDefault()` + `detail.resume()` |
| `turbo:load` | Post-navigation setup (equivalent to `DOMContentLoaded`) |
| `turbo:frame-load` | Frame navigation complete — update active states here, NOT on `turbo:click` |

Always guard animations against `data-turbo-preview` (cached snapshot renders):

```javascript
document.addEventListener("turbo:before-render", (event) => {
  if (document.documentElement.hasAttribute("data-turbo-preview")) return
  event.preventDefault()
  document.documentElement.classList.add("page-leaving")
  document.documentElement.addEventListener("animationend", () => event.detail.resume(), { once: true })
})
```

### Optimistic UI

1. Store markup in a `<template>` containing a `<turbo-stream>` (prevents premature execution)
2. On `turbo:submit-start`, clone and append to the DOM
3. Server responds with `turbo_stream.refresh` to reconcile

Use client-side ULIDs for optimistic IDs (time-ordered, collision-resistant):

```javascript
function generateULID() {
  const time = Date.now().toString(36).padStart(10, "0")
  const rand = Array.from(crypto.getRandomValues(new Uint8Array(10)))
    .map((b) => b.toString(36).padStart(2, "0")).join("").slice(0, 16)
  return (time + rand).toUpperCase()
}
```

---

## Presenter Pattern

Use plain Ruby presenter classes in `app/models/` (not a separate `app/presenters/` directory) to keep view logic out of ERB templates.

**Create a presenter when:** a view needs 3+ conditionals, multiple computed values, HTML generation, or fragment caching.

Key anatomy:

```ruby
class User::Filtering
  def initialize(user, filter, expanded: false)
    @user, @filter, @expanded = user, filter, expanded
  end

  def boards = @boards ||= user.boards.ordered_by_recently_accessed  # memoized
  def show_tags? = filter.tags.any?                                   # boolean for display
  def cache_key                                                        # for fragment caching
    ActiveSupport::Cache.expand_cache_key([user, filter, boards], "user-filtering")
  end
end
```

- **Domain-organized names**: `User::Filtering`, not `FilteringPresenter`
- **Include ActionView helpers** when generating HTML: `include ActionView::Helpers::TagHelper`
- **Factory methods** on models: `event.description_for(user)` for discoverable APIs
- **Controller concerns** for cross-controller instantiation

---

## View Transitions API

Enable in the layout:

```erb
<meta name="view-transition" content="same-origin">
```

Direction-aware transitions: capture in `turbo:click`, apply in `turbo:before-render`, clean up in `turbo:load`.

---

## Key Rules

- No query calls (`where`, `find`, `count`) in ERB — push to presenters or controllers
- No conditionals deeper than one level in templates
- Always pass locals explicitly to partials — never rely on instance variables inside partials
- Use `dom_id` for all Turbo Frame and Stream target IDs
- Clean transient UI on `turbo:before-cache` (dropdowns, flash messages, open modals)
