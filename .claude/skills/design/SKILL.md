---
name: design
description: Apply the rank-list design system when editing any UI, CSS, or component in index.html. Use when changing styles, colors, tiers, layout, modals, buttons, cards, or adding any visual element to the tier-list maker.
---

# Design system skill

This site's entire UI lives in the single `<style>` block and HTML of [`index.html`](../../../index.html). Before changing anything visual, read [`DESIGN.md`](../../../DESIGN.md) — it is the authoritative reference for tokens, the tier palette, typography, spacing, components, and the z-index ladder.

## Rules

- **Use the CSS variables, never hardcode hex.** Colors come from `--bg`, `--panel`, `--panel-2`, `--line`, `--text`, `--muted`, `--accent`, `--danger`. Sizing comes from `--cell`, `--radius`, `--shadow`.
- **Dark theme only.** Don't introduce a light theme or a theme toggle.
- **All styles go in the one `<style>` block** in `index.html` — no new stylesheet files, no CSS framework, no preprocessor.
- **Match existing class patterns** — reuse `.btn` (and `.primary` / `.ghost` / `.danger` / `.small`), `.card`, `.tier`, `.dropzone`, `.modal`, `.overlay`, `.toast` rather than inventing parallel ones.
- **Icons are emoji/Unicode** — no icon library, no web fonts, no new asset dependencies.
- **Respect the z-index ladder:** 20 header · 50 modal · 60 user menu · 80 toasts · 1000 drag ghost.
- **Keep tile/shape sizing on the tokens** — `--cell` for item tiles, `--radius` for surfaces; tiers/dropzones use `min-height: calc(var(--cell) + 24px)`.

## Keep docs in sync

When you change a token, the tier defaults, or add a reusable component/pattern, update [`DESIGN.md`](../../../DESIGN.md) in the same change so the doc and `index.html` don't drift.

## Verifying

There are no automated style tests. Run `python3 -m http.server 4178`, open `http://localhost:4178/`, and confirm the change visually (check both the menu grid and an open board, including a read-only/shared list if layout-related).
