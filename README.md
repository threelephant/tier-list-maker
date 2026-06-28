# Tier List Maker

A classic tier-list maker in a single, self-contained `index.html` — no backend, no build step, no dependencies. Open the file directly or use the hosted version.

**Live:** https://threelephant.github.io/tier-list-maker/

## Features
- **Accounts + sharing (optional)** — sign in with Google to sync your lists to the cloud (Supabase); make any list **public** or **shared** and send the link (others see a read-only view). Links unfurl into a branded preview card when posted to chat/social. Signed out, everything still works locally.
- **Multiple tier lists** — a menu home page to create, open, rename, duplicate, and delete lists, each with a live preview.
- Add images by **paste** (`⌘V` / `Ctrl V`), **drag-and-drop** of image files, or the **+ Add items** button. Images are auto-downscaled to keep things fast.
- Classic **S / A / B / C / D / F** tiers — rename, recolor (color picker), reorder, add, or delete (deleted tiers' items return to the *Unranked* tray, never lost).
- Drag items between tiers and reorder within a tier.
- Each item has a **name** (shown as a caption) and an optional **description** (shown on hover).
- **Quick-fill from a topic** — pick a topic and the app builds a ready-to-copy prompt for your chatbot of choice (ChatGPT, Claude, Gemini…); paste the JSON it returns and the items drop straight into a new list as monogram tiles. No API key, no server.
- **Export PNG** (rendered natively, no library) per list, plus **Export JSON** / **Import list** (a JSON file becomes a new list) for backup and sharing.
- Auto-saved in your browser via **IndexedDB** — all your lists persist across reloads.

## Cloud setup (Supabase)
Sign-in and sharing are backed by Supabase. To self-host: create a Supabase project, run [supabase/schema.sql](supabase/schema.sql) in the SQL Editor (creates the tables, RLS policies, and the `tier-images` Storage bucket), enable the Google auth provider, add your app URL to the allowed Redirect URLs, then set `SUPABASE_URL` / `SUPABASE_ANON_KEY` near the top of the `<script>` in `index.html`. The anon (publishable) key is safe to commit — row-level security is the access boundary.

**Link previews** are static Open Graph tags in `index.html` pointing at `og.png` — so any shared link unfurls into one branded card. (Per-list preview images aren't possible here: the app is hash-routed on a static host, so the `#/b/<id>` fragment never reaches a crawler, and Supabase neuters HTML on both Storage and Edge Functions — a per-list card would require hosting a tiny HTML endpoint on a third service like Cloudflare Workers or Deno Deploy.)

## Notes
Signed out, lists live only in this browser (IndexedDB). To share without an account, use **Export JSON** (re-importable) or **Export PNG** (image). Signed in, lists sync to your account and public lists are shareable by link.

## Privacy
Privacy-light analytics: the app records three anonymous counts — a list **created**, **shared**, or **exported** — each with only low-cardinality flags (local vs. cloud, share method, visibility, export format). No cookies, no identifier, no fingerprint, and no list, image, or account data is sent. Events are written (write-only — the client can't read them back) to a Supabase `events` table via a session-less anonymous client, so they're never tied to your Google account. Like any web request, Supabase's edge may log the request IP transiently — we never store or look at it.

Analytics is skipped automatically when your browser sends **Do-Not-Track** or **Global Privacy Control**. To opt out explicitly, run `localStorage.setItem("analytics:off","1")` in the browser console. Run [supabase/schema.sql](supabase/schema.sql) to create the `events` table when self-hosting.
