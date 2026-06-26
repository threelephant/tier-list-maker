# DESIGN.md

The design system for the Tier List Maker. All values below are extracted from the single `<style>` block and the `DEFAULT_TIERS` array in [`index.html`](index.html) — that file is the source of truth; this document describes it. When you change a token or add a reusable pattern, update both.

## Principles

- **Dark theme only.** No light mode, no theme toggle.
- **Single file.** Every style lives in the one `<style>` block in `index.html`. No external stylesheet, no CSS framework, no preprocessor.
- **Use the CSS variables — never hardcode the hex values below.** They're defined once in `:root`.
- **System fonts, emoji icons.** No web fonts and no icon library are loaded.

## Color tokens (`:root`)

| Variable | Value | Use |
| --- | --- | --- |
| `--bg` | `#15161b` | Page background (also the `theme-color` meta) |
| `--panel` | `#1f2128` | Panel / card / modal background |
| `--panel-2` | `#262934` | Secondary surface, default button background |
| `--line` | `#33363f` | Borders and dividers |
| `--text` | `#e9eaed` | Primary text |
| `--muted` | `#9aa0ac` | Secondary text, labels |
| `--accent` | `#6ea8fe` | Primary accent (blue) — primary buttons, links, focus, drag highlight |
| `--danger` | `#ff6b6b` | Destructive actions (red) |

Note: primary buttons pair `--accent` with dark text `#0b1730` for contrast.

## Tier palette (`DEFAULT_TIERS`)

The default ranks form a red→green ramp. These are per-list defaults — users can recolor any tier with the color picker.

| Tier | Color |
| --- | --- |
| S | `#ff7f7f` |
| A | `#ffbf7f` |
| B | `#ffdf7f` |
| C | `#ffff7f` |
| D | `#bfff7f` |
| F | `#7fff7f` |

The favicon is an inline SVG data-URI of four of these bars (S/A/B/F) on a `--bg` rounded square.

## Typography

System stack, antialiased:

```
-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif
```

- **Weights:** 300 (the add-tile `+`), 600 (buttons, field labels), 700 (header, names, modal titles), 800 (tier labels, item monograms).
- **Size scale:** 22px tier label · 17px header title · 14px card name / inputs · 13px buttons · 12px metadata & section labels · 10–11px mini-preview text.

## Spacing & shape

- `--cell: 92px` — the item tile size (width and base height). Dropzones/tiers use `min-height: calc(var(--cell) + 24px)`.
- `--radius: 10px` — panels, tiers, the main rounded surfaces.
- Other radii: `8px` (buttons, inputs, cards), `14px` (modals).
- Gaps: `12px` (header), `8px` (between tiers), `6px` (between items).
- `main` is capped at `max-width: 1200px` and centered.

## Elevation

- `--shadow: 0 2px 8px rgba(0,0,0,.35)` — standard card/panel shadow; intensifies on hover/active.
- The sticky header uses `backdrop-filter: blur(8px)` over `rgba(21,22,27,.85)`.

## Components

- **Header** — sticky toolbar, `z-index: 20`, blurred translucent background; logo + breadcrumb + actions + auth area, flex-wrap so it collapses on narrow screens.
- **Board → Tier** — `.tier` is a flex row: `.tier-label` (fixed ~96px, editable, color picker on hover) + `.dropzone` (flex-wrap, the rank's items) + `.tier-controls` (up / down / delete).
- **Card (item)** — `.card` at `--cell` width; an `<img>` or a `.stub` monogram fallback (deterministic HSL from the name) plus a `.cap` caption. Hover lifts it; a `.del` button appears top-right.
- **Pool** — the "unranked" panel with a `.pool-head` label and its own dropzone.
- **Modal** — `.overlay` (fixed, `rgba(0,0,0,.55)`, `z-index: 50`) holds a `.modal` (max-width `380px`, `--panel`, radius `14px`).
- **Buttons** — `.btn` base; variants `.primary` (accent fill, dark text), `.ghost` (transparent), `.danger` (red hover), `.small` (compact).
- **Menu grid** — `.list-card`s in a responsive grid: `repeat(auto-fill, minmax(250px, 1fr))`, gap `16px`. Each card shows a mini multi-tier preview, metadata, and hover actions (edit / duplicate / delete).
- **Toasts** — `#toasts` fixed bottom-center, `z-index: 80`; `.toast.err` is red. Pop-in animation.

## Drag & drop visuals

- `.dropzone.drag-over` — subtle blue tint (`rgba(110,168,254,.10)`) plus an inset accent ring.
- `.card.placeholder` — dashed outline marking the drop position.
- `.card.drag-ghost` — the floating element during touch drag, `z-index: 1000`, slightly scaled.
- Desktop uses HTML5 drag events; mobile uses long-press + touch-move handlers.

## Z-index ladder

`20` header · `50` modal overlay · `60` user menu · `80` toasts · `1000` drag ghost.

## Responsive

No media queries. Responsiveness comes from flexbox + `flex-wrap`, the `auto-fill` menu grid, and `max-width` caps on `main` and modals.

## Iconography

Emoji / Unicode only — no icon library, no new asset dependencies:

🏆 logo · ← back · 👁 read-only · 🔒 private · 🌐 public · 🔗 shared · ▲ ▼ reorder · ✕ / × close/delete · ✎ edit · ⧉ duplicate · + add.
