# Views — ERB, Layouts, Partials

Templates are rendering surfaces, not logic containers. Delegate decisions to presenters or model methods.

## ERB Conventions

**Rules:**
- No conditionals deeper than one level
- No query calls (`where`, `find`, `count`) — use presenters
- Use `content_for` to inject section-specific content into layouts
- Prefer `tag.div` helpers inside presenters over inline ERB for complex HTML

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

### `content_for` Pattern

```erb
<%# app/views/messages/show.html.erb %>
<% content_for :title, @message.subject %>
<% content_for :head do %>
  <%= javascript_include_tag "trix" %>
<% end %>
```

```erb
<%# app/views/layouts/application.html.erb %>
<title><%= content_for(:title) || "App" %></title>
<%= yield :head %>
```

---

## Partials

**Extract when:** the same markup appears in 2+ templates, or a clear UI component boundary exists.

**Naming:**
- Leading underscore: `_card.html.erb`
- Named after the UI concept, not the model: `_card.html.erb` not `_message_display.html.erb`
- Cross-controller partials in `app/views/shared/`

**Always pass explicit locals — never rely on instance variables inside partials:**

```erb
<%# Good %>
<%= render partial: "messages/card", locals: { message: message, show_actions: true } %>

<%# Good — short form for collections %>
<%= render partial: "messages/message", collection: @messages, as: :message %>

<%# Bad — implicit instance variable dependency %>
<%= render partial: "messages/card" %>
```

---

## Turbo Frame Wrapping

Wrap the **smallest rerenderable unit**. Frame IDs must match between the source page and the server response.

```erb
<%# app/views/messages/show.html.erb %>
<%= turbo_frame_tag dom_id(message) do %>
  <h2><%= message.subject %></h2>
  <%= link_to "Edit", edit_message_path(message) %>
<% end %>

<%# app/views/messages/edit.html.erb — same ID, swaps in place %>
<%= turbo_frame_tag dom_id(message) do %>
  <%= render "form", message: message %>
<% end %>
```

Lazy-loaded frame with placeholder:

```erb
<%= turbo_frame_tag "comments", src: message_comments_path(message), loading: :lazy do %>
  <p>Loading comments...</p>
<% end %>
```

Tabbed navigation with history:

```erb
<a href="<%= tab_path %>" data-turbo-frame="tab_content" data-turbo-action="advance">
  Tab Name
</a>
<turbo-frame id="tab_content"><%= yield %></turbo-frame>
```

Update active state on `turbo:frame-load` (not `turbo:click`):

```javascript
document.addEventListener("turbo:frame-load", (event) => {
  if (event.target.id !== "tab_content") return
  document.querySelectorAll("[data-turbo-frame='tab_content']").forEach((link) => {
    link.classList.toggle("active", link.href === event.target.src)
  })
})
```

---

## Cache-Safe Views

Turbo caches pages before navigating. Transient UI reappears as stale artifacts unless cleaned up.

```javascript
document.addEventListener("turbo:before-cache", () => {
  document.querySelectorAll("[data-expanded]").forEach(el => el.removeAttribute("data-expanded"))
  document.querySelectorAll(".flash").forEach(el => el.remove())
  document.querySelectorAll("form").forEach(form => form.reset())
})
```

Guard content that depends on fresh data against preview (cached) renders:

```erb
<% unless request.headers["Purpose"] == "preview" %>
  <div data-controller="polling"><%= render "metrics", stats: @stats %></div>
<% end %>
```

Fragment caching with presenter keys:

```erb
<% cache presenter.cache_key do %>
  <%= render partial: "filters/tags", locals: { tags: presenter.tags } %>
<% end %>
```

---

## Template-Based Optimistic UI

Store `<turbo-stream>` inside a `<template>` to prevent premature execution:

```html
<template data-optimistic-stream>
  <turbo-stream action="append" target="messages">
    <template>
      <div class="message message--pending" id="pending_PLACEHOLDER">
        <p data-placeholder>Sending...</p>
      </div>
    </template>
  </turbo-stream>
</template>
```

Clone and dispatch from a Stimulus controller on submit:

```javascript
submit() {
  const template = this.templateTarget.content.cloneNode(true)
  template.querySelector(".message").id = `pending_${Date.now()}`
  document.body.append(template)
}
```
