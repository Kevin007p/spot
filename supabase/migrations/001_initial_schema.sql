-- ============================================================
-- spot. — Initial Database Schema
-- Run this in the Supabase SQL Editor (Dashboard → SQL Editor)
-- ============================================================

-- 1. USERS TABLE
-- Extends Supabase's built-in auth.users with app-specific fields
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  auth_provider text not null default '',
  profile_private boolean not null default true,
  created_at timestamptz not null default now(),
  deleted_at timestamptz  -- soft delete: null = active, set = scheduled for deletion
);

-- 2. PLACE CACHE TABLE
-- Stores cached Google Places data to reduce API calls and enable offline viewing
create table public.place_cache (
  google_place_id text primary key,
  name text not null,
  address text not null default '',
  lat double precision not null default 0,
  lng double precision not null default 0,
  rating double precision not null default 0,
  price_level integer not null default 0,
  category text not null default '',
  cuisine text not null default '',
  last_refreshed timestamptz not null default now()
);

-- 3. SAVED PLACES TABLE
-- Each row = one place saved by one user
create table public.saved_places (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  google_place_id text not null references public.place_cache(google_place_id),
  note_text text not null default '',
  date_visited date,
  saved_at timestamptz not null default now(),

  -- Prevent duplicate saves: same user + same place = blocked
  unique(user_id, google_place_id)
);

-- Indexes for common queries
create index idx_saved_places_user_id on public.saved_places(user_id);
create index idx_saved_places_saved_at on public.saved_places(saved_at desc);
create index idx_users_deleted_at on public.users(deleted_at) where deleted_at is not null;

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Enable RLS on all tables
alter table public.users enable row level security;
alter table public.place_cache enable row level security;
alter table public.saved_places enable row level security;

-- USERS: users can only read/update their own row
create policy "Users can view own profile"
  on public.users for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.users for update
  using (auth.uid() = id);

-- PLACE CACHE: any authenticated user can read; insert handled by service role
create policy "Authenticated users can read place cache"
  on public.place_cache for select
  to authenticated
  using (true);

create policy "Authenticated users can insert place cache"
  on public.place_cache for insert
  to authenticated
  with check (true);

create policy "Authenticated users can update place cache"
  on public.place_cache for update
  to authenticated
  using (true);

-- SAVED PLACES: users can only CRUD their own saved places
create policy "Users can view own saved places"
  on public.saved_places for select
  using (auth.uid() = user_id);

create policy "Users can insert own saved places"
  on public.saved_places for insert
  with check (auth.uid() = user_id);

create policy "Users can update own saved places"
  on public.saved_places for update
  using (auth.uid() = user_id);

create policy "Users can delete own saved places"
  on public.saved_places for delete
  using (auth.uid() = user_id);

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Auto-create a users row when someone signs up via Supabase Auth
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, email, auth_provider)
  values (
    new.id,
    new.email,
    coalesce(new.raw_app_meta_data->>'provider', '')
  );
  return new;
end;
$$ language plpgsql security definer;

-- Trigger: fires after every new auth signup
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Soft delete: mark account for deletion (30-day grace period)
create or replace function public.soft_delete_account()
returns void as $$
begin
  update public.users
  set deleted_at = now()
  where id = auth.uid();
end;
$$ language plpgsql security definer;

-- Cancel deletion: clear the deleted_at timestamp
create or replace function public.cancel_delete_account()
returns void as $$
begin
  update public.users
  set deleted_at = null
  where id = auth.uid();
end;
$$ language plpgsql security definer;

-- ============================================================
-- CRON: Auto-purge accounts after 30 days (requires pg_cron extension)
-- Enable pg_cron in Supabase Dashboard → Database → Extensions
-- Then run this separately:
-- ============================================================
-- select cron.schedule(
--   'purge-deleted-accounts',
--   '0 3 * * *',  -- daily at 3 AM UTC
--   $$
--     delete from auth.users
--     where id in (
--       select id from public.users
--       where deleted_at is not null
--         and deleted_at < now() - interval '30 days'
--     );
--   $$
-- );
