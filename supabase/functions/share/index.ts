// Supabase Edge Function: share
// Serves an Open Graph "unfurl" page for a tier list so links posted to chat/social
// (Messenger, iMessage, Slack, WhatsApp, etc.) show a preview card, then redirects
// real visitors to the app. Storage can't host active HTML (it's served as text/plain
// with a sandbox CSP), so this function returns the real text/html page.
//
// Deploy (must be public — no JWT):
//   Dashboard → Edge Functions → Deploy new function "share", paste this, turn
//   "Verify JWT" OFF.  OR via CLI:
//   supabase functions deploy share --no-verify-jwt --project-ref hizumyjjthjxahykrhpo
//
// URL: https://<project-ref>.supabase.co/functions/v1/share?id=<listId>

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const APP_URL = "https://threelephant.github.io/tier-list-maker/";

const esc = (s: unknown) =>
  String(s ?? "").replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c] as string));

Deno.serve(async (req) => {
  const url = new URL(req.url);
  let id = url.searchParams.get("id");
  if (!id) {
    const parts = url.pathname.split("/").filter(Boolean);
    const last = parts[parts.length - 1];
    if (last && last !== "share") id = last;
  }
  const appUrl = id ? `${APP_URL}#/b/${id}` : APP_URL;

  let title = "Tier List";
  let image = "";
  if (id) {
    try {
      const r = await fetch(
        `${SUPABASE_URL}/rest/v1/tier_lists?id=eq.${encodeURIComponent(id)}` +
          `&visibility=in.(public,shared)&select=name,owner`,
        { headers: { apikey: ANON, Authorization: `Bearer ${ANON}` } },
      );
      const rows = await r.json();
      if (Array.isArray(rows) && rows[0]) {
        title = rows[0].name || title;
        image = `${SUPABASE_URL}/storage/v1/object/public/tier-images/${rows[0].owner}/${id}/_preview.png`;
      }
    } catch (_e) { /* fall back to defaults */ }
  }

  const desc = "Open to view this tier list.";
  const imgTags = image
    ? `<meta property="og:image" content="${esc(image)}">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta name="twitter:image" content="${esc(image)}">`
    : "";

  const html = `<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)} — Tier List</title>
<meta property="og:type" content="website">
<meta property="og:site_name" content="Tier List Maker">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(desc)}">
${imgTags}
<meta property="og:url" content="${esc(appUrl)}">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${esc(title)}">
<meta name="twitter:description" content="${esc(desc)}">
<meta http-equiv="refresh" content="0; url=${esc(appUrl)}">
<script>location.replace(${JSON.stringify(appUrl)})</script>
</head><body style="background:#15161b;color:#e9eaed;font-family:-apple-system,Segoe UI,Roboto,sans-serif;text-align:center;padding:40px">
Redirecting to <a style="color:#6ea8fe" href="${esc(appUrl)}">${esc(title)}</a>…
</body></html>`;

  return new Response(html, {
    headers: { "content-type": "text/html; charset=utf-8", "cache-control": "public, max-age=300" },
  });
});
