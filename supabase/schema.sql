-- Janna's Cleaning Service — Supabase schema
-- Run this once against a fresh Supabase project (SQL Editor -> New query).
-- No auth for v1: RLS is enabled but policies grant the anon key full
-- read/write, matching the posture of the claudia.html HVAC app.

create extension if not exists "pgcrypto";

-- ── clients ──────────────────────────────────────────────────────
create table if not exists clients (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  email text,
  address text,
  created_at timestamptz not null default now()
);

-- ── jobs ─────────────────────────────────────────────────────────
create table if not exists jobs (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references clients(id) on delete cascade,
  address text,
  type text,
  recurring text,
  status text not null default 'scheduled',
  date date not null,
  time text,
  cleaner text default 'Unassigned',
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists jobs_client_id_idx on jobs(client_id);
create index if not exists jobs_date_idx on jobs(date);

-- ── notes ────────────────────────────────────────────────────────
create table if not exists notes (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references clients(id) on delete cascade,
  text text not null,
  date date not null default current_date,
  created_at timestamptz not null default now()
);

create index if not exists notes_client_id_idx on notes(client_id);

-- ── RLS: open anon key access (no auth in v1) ───────────────────
alter table clients enable row level security;
alter table jobs enable row level security;
alter table notes enable row level security;

create policy "anon full access on clients" on clients
  for all to anon using (true) with check (true);

create policy "anon full access on jobs" on jobs
  for all to anon using (true) with check (true);

create policy "anon full access on notes" on notes
  for all to anon using (true) with check (true);
