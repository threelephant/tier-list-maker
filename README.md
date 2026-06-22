# Tier List Maker

A classic tier-list maker in a single, self-contained `index.html` — no backend, no build step, no dependencies. Open the file directly or use the hosted version.

**Live:** https://threelephant.github.io/tier-list-maker/

## Features
- Add images by **paste** (`⌘V` / `Ctrl V`), **drag-and-drop** of image files, or the **+ Add items** button. Images are auto-downscaled to keep things fast.
- Classic **S / A / B / C / D / F** tiers — rename, recolor (color picker), reorder, add, or delete (deleted tiers' items return to the *Unranked* tray, never lost).
- Drag items between tiers and reorder within a tier.
- Each item has a **name** (shown as a caption) and an optional **description** (shown on hover).
- **Export PNG** (rendered natively, no library) and **Export / Import JSON** for backup and sharing.
- Auto-saved in your browser via **IndexedDB** — your board persists across reloads.

## Notes
Storage is per-browser; nothing is shared server-side. To share a specific list, use **Export JSON** (re-importable) or **Export PNG** (image).
