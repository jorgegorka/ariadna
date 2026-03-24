# Components — Stimulus Controllers & Presenter Pattern

## Stimulus Controller Architecture

**File naming:** `app/javascript/controllers/{name}_controller.js`

| File | Class | Identifier |
|------|-------|------------|
| `upload_preview_controller.js` | `UploadPreviewController` | `upload-preview` |
| `broadcast_channel_controller.js` | `BroadcastChannelController` | `broadcast-channel` |

Controllers in `app/javascript/controllers/` are auto-discovered. No manual `application.register()` needed.

### Contract-First Declaration

Declare the full interface at the top before any methods:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values  = { url: String, refreshInterval: Number, active: Boolean }
  static targets = ["output", "spinner", "emptyState"]
  static outlets = ["filter", "notification"]
  static classes = ["loading", "hidden"]

  connect() { }
  disconnect() { }
}
```

**Single-purpose controllers.** Compose multiple controllers rather than one large one:

```html
<div data-controller="clipboard toggle tooltip"
     data-clipboard-text-value="https://example.com/share/abc123">
  <button data-action="clipboard#copy toggle#toggle">Copy Link</button>
</div>
```

---

## Lifecycle

**Every `connect()` resource must be released in `disconnect()`.** Turbo navigations and morphs trigger these repeatedly:

```javascript
connect() {
  this.broadcast = new BroadcastChannel(this.channelValue)
  this.broadcast.onmessage = this.handleMessage.bind(this)
  this.refreshTimer = setInterval(() => this.refresh(), 30000)
}

disconnect() {
  this.broadcast.close()
  clearInterval(this.refreshTimer)
}
```

| Resource | Setup | Teardown |
|----------|-------|----------|
| BroadcastChannel | `new BroadcastChannel()` | `.close()` |
| Blob URL | `URL.createObjectURL()` | `URL.revokeObjectURL()` |
| Timer | `setInterval()` / `setTimeout()` | `clearInterval()` / `clearTimeout()` |
| Observer | `.observe()` | `.disconnect()` |
| EventListener (window/doc) | `addEventListener()` | `removeEventListener()` |

**Guard `valueChanged` callbacks** — they fire before `connect()` completes; targets may not exist yet:

```javascript
urlValueChanged(url) {
  if (!this.hasFrameTarget) return
  this.frameTarget.src = url
}
```

---

## Values (Reactive State)

Values are the single source of truth. Never duplicate state in dataset entries or instance variables.

```javascript
static values = {
  url:     String,   // default: ""
  count:   Number,   // default: 0
  active:  Boolean,  // default: false
  filters: Object,   // default: {}
  items:   Array,    // default: []
}
```

React with `{name}ValueChanged`. The `previous` argument is `undefined` on initial load:

```javascript
pageValueChanged(current, previous) {
  if (previous !== undefined) this.fetchPage(current)
  this.counterTarget.textContent = `Page ${current}`
}

next() { this.pageValue++ }  // Triggers pageValueChanged automatically
```

Bridge third-party libraries through value callbacks — the value is the source of truth, the callback translates to the library API:

```javascript
dataValueChanged(data) {
  if (!this.chart) return
  this.chart.data = data
  this.chart.update()
}
```

---

## Targets

Target callbacks fire when the DOM changes — essential for Turbo Stream integration:

```javascript
static targets = ["item", "counter", "emptyState"]

itemTargetConnected(element) {
  this.updateCount()
  element.animate([{ opacity: 0 }, { opacity: 1 }], { duration: 200 })
}

itemTargetDisconnected() { this.updateCount() }

updateCount() {
  this.counterTarget.textContent = this.itemTargets.length
  this.emptyStateTarget.hidden = this.itemTargets.length > 0
}
```

**Keep target callbacks idempotent** — morphs can trigger `TargetConnected` multiple times:

```javascript
// Bad — adds duplicate listeners on reconnect
itemTargetConnected(element) {
  element.addEventListener("click", this.handleClick)
}

// Good
itemTargetConnected(element) {
  element.handleClick ||= this.handleClick.bind(this)
  element.removeEventListener("click", element.handleClick)
  element.addEventListener("click", element.handleClick)
}
```

Derive computed state from targets rather than tracking separate values:

```javascript
get isEmpty()       { return this.itemTargets.length === 0 }
get selectedItems() { return this.itemTargets.filter(el => el.dataset.selected === "true") }
```

---

## Outlets (Controller-to-Controller)

Prefer outlets over custom events or `getControllerForElementAndIdentifier` for direct communication:

```javascript
// dashboard_controller.js
static outlets = ["chart", "filter"]

apply() {
  const filters = this.filterOutlet.currentFilters
  this.chartOutlets.forEach(chart => chart.reload(filters))
}
```

```html
<div data-controller="dashboard"
     data-dashboard-chart-outlet=".chart-widget"
     data-dashboard-filter-outlet="#main-filter">
```

---

## Action Parameters

Pass typed data from HTML without manual `dataset` parsing:

```html
<button data-action="cart#add"
        data-cart-id-param="42"
        data-cart-name-param="Widget"
        data-cart-price-param="19.99">
```

```javascript
add({ params: { id, name, price } }) {
  this.addItem(id, name, price)  // id = 42 (Number), name = "Widget" (String)
}
```

Keyboard filters:

```html
<textarea data-action="keydown.ctrl+s->editor#save
                       keydown.meta+s->editor#save
                       keydown.esc->editor#cancel">
```

---

## Presenter Pattern

Plain Ruby classes in `app/models/` — no special directory, no inheritance:

```ruby
class Event::Description
  include ActionView::Helpers::TagHelper
  include ERB::Util

  def initialize(event, user) = @event, @user = event, user

  def to_html = to_sentence(creator_tag, card_title_tag).html_safe
  def to_plain_text = to_sentence(creator_name, quoted(card.title))

  private
    def creator_tag = tag.span(event.creator.name, class: "creator")
end
```

Factory method on the model keeps the API discoverable:

```ruby
# app/models/event.rb
def description_for(user) = Event::Description.new(self, user)
```

```erb
<%= event.description_for(Current.user).to_html %>
```

Controller concern for cross-controller instantiation:

```ruby
module FilterScoped
  extend ActiveSupport::Concern
  included do
    before_action :set_user_filtering
  end
  private
    def set_user_filtering
      @user_filtering = User::Filtering.new(Current.user, @filter, expanded: expanded_param)
    end
end
```
