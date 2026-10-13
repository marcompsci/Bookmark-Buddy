-- Bookmark Buddy · Phase 11 · Beta event logging
-- Run once in the Supabase SQL Editor. Safe to re-run.
--
-- The app inserts one row per meaningful moment (see Services/Analytics/Analytics.swift):
--   app_opened, onboarding_completed, book_started, first_run_completed,
--   reminder_scheduled, refresh_answered, notification_opened,
--   feedback_card_tapped, shelf_opened
-- Readers can only INSERT their own rows. Nobody can read them from the app;
-- you read them in the dashboard (Table Editor → events) or with the queries below.

create table if not exists public.events (
  id          bigint generated always as identity primary key,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name        text not null check (char_length(name) between 1 and 64),
  props       jsonb not null default '{}'::jsonb check (pg_column_size(props) < 2048),
  app_version text check (char_length(app_version) <= 32),
  created_at  timestamptz not null default now()
);

create index if not exists events_name_created_idx on public.events (name, created_at desc);
create index if not exists events_user_created_idx on public.events (user_id, created_at desc);

alter table public.events enable row level security;

drop policy if exists "events: insert own" on public.events;
create policy "events: insert own"
  on public.events for insert
  to authenticated
  with check (user_id = auth.uid());

-- No select/update/delete policies on purpose: the app can't read or change events.
-- Rows are removed automatically when an account is deleted (on delete cascade).

-- ─────────────────────────────────────────────────────────────
-- Handy queries (run in the SQL Editor; they use the dashboard's admin role)
-- ─────────────────────────────────────────────────────────────

-- Funnel: how many testers reached each step
-- select name, count(distinct user_id) as testers
-- from public.events
-- where name in ('onboarding_completed','book_started','reminder_scheduled','refresh_answered')
-- group by name order by testers desc;

-- Day-7 return: testers who opened the app 7+ days after their first open
-- with first_seen as (
--   select user_id, min(created_at) as first_at from public.events group by user_id
-- )
-- select count(*) filter (where exists (
--          select 1 from public.events e
--          where e.user_id = f.user_id and e.name = 'app_opened'
--            and e.created_at >= f.first_at + interval '7 days')) as returned_day7,
--        count(*) as total_testers
-- from first_seen f;

-- Answers by source (Today screen vs. straight from the notification)
-- select props->>'source' as source, props->>'correct' as correct, count(*)
-- from public.events where name = 'refresh_answered' group by 1, 2 order by 1, 2;
