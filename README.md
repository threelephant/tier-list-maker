# Tier List Maker

A classic tier-list maker in a single, self-contained `index.html` — no backend, no build step, no dependencies. Open the file directly or use the hosted version.

**Live:** https://threelephant.github.io/tier-list-maker/

## Features
- **Accounts + sharing (optional)** — sign in with Google to sync your lists to the cloud (Supabase); make any list **public** and share it with a link (others see a read-only view). Signed out, everything still works locally.
- **Multiple tier lists** — a menu home page to create, open, rename, duplicate, and delete lists, each with a live preview.
- Add images by **paste** (`⌘V` / `Ctrl V`), **drag-and-drop** of image files, or the **+ Add items** button. Images are auto-downscaled to keep things fast.
- Classic **S / A / B / C / D / F** tiers — rename, recolor (color picker), reorder, add, or delete (deleted tiers' items return to the *Unranked* tray, never lost).
- Drag items between tiers and reorder within a tier.
- Each item has a **name** (shown as a caption) and an optional **description** (shown on hover).
- **Export PNG** (rendered natively, no library) per list, plus **Export JSON** / **Import list** (a JSON file becomes a new list) for backup and sharing.
- Auto-saved in your browser via **IndexedDB** — all your lists persist across reloads.

## Cloud setup (Supabase)
Sign-in and sharing are backed by Supabase. To self-host: create a Supabase project, run [supabase/schema.sql](supabase/schema.sql) in the SQL Editor (creates the tables, RLS policies, and the `tier-images` Storage bucket), enable the Google auth provider, add your app URL to the allowed Redirect URLs, then set `SUPABASE_URL` / `SUPABASE_ANON_KEY` near the top of the `<script>` in `index.html`. The anon (publishable) key is safe to commit — row-level security is the access boundary.

## Notes
Signed out, lists live only in this browser (IndexedDB). To share without an account, use **Export JSON** (re-importable) or **Export PNG** (image). Signed in, lists sync to your account and public lists are shareable by link.
