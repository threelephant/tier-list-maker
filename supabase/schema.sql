-- ============================================================
-- Tier List Maker — Supabase schema
-- ============================================================
-- HOW TO RUN: Supabase Dashboard → SQL Editor → New query →
-- paste this whole file → Run. Safe to re-run (idempotent) — also migrates
-- existing tables (column constraints are re-applied via ALTER, since a repeat
-- CREATE TABLE IF NOT EXISTS is a no-op once the table exists).
--
-- After running, also do (one-time):
--   1. Authentication → Providers → Google → enable (add a Google Cloud
--      OAuth client id + secret; callback URL is shown there:
--      https://hizumyjjthjxahykrhpo.supabase.co/auth/v1/callback).
--   2. Authentication → URL Configuration → Redirect URLs → add:
--        https://threelephant.github.io/tier-list-maker/
--        http://localhost:4178/
-- ============================================================

-- ---------- profiles ----------
create table if not exists public.profiles (
  id         uuid primary key references auth.users on delete cascade,
  username   text,
  avatar_url text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Profiles are viewable by everyone" on public.profiles;
create policy "Profiles are viewable by everyone"
  on public.profiles for select using (true);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles for insert with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

-- Auto-create a profile row when a new auth user signs up (Google name/avatar).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, username, avatar_url)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'name',
      new.raw_user_meta_data->>'full_name',
      split_part(coalesce(new.email, ''), '@', 1)
    ),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- tier_lists ----------
create table if not exists public.tier_lists (
  id         uuid primary key default gen_random_uuid(),
  owner      uuid not null references auth.users on delete cascade,
  name       text not null default 'Untitled list',
  visibility text not null default 'private' check (visibility in ('private','public','shared')),
  data       jsonb not null default '{}'::jsonb,   -- { tiers, pool, items } with image URLs
  position   integer not null default 0,           -- menu order
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Bring existing tables up to date: the CREATE TABLE above is skipped entirely
-- when the table already exists, so column-level constraint changes must be
-- re-applied explicitly here (e.g. adding 'shared' to the visibility values).
alter table public.tier_lists drop constraint if exists tier_lists_visibility_check;
alter table public.tier_lists
  add constraint tier_lists_visibility_check check (visibility in ('private','public','shared'));

create index if not exists tier_lists_owner_idx      on public.tier_lists (owner);
create index if not exists tier_lists_visibility_idx on public.tier_lists (visibility);

alter table public.tier_lists enable row level security;

-- Owners can do anything with their own lists.
drop policy if exists "Owners manage their lists" on public.tier_lists;
create policy "Owners manage their lists"
  on public.tier_lists for all
  using (auth.uid() = owner)
  with check (auth.uid() = owner);

-- Anyone (including anonymous) can READ a public OR shared list (for share links).
-- 'public' = also listed on the owner's home; 'shared' = link-only (not listed).
drop policy if exists "Public lists are readable by anyone" on public.tier_lists;
create policy "Public lists are readable by anyone"
  on public.tier_lists for select
  using (visibility in ('public', 'shared'));

-- keep updated_at fresh
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists tier_lists_touch_updated_at on public.tier_lists;
create trigger tier_lists_touch_updated_at
  before update on public.tier_lists
  for each row execute function public.touch_updated_at();

-- ---------- role grants ----------
-- RLS filters *rows*, but Postgres still needs table-level privileges granted
-- to the API roles. (Row access stays restricted by the policies above.)
grant usage on schema public to anon, authenticated;
grant select on public.profiles to anon, authenticated;
grant insert, update on public.profiles to authenticated;
grant select on public.tier_lists to anon, authenticated;
grant insert, update, delete on public.tier_lists to authenticated;

-- ---------- analytics: events ----------
-- Write-only, anonymous telemetry. No PII, no list ids, no client reads.
-- Abuse is bounded by fixed enum CHECKs + server-set timestamp.
create table if not exists public.events (
  id          bigint generated always as identity primary key,
  event       text not null check (event in ('list_created','list_shared','list_exported')),
  mode        text check (mode in ('local','cloud')),
  method      text check (method in ('link','visibility')),
  visibility  text check (visibility in ('public','shared')),
  format      text check (format in ('png','json')),
  received_at timestamptz not null default now()   -- server clock; client value ignored
);

create index if not exists events_event_received_idx on public.events (event, received_at);

alter table public.events enable row level security;

-- Anyone (anonymous included) may INSERT a telemetry row; the column CHECKs above
-- are the real guard. The with-check only blocks future-dated rows from skewing charts.
drop policy if exists "Anyone can insert events" on public.events;
create policy "Anyone can insert events"
  on public.events for insert
  with check (received_at <= now() + interval '1 minute');

grant insert on public.events to anon, authenticated;
-- deliberately NO select/update/delete grant: inspect via dashboard/service role only.

-- ---------- storage: tier-images bucket ----------
insert into storage.buckets (id, name, public)
values ('tier-images', 'tier-images', true)
on conflict (id) do nothing;

-- Public read of images (so public lists load for anyone).
drop policy if exists "tier-images public read" on storage.objects;
create policy "tier-images public read"
  on storage.objects for select
  using (bucket_id = 'tier-images');

-- Authenticated users may write/replace/delete only under their own uid/ prefix:
--   path layout: <auth.uid()>/<listId>/<itemId>.png
drop policy if exists "tier-images user insert" on storage.objects;
create policy "tier-images user insert"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'tier-images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "tier-images user update" on storage.objects;
create policy "tier-images user update"
  on storage.objects for update to authenticated
  using (bucket_id = 'tier-images' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "tier-images user delete" on storage.objects;
create policy "tier-images user delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'tier-images' and (storage.foldername(name))[1] = auth.uid()::text);
