-- Planet Streaming: initial database schema
-- Run this in Supabase SQL Editor. RLS is enabled on every user-owned table.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now()
);

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  source_url text,
  source_platform text not null default 'youtube',
  status text not null default 'draft' check (status in ('draft','queued','processing','ready','failed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.clips (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text,
  start_seconds numeric(12,3) not null default 0,
  end_seconds numeric(12,3),
  aspect_ratio text not null default '9:16',
  status text not null default 'suggested' check (status in ('suggested','editing','approved','published')),
  storage_path text,
  created_at timestamptz not null default now()
);

create table if not exists public.editing_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  pacing text not null default 'dynamic',
  captions_style text not null default 'highlighted',
  framing text not null default 'follow_subject',
  preferred_duration text not null default '30-60',
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.clips enable row level security;
alter table public.editing_preferences enable row level security;

create policy "Users can read own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can create own profile" on public.profiles for insert with check (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

create policy "Users manage own projects" on public.projects for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own clips" on public.clips for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users manage own editing preferences" on public.editing_preferences for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
