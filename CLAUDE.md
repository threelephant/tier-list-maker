# CLAUDE.md

Project guide for working in this repo. For anything touching UI/CSS, also read [DESIGN.md](DESIGN.md).

## What this is

A classic **tier-list maker** web app. Users create lists, drag items (with images) into S/A/B/C/D/F ranks, and export/import them. Optional Google accounts add cloud sync and link sharing.

## Architecture

- **Single-file app.** The entire application — HTML structure, one `<style>` block, and all JS — lives in [`index.html`](index.html) (~2,600 lines). **No build step, no npm, no bundler.**
- **One external dependency:** Supabase JS v2, loaded from a CDN (`@supabase/supabase-js@2`).
- **Local persistence:** IndexedDB, database name `"tierlist"` (stores: `boards`, `app`, `state`). Works fully offline.
- **Cloud (optional):** Supabase — Postgres for list data, Storage for images, Google OAuth for auth. The publishable/anon key is in `index.html` on purpose; **RLS is the security boundary**, so it's safe to ship.

## Run it

```bash
python3 -m http.server 4178
```

Then open `http://localhost:4178/`. Port `4178` matches [`.claude/launch.json`](.claude/launch.json) and the Supabase OAuth redirect allow-list. There is **no test / lint / typecheck** step — it's vanilla JS, so verify changes in the browser.

## Key files

| Path | What |
| --- | --- |
| [`index.html`](index.html) | The whole app (HTML + CSS + JS) |
| [`supabase/schema.sql`](supabase/schema.sql) | Tables, RLS policies, triggers, Storage bucket — idempotent, re-runnable |
| [`DESIGN.md`](DESIGN.md) | Design system — read before any UI/CSS change |
| [`README.md`](README.md) | Setup + feature overview |
| `og.png` | Static 1200×630 link-preview card |

## Code map inside `index.html`

Three regions: the CSS `<style>` block, the HTML views (`#menuView` home grid, `#boardView` editor, plus `#syncOverlay` / `#editorOverlay` / `#toasts`), and the JS grouped by feature with section-divider comments.

Core abstractions:

- A **board** is one tier list: `{ id, name, version, tiers, pool, items, createdAt, updatedAt }`. The cloud `data` JSONB column stores `{ tiers, pool, items }`.
- `state` — the currently-open board (`null` while on the menu).
- `localBackend` (IndexedDB) and `cloudBackend` (Supabase) share **one interface** (load / save / remove / fetchOne / process images); the app swaps between them by sign-in status.
- `render()` redraws from `state`; `persist()` saves locally; `flushSave()` is the debounced (~2s) cloud save; a `beforeunload` listener forces a final save.
- `route()` does hash routing: `#/` (menu) and `#/b/<listId>` (board).

## Naming conventions

- `byId(...)` — DOM lookups.
- `db*` (`dbGet`, `dbPut`, …) — IndexedDB wrappers.
- `ls*` (`lsPutBoard`, `lsDeleteBoard`) — local board ops.
- `cloud*` (`cloudBackend`, `cloudFetchOne`) — Supabase.
- camelCase throughout; feature sections marked with banner comments.

## Data model (Supabase)

- `public.profiles` — id, username, avatar_url. Auto-created on first Google sign-in via trigger. Readable by everyone; users update only their own.
- `public.tier_lists` — `visibility` is `private` | `public` (shown on owner's profile) | `shared` (link-only). `data` JSONB = `{ tiers, pool, items }`. Owners manage their own rows; `public`/`shared` rows are readable by anyone.
- `tier-images` Storage bucket — public read; authenticated writes are scoped to `<uid>/<listId>/<itemId>.png` (the first path segment must equal `auth.uid()`).

## Deploy

GitHub Pages → `https://threelephant.github.io/tier-list-maker/`. **To deploy, always push to `main`** — there is no separate build or release step; a push to `main` publishes the site. Because routing is hash-based, crawlers never see per-list content — **every shared link shows the same static `og.png`** card.

## Gotchas

- Most edits concentrate in the single large `index.html`; keep the existing section structure.
- Item images are downscaled to ~92px tiles via canvas before storage; data URLs during edit, uploaded to Supabase Storage on save.
- A `canEdit` flag gates all mutations — `public`/`shared` lists you don't own open read-only (edit controls hidden).
- Keep design tokens in sync with [DESIGN.md](DESIGN.md) when you change colors, spacing, or components.
