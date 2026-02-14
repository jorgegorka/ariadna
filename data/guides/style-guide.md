# Fizzy Style Guide

This document defines the CSS architecture, design tokens, and styling conventions used throughout Fizzy.

## Overview

Fizzy uses **pure, custom CSS** with no external frameworks (no Tailwind, Bootstrap, etc.). The design system is built on modern CSS features including CSS custom properties, OKLCH colors, CSS layers, and logical properties.

## CSS Architecture

### Layer Organization

Styles are organized using CSS `@layer` rules for predictable specificity:

```css
@layer reset;      /* Browser normalization */
@layer base;       /* Base element styles */
@layer components; /* Component-specific styles */
@layer modules;    /* Feature modules */
@layer utilities;  /* Utility classes */
@layer native;     /* Native app overrides */
@layer platform;   /* Platform-specific styles */
```

### File Organization

```
app/assets/stylesheets/
├── _global.css      # Root variables and @layer definitions
├── base.css         # Base element styling
├── utilities.css    # Utility classes
├── buttons.css      # Button components
├── inputs.css       # Form inputs
├── cards.css        # Card components
├── layout.css       # Main layout
├── header.css       # Header component
├── dialog.css       # Dialogs/modals
├── animation.css    # Keyframes
└── [feature].css    # Feature-specific styles
```

---

## Color System

### OKLCH Color Model

Fizzy uses the OKLCH color space for better perceptual uniformity across light and dark modes. Colors are defined as lightness, chroma, and hue values:

```css
--lch-black: 0% 0 0
--lch-white: 100% 0 0
--color-ink: oklch(var(--lch-black))
```

### Semantic Colors

Use semantic color variables rather than raw values:

| Variable | Purpose |
|----------|---------|
| `--color-ink` | Primary text color |
| `--color-ink-light` | Secondary text |
| `--color-ink-lighter` | Tertiary/muted text |
| `--color-canvas` | Background color |
| `--color-link` | Interactive elements (blue) |
| `--color-positive` | Success states (green) |
| `--color-negative` | Error states (red) |
| `--color-highlight` | Emphasis/markers (yellow) |

### Color Palette

The palette includes 10 color families, each with 7 intensity levels:

- **Ink** (neutrals): `--lch-ink-1` through `--lch-ink-8`
- **Red, Yellow, Lime, Green, Aqua, Blue, Violet, Purple, Pink**: `--lch-[color]-1` through `--lch-[color]-7`

### Card Colors

Cards use 8 distinct colors for visual categorization:

```css
--color-card-1 through --color-card-8
--color-card-default
--color-card-complete
```

Card backgrounds use color mixing for subtlety:

```css
background: color-mix(in srgb, var(--card-color) 4%, var(--color-canvas));
```

---

## Typography

### Font Stack

```css
--font-sans: "Adwaita Sans", -apple-system, BlinkMacSystemFont, "Segoe UI",
             "Noto Sans", Helvetica, Arial, sans-serif,
             "Apple Color Emoji", "Segoe UI Emoji";
--font-serif: ui-serif, serif;
--font-mono: ui-monospace, monospace;
```

### Text Size Scale

| Variable | Desktop | Mobile |
|----------|---------|--------|
| `--text-xx-small` | 0.55rem | 0.65rem |
| `--text-x-small` | 0.75rem | 0.85rem |
| `--text-small` | 0.85rem | 0.95rem |
| `--text-normal` | 1rem | 1.1rem |
| `--text-medium` | 1.1rem | 1.2rem |
| `--text-large` | 1.5rem | 1.5rem |
| `--text-x-large` | 1.8rem | 1.8rem |
| `--text-xx-large` | 2.5rem | 2.5rem |

### Typography Utilities

```css
.txt-xx-small, .txt-x-small, .txt-small, .txt-normal, .txt-medium, .txt-large
.txt-ink, .txt-subtle, .txt-negative, .txt-positive, .txt-alert
.txt-tight-lines          /* Reduced line-height */
.font-weight-black        /* 900 */
.font-weight-normal       /* 400 */
```

### Font Rendering

Global settings for consistent rendering:

```css
-webkit-font-smoothing: antialiased;
-moz-osx-font-smoothing: grayscale;
text-rendering: optimizeLegibility;
line-height: 1.375;
```

---

## Spacing System

### Logical Properties

Fizzy uses CSS logical properties for RTL support. Use `block` (vertical) and `inline` (horizontal) instead of top/bottom/left/right.

### Base Spacing Variables

```css
--inline-space: 1ch;        /* Character width */
--inline-space-half: 0.5ch;
--inline-space-double: 2ch;

--block-space: 1rem;        /* Vertical rhythm */
--block-space-half: 0.5rem;
--block-space-double: 2rem;
```

### Padding Utilities

```css
.pad                    /* Full padding */
.pad-double             /* 2x padding */
.pad-block              /* Vertical only */
.pad-block-start        /* Top only */
.pad-block-end          /* Bottom only */
.pad-block-half         /* Half vertical */
.pad-inline             /* Horizontal only */
.pad-inline-start       /* Left only (LTR) */
.pad-inline-end         /* Right only (LTR) */
.pad-inline-half        /* Half horizontal */
.unpad, .unpad-block-end, .unpad-inline
```

### Margin Utilities

```css
.margin, .margin-block, .margin-inline
.margin-block-start, .margin-block-end
.margin-block-half, .margin-block-double
.margin-inline-start, .margin-inline-end
.center                 /* margin-inline: auto */
.margin-none, .margin-block-none, .margin-inline-none
```

### Layout Spacing

```css
--main-padding: clamp(1ch, 3vw, 3ch);
--main-width: 1400px;
```

---

## Components

### Buttons

Buttons use CSS custom properties for variants:

```css
.btn {
  --btn-background: var(--color-canvas);
  --btn-border-color: var(--color-ink-lighter);
  --btn-color: inherit;
  --btn-padding: 0.5em 1.25em;
  --btn-font-weight: 500;
  --btn-border-radius: 99rem;
}
```

**Variants:**

| Class | Purpose |
|-------|---------|
| `.btn--link` | Text-only, no background |
| `.btn--plain` | Minimal styling |
| `.btn--circle` | Circular icon button |
| `.btn--negative` | Destructive action (red) |
| `.btn--positive` | Affirmative action (green) |
| `.btn--reversed` | Inverted colors |
| `.btn--circle-mobile` | Circle on small screens |

**States:**
- Disabled: `opacity: 0.3; pointer-events: none`
- Loading: Animated spinner overlay on form submit

### Cards

```css
.card {
  --card-color: var(--color-card-default);
  --card-bg-color: color-mix(in srgb, var(--card-color) 4%, var(--color-canvas));
}

.card__header
.card__board
.card__id
```

### Dialogs

Dialogs use CSS transitions with `allow-discrete`:

```css
.dialog {
  --dialog-duration: 150ms;
  /* Scale from 0.2 to 1 with opacity */
}
```

---

## Icons & SVG

Fizzy uses a **CSS mask-based icon system** with individual SVG files. Icons inherit color from their parent via `currentColor`, making them easy to style contextually.

### Icon Storage

All icons are stored as individual SVG files in `app/assets/images/`:

```
app/assets/images/
├── add.svg
├── check.svg
├── bell.svg
├── bell-alert.svg
├── bell-off.svg
├── bookmark.svg
├── bookmark-outline.svg
├── boost-color.svg      # Special colored variant
└── ... (84 total icons)
```

### Naming Conventions

| Pattern | Example | Purpose |
|---------|---------|---------|
| `name.svg` | `check.svg` | Standard icon |
| `name-variant.svg` | `bell-alert.svg` | State variant |
| `name-outline.svg` | `bookmark-outline.svg` | Outline style |
| `name--meta.svg` | `add--meta.svg` | Metadata context |
| `name-color.svg` | `boost-color.svg` | Multi-color icon |

### Icon Helper

Use the `icon_tag` helper to render icons:

```erb
<%# Basic usage %>
<%= icon_tag "check" %>

<%# With custom classes %>
<%= icon_tag "pencil", class: "txt-subtle" %>

<%# In a button with screen reader text %>
<%= button_to path, class: "btn" do %>
  <%= icon_tag "trash" %>
  <span class="for-screen-reader">Delete item</span>
<% end %>
```

The helper generates:

```html
<span class="icon icon--check" aria-hidden="true"></span>
```

### How It Works

Icons use CSS `mask-image` with `currentColor` for flexible styling:

```css
.icon {
  background-color: currentColor;
  block-size: var(--icon-size, 1em);
  inline-size: var(--icon-size, 1em);
  mask-image: var(--svg);
  mask-position: center;
  mask-repeat: no-repeat;
  mask-size: var(--icon-size, 1em);
}

.icon--check {
  --svg: url("check.svg");
}
```

### Icon Sizing

Control size via the `--icon-size` custom property:

| Context | Size | Variable |
|---------|------|----------|
| Default | `1em` | `--icon-size: 1em` |
| Buttons | `1.3em` | `--btn-icon-size: 1.3em` |
| Header buttons | `1rem` | `--btn-icon-size: 1rem` |
| Popups | `24px` | `--popup-icon-size: 24px` |
| Navigation | `2em` | `--icon-size: 2em` |
| Card metadata | `0.9em` | `--icon-size: 0.9em` |
| Reactions | `1.3em` | `--btn-icon-size: 1.3em` |

### Icon Colors

Icons inherit `currentColor` by default. Override contextually:

```css
/* Inherits parent text color */
.icon {
  background-color: currentColor;
}

/* Context-specific coloring */
.event-icon .icon {
  background-color: var(--card-color);
}

/* Attachment type colors */
.attachment--red { --attachment-icon-color: oklch(var(--lch-red-medium)); }
.attachment--blue { --attachment-icon-color: oklch(var(--lch-blue-medium)); }
```

### Icon Buttons

Icon-only buttons automatically adjust sizing:

```css
/* Buttons with only an icon (detected via aria-label or .for-screen-reader) */
.btn[aria-label]:where(:has(.icon)),
.btn:where(:has(.for-screen-reader):has(.icon)) {
  --btn-padding: 0;
  --icon-size: 75%;
  aspect-ratio: 1;
  display: grid;
  place-items: center;
}
```

Usage pattern:

```erb
<%# Icon button with accessible label %>
<%= button_to path, class: "btn", aria: { label: "Edit" } do %>
  <%= icon_tag "pencil" %>
<% end %>

<%# Or with screen reader text %>
<%= button_to path, class: "btn" do %>
  <%= icon_tag "pencil" %>
  <span class="for-screen-reader">Edit</span>
<% end %>
```

### Icon Animations

Icons support animations, particularly in success states:

```css
@keyframes zoom-fade {
  100% {
    transform: translateY(-1.5em);
    scale: 2;
    opacity: 0;
  }
}

.btn--success .icon {
  animation: zoom-fade 500ms cubic-bezier(0.25, 1.25, 0.5, 1);
}
```

### Multi-Color Icons

For icons requiring multiple colors (not mask-compatible), use `image_tag`:

```erb
<%# Colored icon (not masked) %>
<%= image_tag "boost-color.svg", aria: { hidden: true }, class: "icon" %>
```

### SVG File Requirements

When creating new icons:

1. **ViewBox**: Use `viewBox="0 0 24 24"` or `viewBox="0 0 32 32"`
2. **No fixed dimensions**: Omit `width` and `height` attributes
3. **Fill**: Use `fill="currentColor"` or no fill (for mask compatibility)
4. **Single color**: Icons should be monochrome for mask-image to work
5. **Optimized**: Remove unnecessary metadata and groups

Example SVG structure:

```xml
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2L2 7l10 5 10-5-10-5z"/>
</svg>
```

### Available Icons

Common icons organized by category:

**Navigation:**
`arrow-left`, `arrow-right`, `arrow-up`, `chevron`, `caret-down`, `expand`, `collapse`

**Actions:**
`add`, `remove`, `close`, `check`, `pencil`, `copy-paste`, `trash`, `bookmark`, `pin`

**Status:**
`bell`, `bell-alert`, `bell-off`, `check-circle`, `close-circle`, `assigned`

**UI Elements:**
`menu-dots-horizontal`, `menu-dots-vertical`, `search`, `filter`, `sliders`

**Entities:**
`person`, `person-add`, `board`, `column-left`, `column-right`

**Application:**
`fizzy`, `boost`, `boost-color`, `golden-ticket`

---

## Forms & Inputs

Fizzy uses CSS custom properties for flexible, themeable form controls. All inputs prevent iOS auto-zoom with `font-size: max(16px, 1em)`.

### Base Input Styling

```css
.input {
  --input-accent-color: var(--color-ink);
  --input-background: transparent;
  --input-border-radius: 0.5em;
  --input-border-color: var(--color-ink-medium);
  --input-border-size: 1px;
  --input-color: var(--color-ink);
  --input-padding: 0.5em 0.8em;

  font-size: max(16px, 1em);  /* Prevents iOS zoom */
  inline-size: 100%;
  resize: none;
}
```

### Input Variants

#### Text Input

Basic text input with full width:

```erb
<%= form.text_field :name, class: "input", placeholder: "Enter name..." %>
```

#### Actor Input Pattern

Wraps inputs in a label that acts as the visual input container, providing larger touch targets:

```erb
<label class="flex align-center gap input input--actor">
  <%= icon_tag "search" %>
  <%= form.text_field :query, class: "input full-width", placeholder: "Search..." %>
</label>
```

```css
.input--actor {
  &:focus-within {
    --input-border-color: var(--color-selected-dark);
    outline: var(--focus-ring-size) solid var(--focus-ring-color);
  }

  .input {
    --input-padding: 0;
    --input-border-size: 0;
    --input-background: transparent;
  }
}
```

#### Select Dropdown

Custom styled select with SVG caret:

```erb
<%= form.select :status, options, {}, class: "input input--select" %>
```

```css
.input--select {
  --input-border-radius: 2em;
  --input-padding: 0.5em 1.8em 0.5em 1.2em;
  appearance: none;
  background-image: url("caret-down.svg");
  background-position: right 0.5em center;
  background-repeat: no-repeat;
  background-size: 1em;
}
```

#### Textarea

Auto-resizing textarea using `field-sizing: content`:

```erb
<%= form.text_area :description, class: "input input--textarea", rows: 1 %>
```

```css
.input--textarea {
  min-block-size: calc(3lh + (2 * var(--input-padding)));

  @supports (field-sizing: content) {
    field-sizing: content;
    max-block-size: calc(3lh + (2 * var(--input-padding)));
    min-block-size: calc(1lh + (2 * var(--input-padding)));
  }
}
```

#### File Input

Hidden file input with custom button overlay:

```erb
<label class="btn input--file">
  <%= icon_tag "upload" %>
  <span>Choose file</span>
  <%= form.file_field :attachment, class: "input", accept: "image/*" %>
</label>
```

```css
.input--file {
  cursor: pointer;
  display: grid;
  place-items: center;

  input[type="file"] {
    cursor: pointer;
    font-size: 0;
    inset: 0;
    opacity: 0;
    position: absolute;

    &::file-selector-button {
      appearance: none;
      cursor: pointer;
      opacity: 0;
    }
  }
}
```

#### Number Input (Inline)

Minimal inline number input that sizes to content:

```erb
<%= form.number_field :quantity, class: "input boost__input", min: 1 %>
```

```css
.input.boost__input {
  --input-border-size: 0;
  --input-padding: 0;
  inline-size: min-content;

  @supports (field-sizing: content) {
    field-sizing: content;
  }

  &:focus {
    background-color: var(--color-highlight);
  }
}
```

#### One-Time Code Input

Styled for OTP/verification codes:

```erb
<%= form.text_field :code, class: "input", autocomplete: "one-time-code" %>
```

```css
.input[autocomplete='one-time-code'] {
  font-family: var(--font-mono);
  font-size: var(--text-large);
  font-weight: 900;
  inline-size: 18ch;
  letter-spacing: 1ch;
  text-align: center;
}
```

### Switch/Toggle

Binary toggle switch component:

```erb
<label class="switch">
  <%= form.check_box :enabled, class: "switch__input" %>
  <span class="switch__btn"></span>
  <span class="for-screen-reader">Enable feature</span>
</label>
```

```css
.switch {
  --switch-color: var(--color-ink-medium);
  block-size: 1.75em;
  inline-size: 3em;
  border-radius: 2em;
}

.switch__btn {
  background-color: var(--switch-color);
  transition: 150ms ease;

  &::before {  /* The toggle dot */
    background-color: var(--color-ink-inverted);
    block-size: 1.35em;
    border-radius: 50%;
    transition: 150ms ease;
  }
}

.switch__input:checked + .switch__btn {
  --switch-color: var(--color-link);

  &::before {
    transform: translateX(1.2em);
  }
}

.switch__input:disabled + .switch__btn {
  cursor: not-allowed;
  opacity: 0.5;
}
```

### Checkbox & Radio as Buttons

Style checkboxes/radios as toggle buttons:

```erb
<label class="btn">
  <%= form.radio_button :color, "red" %>
  Red
</label>
```

```css
.btn:has(input[type=radio], input[type=checkbox]) {
  input {
    appearance: none;
    cursor: pointer;
    inset: 0;
    position: absolute;
  }

  &:has(input:checked) {
    --btn-background: var(--color-ink);
    --btn-color: var(--color-ink-inverted);
  }
}
```

### Input States

#### Focus State

Inputs use an internal focus ring (offset inside the border):

```css
.input {
  --focus-ring-offset: -1px;

  &:focus {
    outline: var(--focus-ring-size) solid var(--focus-ring-color);
    outline-offset: var(--focus-ring-offset);
  }
}
```

#### Disabled State

```css
.input:disabled {
  cursor: not-allowed;
  opacity: 0.5;
  pointer-events: none;
}
```

#### Readonly State

```css
.input[readonly] {
  --focus-ring-size: 0;
}
```

#### Autofill Styling

Override browser autofill colors:

```css
.input:autofill,
.input:-webkit-autofill {
  -webkit-text-fill-color: var(--color-ink);
  -webkit-box-shadow: 0 0 0px 1000px var(--color-selected) inset;
}
```

### Form Layout

Use flexbox utilities for form structure:

```erb
<%= form_with model: @user, class: "flex flex-column gap" do |form| %>
  <div class="flex flex-column gap-half">
    <label>Email</label>
    <%= form.email_field :email, class: "input" %>
  </div>

  <div class="flex flex-column gap-half">
    <label>Password</label>
    <%= form.password_field :password, class: "input" %>
  </div>

  <button type="submit" class="btn btn--positive">Save</button>
<% end %>
```

### Error Display

Display validation errors with semantic styling:

```erb
<% if @user.errors.any? %>
  <div class="txt-negative txt-small margin-block-half">
    <p class="font-weight-bold margin-block-none">Your changes couldn't be saved:</p>
    <ul class="margin-block-none">
      <% @user.errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  </div>
<% end %>
```

### Form Submission

#### Submit Button with Loading State

Forms with `aria-busy` show a spinner on disabled submit buttons:

```css
form[aria-busy] button:disabled {
  > * {
    visibility: hidden;
  }

  &::after {
    animation: submitting 1s infinite linear;
    /* Spinner overlay */
  }
}
```

#### Auto-Submit Forms

Use the `auto_submit_form_with` helper for forms that submit on change:

```erb
<%= auto_submit_form_with model: @settings do |form| %>
  <%= form.select :theme, options, {},
        class: "input input--select",
        data: { action: "change->form#submit" } %>
<% end %>
```

### Form Custom Properties Reference

| Property | Default | Purpose |
|----------|---------|---------|
| `--input-accent-color` | `var(--color-ink)` | Checkbox/radio accent |
| `--input-background` | `transparent` | Input background |
| `--input-border-radius` | `0.5em` | Corner radius |
| `--input-border-color` | `var(--color-ink-medium)` | Border color |
| `--input-border-size` | `1px` | Border width |
| `--input-color` | `var(--color-ink)` | Text color |
| `--input-padding` | `0.5em 0.8em` | Internal padding |
| `--switch-color` | `var(--color-ink-medium)` | Switch track color |

---

## Layout

### Grid-Based Header

```css
.header {
  display: grid;
  grid-template-columns: var(--actions-start-size) 1fr var(--actions-end-size);
}

.header--mobile-actions-stack  /* Stacked on mobile */
```

### Main Content

```css
body {
  display: grid;
  grid-template-rows: auto 1fr auto 9em;
}

#main {
  inline-size: 100dvw;
  max-inline-size: var(--main-width);
}
```

### Flexbox Utilities

```css
.flex, .flex-inline, .flex-column, .flex-wrap
.flex-1, .flex-item-grow, .flex-item-shrink, .flex-item-no-shrink
.gap, .gap-half, .gap-none
.justify-start, .justify-end, .justify-center, .justify-space-between
.align-start, .align-end, .align-center
```

### Sizing Utilities

```css
.full-width, .max-width, .half-width
.min-width, .min-content, .fit-content
.overflow-x, .overflow-y
.overflow-ellipsis
.overflow-line-clamp  /* Use with --lines custom property */
```

---

## Dark Mode

Dark mode is supported via theme attribute and system preference:

```css
/* User-selected theme */
html[data-theme="dark"] { ... }

/* System preference fallback */
@media (prefers-color-scheme: dark) {
  html:not([data-theme]) { ... }
}
```

Dark mode adjustments include:
- Complete OKLCH palette redefinition
- Enhanced layered shadows (6 layers vs 4)
- Adjusted contrast ratios

---

## Borders & Shadows

### Borders

```css
--border-color: var(--color-ink-lighter);

.border              /* 1px solid */
.border-block        /* Top and bottom */
.border-top, .border-bottom
.borderless
.border-radius       /* Uses --border-radius, default 0.5em */
```

### Shadows

```css
--shadow:
  0 0 0 1px oklch(var(--lch-black) / 5%),
  0 0.2em 0.2em oklch(var(--lch-black) / 5%),
  0 0.4em 0.4em oklch(var(--lch-black) / 5%),
  0 0.8em 0.8em oklch(var(--lch-black) / 5%);

.shadow  /* Applies the layered shadow */
```

---

## Animations

### Easing Functions

```css
--ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
--ease-out-overshoot: cubic-bezier(0.25, 1.75, 0.5, 1);
--ease-out-overshoot-subtle: cubic-bezier(0.25, 1.25, 0.5, 1);
```

### Default Transitions

```css
transition: 100ms ease-out;
transition-property: background-color, border-color, box-shadow, filter, outline;
```

### Available Keyframes

| Animation | Purpose |
|-----------|---------|
| `shake` | Horizontal error shake |
| `react` | Scale up reaction |
| `scale-fade-out` | Shrink and fade |
| `slide-up`, `slide-down` | Vertical movement |
| `slide-up-fade-in` | Combined slide + fade |
| `pulse` | Opacity pulse |
| `submitting` | Spinner animation |
| `success` | Scale on success |
| `wiggle` | Rotation wiggle |

### Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  animation-duration: 0.01ms !important;
  transition-duration: 0.01ms !important;
}
```

---

## Focus States

### Focus Ring

```css
--focus-ring-color: var(--color-link);
--focus-ring-offset: 1px;
--focus-ring-size: 2px;
--focus-ring: 2px solid var(--color-link);
```

Applied via `:focus-visible` for keyboard-only styling on all interactive elements.

---

## Z-Index Stack

| Variable | Value | Purpose |
|----------|-------|---------|
| `--z-events-column-header` | 1 | Column headers |
| `--z-events-day-header` | 3 | Day headers |
| `--z-popup` | 10 | Popups/dropdowns |
| `--z-nav` | 20 | Navigation |
| `--z-flash` | 30 | Flash messages |
| `--z-tooltip` | 40 | Tooltips |
| `--z-bar` | 50 | Action bars |
| `--z-tray` | 51 | Side trays |
| `--z-welcome` | 52 | Welcome overlay |
| `--z-nav-open` | 100 | Open navigation |

---

## Accessibility

### Visibility Utilities

```css
.visually-hidden, .for-screen-reader  /* Screen reader only */
[hidden]                               /* Display none */
.display-contents                      /* Remove wrapper */
```

### Responsive Visibility

```css
.hide-on-touch      /* Hidden on touch devices */
.show-on-touch      /* Visible only on touch */
.show-on-native     /* Native app only */
.hide-in-pwa        /* Hidden in PWA mode */
.hide-in-browser    /* Hidden in browser */
```

---

## Responsive Design

### Breakpoints

- **Small**: < 640px (mobile)
- **Medium**: 640px - 800px (tablet)
- **Large**: > 800px (desktop)

### Approach

Mobile-first with `max-width` queries for larger screens. Use `clamp()` for fluid sizing:

```css
--main-padding: clamp(1ch, 3vw, 3ch);
font-size: clamp(0.85rem, 2vw, 1rem);
```

### Safe Area Insets

Support for notched devices:

```css
padding-inline: calc(var(--main-padding) + env(safe-area-inset-left));
padding-block-start: calc(var(--block-space-half) + env(safe-area-inset-top));
```

---

## Best Practices

### Do

- Use semantic color variables (`--color-ink`, `--color-link`)
- Use logical properties (`block-start` instead of `top`)
- Use CSS custom properties for component variants
- Use `clamp()` for fluid responsive values
- Test in both light and dark modes
- Respect `prefers-reduced-motion`

### Don't

- Hard-code color values (use variables)
- Use physical properties when logical work
- Create new z-index values without adding to the stack
- Skip focus states on interactive elements
- Use `px` for font sizes (use `rem`)

### Adding New Styles

1. Check if an existing utility class serves the purpose
2. Use CSS custom properties for configurable values
3. Place styles in the appropriate layer
4. Ensure dark mode compatibility
5. Test with reduced motion preferences
