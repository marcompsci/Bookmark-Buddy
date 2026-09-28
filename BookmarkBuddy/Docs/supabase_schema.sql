-- ============================================================
-- Bookmark Buddy — Supabase Database Schema
-- Copyright © 2026 Omari Bell. All rights reserved.
--
-- HOW TO USE:
-- 1. Go to https://app.supabase.com → your project → SQL Editor
-- 2. Paste this entire file and click Run
-- ============================================================

-- ── Profiles (one row per auth user) ─────────────────────────
create table public.profiles (
  id                  uuid references auth.users on delete cascade primary key,
  display_name        text not null,
  favorite_genres     text[]        default '{}',
  books_per_month     int           default 2,
  pace                text          default 'steady',
  spoiler_level       text          default 'currentChapter',
  current_streak_days int           default 0,
  squad_points        int           default 0,
  joined_squad_ids    uuid[]        default '{}',
  created_at          timestamptz   default now()
);
alter table public.profiles enable row level security;
create policy "Read own profile"   on public.profiles for select using (auth.uid() = id);
create policy "Insert own profile" on public.profiles for insert with check (auth.uid() = id);
create policy "Update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Delete own profile" on public.profiles for delete using (auth.uid() = id);

-- ── Books (seeded once, readable by all authenticated users) ──
create table public.books (
  id                   uuid primary key default gen_random_uuid(),
  title                text not null,
  author               text not null,
  genres               text[]      default '{}',
  page_count           int         not null,
  chapter_count        int         not null,
  premise              text        default '',
  cover_palette_index  int         default 0,
  cover_motif          text        default 'harbor',
  is_demo_content      bool        default true,
  created_at           timestamptz default now()
);
alter table public.books enable row level security;
create policy "Anyone authenticated can read books" on public.books
  for select using (auth.role() = 'authenticated');

-- ── Reading progress ──────────────────────────────────────────
create table public.reading_progress (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid references auth.users on delete cascade not null,
  book_id         uuid references public.books on delete cascade not null,
  state           text          default 'wantToRead',
  current_chapter int           default 1,
  pages_read      int           default 0,
  memory_strength double precision default 1.0,
  started_at      timestamptz,
  finished_at     timestamptz,
  updated_at      timestamptz   default now(),
  unique(user_id, book_id)
);
alter table public.reading_progress enable row level security;
create policy "Own progress only" on public.reading_progress
  for all using (auth.uid() = user_id);

-- ── Squads ────────────────────────────────────────────────────
create table public.squads (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  tagline        text default '',
  current_book_id uuid references public.books,
  created_by     uuid references auth.users,
  created_at     timestamptz default now()
);
alter table public.squads enable row level security;
create policy "Authenticated users can read squads" on public.squads
  for select using (auth.role() = 'authenticated');

-- ── Squad members ─────────────────────────────────────────────
create table public.squad_members (
  id             uuid primary key default gen_random_uuid(),
  squad_id       uuid references public.squads on delete cascade,
  user_id        uuid references auth.users on delete cascade,
  display_name   text not null,
  avatar_seed    int  default 0,
  weekly_points  int  default 0,
  current_chapter int,
  unique(squad_id, user_id)
);
alter table public.squad_members enable row level security;
create policy "Read own memberships" on public.squad_members
  for select using (auth.uid() = user_id);
create policy "Insert own membership" on public.squad_members
  for insert with check (auth.uid() = user_id);
create policy "Update own membership" on public.squad_members
  for update using (auth.uid() = user_id);

-- ── Reading events ────────────────────────────────────────────
create table public.reading_events (
  id               uuid primary key default gen_random_uuid(),
  squad_id         uuid references public.squads on delete cascade,
  event_type       text not null,
  title            text not null,
  starts_at        timestamptz not null,
  duration_minutes int         default 60,
  host_member_id   uuid        references auth.users,
  rsvp_member_ids  uuid[]      default '{}',
  book_id          uuid        references public.books,
  notes            text        default '',
  created_at       timestamptz default now()
);
alter table public.reading_events enable row level security;
create policy "Squad members can read events" on public.reading_events
  for select using (auth.role() = 'authenticated');
create policy "Authenticated users can create events" on public.reading_events
  for insert with check (auth.role() = 'authenticated');

-- ── Activity feed ─────────────────────────────────────────────
create table public.activity_feed (
  id             uuid primary key default gen_random_uuid(),
  squad_id       uuid references public.squads on delete cascade,
  member_id      uuid references auth.users,
  kind           text not null,
  message        text not null,
  timestamp      timestamptz default now(),
  reaction_count int         default 0
);
alter table public.activity_feed enable row level security;
create policy "Read squad activity" on public.activity_feed
  for select using (auth.role() = 'authenticated');
create policy "Post activity" on public.activity_feed
  for insert with check (auth.uid() = member_id);

-- ── Book notes ────────────────────────────────────────────────
create table public.book_notes (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users on delete cascade,
  book_id    uuid references public.books on delete cascade,
  chapter    int         default 1,
  text       text        not null,
  created_at timestamptz default now()
);
alter table public.book_notes enable row level security;
create policy "Own notes only" on public.book_notes for all using (auth.uid() = user_id);

-- ── Saved moments ─────────────────────────────────────────────
create table public.saved_moments (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references auth.users on delete cascade,
  book_id    uuid references public.books on delete cascade,
  chapter    int         not null,
  title      text        not null,
  reflection text        not null,
  created_at timestamptz default now()
);
alter table public.saved_moments enable row level security;
create policy "Own moments only" on public.saved_moments for all using (auth.uid() = user_id);

-- ── Buddy reads ───────────────────────────────────────────────
create table public.buddy_reads (
  id                  uuid primary key default gen_random_uuid(),
  book_id             uuid references public.books on delete cascade,
  invited_member_ids  uuid[] default '{}',
  goal_date           timestamptz not null,
  spoiler_level       text        default 'currentChapter',
  created_at          timestamptz default now()
);
alter table public.buddy_reads enable row level security;
create policy "Invited members can read buddy reads" on public.buddy_reads
  for select using (auth.uid() = any(invited_member_ids));
create policy "Create buddy reads" on public.buddy_reads
  for insert with check (auth.role() = 'authenticated');

-- ── Privacy settings ──────────────────────────────────────────
create table public.privacy_settings (
  user_id                  uuid references auth.users on delete cascade primary key,
  notes_consent            text  default 'notAsked',
  reading_progress_visible bool  default true,
  notes_visible            bool  default false,
  updated_at               timestamptz default now()
);
alter table public.privacy_settings enable row level security;
create policy "Own privacy settings" on public.privacy_settings
  for all using (auth.uid() = user_id);

-- ── RPC: toggle reaction (server-side to prevent race conditions) ──
create or replace function toggle_reaction(item_id uuid)
returns setof activity_feed language plpgsql security definer as $$
declare
  cur_count int;
begin
  select reaction_count into cur_count from activity_feed where id = item_id;
  update activity_feed
    set reaction_count = case when cur_count = 0 then 1 else cur_count - 1 end
    where id = item_id;
  return query select * from activity_feed where id = item_id;
end;
$$;

-- ── RPC: award points (server-side — never trust the client for points) ──
create or replace function award_points(member_id uuid, points int)
returns void language plpgsql security definer as $$
begin
  update squad_members
    set weekly_points = weekly_points + points
    where user_id = member_id;
end;
$$;

-- ── RPC: set RSVP (atomic array update) ──────────────────────
create or replace function set_event_rsvp(event_id uuid, member_id uuid, attending bool)
returns setof reading_events language plpgsql security definer as $$
begin
  if attending then
    update reading_events
      set rsvp_member_ids = array_append(
            array_remove(rsvp_member_ids, member_id), member_id)
      where id = event_id;
  else
    update reading_events
      set rsvp_member_ids = array_remove(rsvp_member_ids, member_id)
      where id = event_id;
  end if;
  return query select * from reading_events where id = event_id;
end;
$$;
