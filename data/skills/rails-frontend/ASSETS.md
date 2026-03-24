# Assets — CSS, JS Bundling, Design Tokens

## CSS Architecture

**Pure custom CSS — no Tailwind, Bootstrap, or utility frameworks.** Built on modern CSS: custom properties, OKLCH colors, CSS layers, and logical properties.

### Layer Organization

```css
@layer reset;      /* Browser normalization */
@layer base;       /* Base element styles */
@layer components; /* Component-specific styles */
@layer modules;    /* Feature modules */
@layer utilities;  /* Utility classes */
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
└── [feature].css    # Feature-specific styles
```

---

## Design Tokens

### Colors — OKLCH

Use OKLCH for perceptual uniformity across light/dark modes. Always use semantic variables:

| Variable | Purpose |
|----------|---------|
| `--color-ink` | Primary text |
| `--color-ink-light` | Secondary text |
| `--color-canvas` | Background |
| `--color-link` | Interactive elements (blue) |
| `--color-positive` | Success (green) |
| `--color-negative` | Error (red) |

Dark mode via attribute and media query:

```css
html[data-theme="dark"] { ... }
@media (prefers-color-scheme: dark) { html:not([data-theme]) { ... } }
```

### Spacing — Logical Properties

Use `block` (vertical) and `inline` (horizontal) instead of top/bottom/left/right for RTL support:

```css
--inline-space: 1ch;
--block-space:  1rem;
```

Key utilities: `.pad`, `.pad-block`, `.pad-inline`, `.margin`, `.gap`, `.gap-half`

### Typography

```css
--font-sans: "Adwaita Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
--font-mono: ui-monospace, monospace;
```

Scale: `--text-xx-small` (0.55rem) through `--text-xx-large` (2.5rem). Always use `rem`, never `px` for font sizes.

---

## Icons

CSS mask-based icon system — icons inherit `currentColor`, easy to style contextually:

```erb
<%= icon_tag "check" %>
<%= icon_tag "pencil", class: "txt-subtle" %>
```

Generates: `<span class="icon icon--check" aria-hidden="true"></span>`

Icon-only buttons — use `aria-label` or `.for-screen-reader` for accessibility:

```erb
<%= button_to path, class: "btn", aria: { label: "Edit" } do %>
  <%= icon_tag "pencil" %>
<% end %>
```

New SVG requirements: `viewBox="0 0 24 24"`, no fixed `width`/`height`, `fill="currentColor"`, monochrome for mask-image compatibility.

---

## Component Patterns

### Buttons

```css
.btn                /* Base — rounded pill */
.btn--positive      /* Green */
.btn--negative      /* Red/destructive */
.btn--link          /* Text-only */
.btn--circle        /* Circular icon button */
```

### Inputs

All inputs use `font-size: max(16px, 1em)` to prevent iOS auto-zoom.

```erb
<%= form.text_field :name, class: "input" %>
<%= form.select :status, options, {}, class: "input input--select" %>
<%= form.text_area :body, class: "input input--textarea", rows: 1 %>
```

Auto-resizing textarea (modern browsers): `field-sizing: content`

### Focus & Motion

```css
--focus-ring: 2px solid var(--color-link);  /* Applied via :focus-visible */

@media (prefers-reduced-motion: reduce) {
  animation-duration: 0.01ms !important;
  transition-duration: 0.01ms !important;
}
```

Always respect `prefers-reduced-motion`. Always apply focus states on interactive elements.

---

## JS Bundling

Controllers are auto-discovered from `app/javascript/controllers/`. No manual registration.

Importmap (default) or esbuild depending on project setup. Third-party libraries bridged through Stimulus value callbacks — keep the controller as the integration boundary, not inline `<script>` tags.

---

## Rules

- Use semantic color variables, never hard-coded values
- Use logical properties (`block-start` not `top`, `inline-size` not `width`)
- Use CSS custom properties for component variants
- Use `clamp()` for fluid responsive values
- Test in both light and dark modes
- Never create z-index values without adding to the defined stack
