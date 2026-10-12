-- ============================================================
-- Bookmark Buddy — Phase 10: public shareable shelves.
-- Copyright © 2026 Omari Bell. All rights reserved.
-- Run AFTER supabase_phase9_hardening.sql. Safe to re-run.
-- ============================================================

create table if not exists public.reader_shelves (
  user_id      uuid primary key references auth.users on delete cascade default auth.uid(),
  handle       text not null unique check (handle ~ '^[a-z0-9_]{3,24}$'),
  display_name text not null default '' check (char_length(display_name) <= 40),
  bio          text not null default '' check (char_length(bio) <= 160),
  is_public    boolean not null default false,
  updated_at   timestamptz not null default now()
);
alter table public.reader_shelves enable row level security;

drop policy if exists "Read public or own shelf" on public.reader_shelves;
create policy "Read public or own shelf" on public.reader_shelves
  for select to anon, authenticated using (is_public or auth.uid() = user_id);
drop policy if exists "Create own shelf" on public.reader_shelves;
create policy "Create own shelf" on public.reader_shelves
  for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "Update own shelf" on public.reader_shelves;
create policy "Update own shelf" on public.reader_shelves
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "Delete own shelf" on public.reader_shelves;
create policy "Delete own shelf" on public.reader_shelves
  for delete to authenticated using (auth.uid() = user_id);

create table if not exists public.reader_shelf_books (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.reader_shelves(user_id) on delete cascade default auth.uid(),
  title      text not null check (char_length(title) between 1 and 90),
  author     text not null check (char_length(author) between 1 and 60),
  note       text not null default '' check (char_length(note) <= 280),
  color      smallint not null default 0 check (color between 0 and 7),
  position   int not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists reader_shelf_books_user_idx on public.reader_shelf_books (user_id, position);
alter table public.reader_shelf_books enable row level security;

drop policy if exists "Read books on public or own shelf" on public.reader_shelf_books;
create policy "Read books on public or own shelf" on public.reader_shelf_books
  for select to anon, authenticated using (
    auth.uid() = user_id
    or exists (select 1 from public.reader_shelves s where s.user_id = reader_shelf_books.user_id and s.is_public)
  );
drop policy if exists "Add books to own shelf" on public.reader_shelf_books;
create policy "Add books to own shelf" on public.reader_shelf_books
  for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "Edit books on own shelf" on public.reader_shelf_books;
create policy "Edit books on own shelf" on public.reader_shelf_books
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "Remove books from own shelf" on public.reader_shelf_books;
create policy "Remove books from own shelf" on public.reader_shelf_books
  for delete to authenticated using (auth.uid() = user_id);

-- At most 50 books per shelf.
create or replace function public.limit_shelf_books()
returns trigger language plpgsql security definer
set search_path = public as $$
begin
  if (select count(*) from reader_shelf_books where user_id = new.user_id) >= 50 then
    raise exception 'Your shelf holds up to 50 books.';
  end if;
  return new;
end;
$$;
drop trigger if exists reader_shelf_books_limit on public.reader_shelf_books;
create trigger reader_shelf_books_limit before insert on public.reader_shelf_books
  for each row execute function public.limit_shelf_books();

-- Keep updated_at fresh.
create or replace function public.touch_reader_shelf()
returns trigger language plpgsql set search_path = public as $$
begin
  new.updated_at := now();
  return new;
end;
$$;
drop trigger if exists reader_shelves_touch on public.reader_shelves;
create trigger reader_shelves_touch before update on public.reader_shelves
  for each row execute function public.touch_reader_shelf();
