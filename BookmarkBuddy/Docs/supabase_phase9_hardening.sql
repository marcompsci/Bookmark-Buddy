-- ============================================================
-- Bookmark Buddy — Phase 9 migration: production hardening,
-- moderation, account deletion, and Digital Library recommendations.
-- Copyright © 2026 Omari Bell. All rights reserved.
--
-- Run AFTER supabase_schema.sql. Safe to re-run.
-- ============================================================

-- ── Helper: squads I belong to (pin search_path) ─────────────
create or replace function public.get_my_squad_ids()
returns uuid[] language sql security definer stable
set search_path = public as $$
  select coalesce(array_agg(squad_id), '{}') from public.squad_members where user_id = auth.uid()
$$;

-- ── Events: only squad members can see / create; host must be you ──
drop policy if exists "Squad members can read events" on public.reading_events;
create policy "Squad members can read events" on public.reading_events
  for select using (squad_id = any(public.get_my_squad_ids()));
drop policy if exists "Authenticated users can create events" on public.reading_events;
drop policy if exists "Members create events as themselves" on public.reading_events;
create policy "Members create events as themselves" on public.reading_events
  for insert with check (host_member_id = auth.uid() and squad_id = any(public.get_my_squad_ids()));

-- ── Activity feed: only squad members read / post ─────────────
drop policy if exists "Read squad activity" on public.activity_feed;
create policy "Read squad activity" on public.activity_feed
  for select using (squad_id = any(public.get_my_squad_ids()));
drop policy if exists "Post activity" on public.activity_feed;
create policy "Post activity" on public.activity_feed
  for insert with check (auth.uid() = member_id and squad_id = any(public.get_my_squad_ids()));

-- ── Reactions: one per person per item (replaces the shared counter toggle) ──
create table if not exists public.activity_reactions (
  item_id    uuid references public.activity_feed on delete cascade,
  user_id    uuid references auth.users on delete cascade default auth.uid(),
  created_at timestamptz default now(),
  primary key (item_id, user_id)
);
alter table public.activity_reactions enable row level security;
drop policy if exists "Own reactions" on public.activity_reactions;
create policy "Own reactions" on public.activity_reactions for all using (auth.uid() = user_id);

create or replace function public.toggle_reaction(item_id uuid)
returns setof public.activity_feed language plpgsql security definer
set search_path = public as $$
declare
  target_squad uuid;
begin
  select squad_id into target_squad from activity_feed where id = toggle_reaction.item_id;
  if target_squad is null or not (target_squad = any(get_my_squad_ids())) then
    raise exception 'not allowed';
  end if;
  if exists (select 1 from activity_reactions r where r.item_id = toggle_reaction.item_id and r.user_id = auth.uid()) then
    delete from activity_reactions r where r.item_id = toggle_reaction.item_id and r.user_id = auth.uid();
  else
    insert into activity_reactions (item_id, user_id) values (toggle_reaction.item_id, auth.uid());
  end if;
  update activity_feed a
    set reaction_count = (select count(*) from activity_reactions r where r.item_id = a.id)
    where a.id = toggle_reaction.item_id;
  return query select * from activity_feed where id = toggle_reaction.item_id;
end;
$$;

-- ── Points: only for yourself, bounded per call and per day ──
create table if not exists public.points_ledger (
  id         bigint generated always as identity primary key,
  user_id    uuid references auth.users on delete cascade not null,
  points     int not null,
  created_at timestamptz default now()
);
alter table public.points_ledger enable row level security;
drop policy if exists "Read own points" on public.points_ledger;
create policy "Read own points" on public.points_ledger for select using (auth.uid() = user_id);

create or replace function public.award_points(member_id uuid, points int)
returns void language plpgsql security definer
set search_path = public as $$
declare
  today_total int;
begin
  if auth.uid() is null or member_id <> auth.uid() then
    raise exception 'points can only be awarded to yourself';
  end if;
  if points < 1 or points > 100 then
    raise exception 'points out of range';
  end if;
  select coalesce(sum(l.points), 0) into today_total from points_ledger l
    where l.user_id = auth.uid() and l.created_at > now() - interval '1 day';
  if today_total + points > 500 then
    raise exception 'daily points limit reached';
  end if;
  insert into points_ledger (user_id, points) values (auth.uid(), points);
  perform set_config('bb.allow_points', 'on', true);
  update squad_members set weekly_points = weekly_points + points where user_id = auth.uid();
end;
$$;

-- Members can't edit their own points directly anymore.
drop policy if exists "Update own membership" on public.squad_members;
create policy "Update own membership" on public.squad_members
  for update using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
-- weekly_points may only change inside award_points().
create or replace function public.guard_weekly_points()
returns trigger language plpgsql
set search_path = public as $$
begin
  if new.weekly_points is distinct from old.weekly_points
     and coalesce(current_setting('bb.allow_points', true), '') <> 'on' then
    raise exception 'points can only change through award_points';
  end if;
  return new;
end;
$$;
drop trigger if exists squad_members_guard_points on public.squad_members;
create trigger squad_members_guard_points before update on public.squad_members
  for each row execute function public.guard_weekly_points();

-- ── RSVP: only for yourself, only in your squads ──
create or replace function public.set_event_rsvp(event_id uuid, member_id uuid, attending bool)
returns setof public.reading_events language plpgsql security definer
set search_path = public as $$
begin
  if auth.uid() is null or member_id <> auth.uid() then
    raise exception 'you can only RSVP for yourself';
  end if;
  if not exists (select 1 from reading_events e where e.id = event_id and e.squad_id = any(get_my_squad_ids())) then
    raise exception 'not allowed';
  end if;
  if attending then
    update reading_events
      set rsvp_member_ids = array_append(array_remove(rsvp_member_ids, member_id), member_id)
      where id = event_id;
  else
    update reading_events
      set rsvp_member_ids = array_remove(rsvp_member_ids, member_id)
      where id = event_id;
  end if;
  return query select * from reading_events where id = event_id;
end;
$$;

-- ── Buddy reads: record the creator ──
alter table public.buddy_reads add column if not exists created_by uuid references auth.users on delete cascade default auth.uid();
drop policy if exists "Invited members can read buddy reads" on public.buddy_reads;
create policy "Invited members can read buddy reads" on public.buddy_reads
  for select using (auth.uid() = any(invited_member_ids) or auth.uid() = created_by);
drop policy if exists "Create buddy reads" on public.buddy_reads;
create policy "Create buddy reads" on public.buddy_reads
  for insert with check (auth.uid() = created_by);

-- ── Moderation: reports go to a queue only reviewers can read ──
create table if not exists public.content_reports (
  id          uuid primary key default gen_random_uuid(),
  reporter_id uuid references auth.users on delete set null default auth.uid(),
  item_id     uuid references public.activity_feed on delete set null,
  reported_member_id uuid,
  note        text not null default '' check (char_length(note) <= 500),
  status      text not null default 'open' check (status in ('open','reviewing','actioned','dismissed')),
  created_at  timestamptz default now()
);
alter table public.content_reports enable row level security;
drop policy if exists "File reports" on public.content_reports;
create policy "File reports" on public.content_reports
  for insert with check (auth.uid() = reporter_id);
drop policy if exists "See own reports" on public.content_reports;
create policy "See own reports" on public.content_reports
  for select using (auth.uid() = reporter_id);

-- Max 10 reports per person per hour.
create or replace function public.limit_reports()
returns trigger language plpgsql security definer
set search_path = public as $$
begin
  if (select count(*) from content_reports where reporter_id = auth.uid()
      and created_at > now() - interval '1 hour') >= 10 then
    raise exception 'Too many reports. Try again later.';
  end if;
  return new;
end;
$$;
drop trigger if exists content_reports_rate_limit on public.content_reports;
create trigger content_reports_rate_limit before insert on public.content_reports
  for each row execute function public.limit_reports();

create table if not exists public.blocked_members (
  user_id    uuid references auth.users on delete cascade default auth.uid(),
  blocked_id uuid not null,
  created_at timestamptz default now(),
  primary key (user_id, blocked_id)
);
alter table public.blocked_members enable row level security;
drop policy if exists "Own blocks" on public.blocked_members;
create policy "Own blocks" on public.blocked_members for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Hide blocked people's posts from the person who blocked them.
drop policy if exists "Read squad activity" on public.activity_feed;
create policy "Read squad activity" on public.activity_feed
  for select using (
    squad_id = any(public.get_my_squad_ids())
    and not exists (select 1 from public.blocked_members b where b.user_id = auth.uid() and b.blocked_id = member_id)
  );

-- ── Account deletion: removes the auth user; everything cascades ──
create or replace function public.delete_my_account()
returns void language plpgsql security definer
set search_path = public, auth as $$
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  -- Rows that reference auth.users without cascade.
  delete from activity_feed where member_id = auth.uid();
  delete from reading_events where host_member_id = auth.uid();
  update squads set created_by = null where created_by = auth.uid();
  delete from auth.users where id = auth.uid();
end;
$$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- ── Digital Library: recommendations to Omari ──
alter table public.book_recommendations add column if not exists created_by uuid references auth.users on delete cascade default auth.uid();

drop policy if exists "Anyone can add book recommendations" on public.book_recommendations;
drop policy if exists "Signed-in readers can add book recommendations" on public.book_recommendations;
create policy "Signed-in readers can add book recommendations"
  on public.book_recommendations for insert to authenticated
  with check (
    created_by = auth.uid()
    and char_length(title) between 1 and 90
    and char_length(author) between 1 and 60
    and char_length(recommender_name) <= 40
    and char_length(note) <= 280
    and color between 0 and 7
  );
drop policy if exists "Delete own recommendations" on public.book_recommendations;
create policy "Delete own recommendations" on public.book_recommendations
  for delete to authenticated using (created_by = auth.uid());

-- 1 submission per 15 seconds, 10 total per person.
create or replace function public.limit_book_recommendations()
returns trigger language plpgsql security definer
set search_path = public as $$
begin
  if exists (select 1 from book_recommendations where created_by = auth.uid()
             and created_at > now() - interval '15 seconds') then
    raise exception 'Give it a few seconds before recommending another.';
  end if;
  if (select count(*) from book_recommendations where created_by = auth.uid()) >= 10 then
    raise exception 'You''ve reached the limit of 10 recommendations.';
  end if;
  return new;
end;
$$;
drop trigger if exists book_recommendations_rate_limit on public.book_recommendations;
create trigger book_recommendations_rate_limit before insert on public.book_recommendations
  for each row execute function public.limit_book_recommendations();
