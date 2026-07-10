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

-- ── properties ───────────────────────────────────────────────────
-- A client's saved/named job-site addresses (e.g. a renter who has us
-- clean both their own unit and a second rental they manage). This is
-- purely a lookup for autofilling the Book/Edit Job "Job Site Address"
-- field -- jobs.address stays free text, exactly like jobs.cleaner, so a
-- job's booked address is never retroactively changed by later property
-- edits/deletions, and deleting a property is never blocked by past job
-- references.
create table if not exists properties (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references clients(id) on delete cascade,
  label text,
  address text not null,
  created_at timestamptz not null default now()
);

create index if not exists properties_client_id_idx on properties(client_id);

-- ── cleaners ─────────────────────────────────────────────────────
-- Staff/employees. jobs.cleaner stays a free-text name (not a FK) so
-- existing job history isn't disturbed by roster changes; the Book/Edit
-- Job "Assign Cleaner" dropdown is populated from this table.
-- role: 'owner' (Janna -- full access) or 'cleaner' (view + notes +
-- mark-complete only). New rows default to 'cleaner'; promote the owner
-- manually (see supabase/003_add_cleaner_role.sql).
create table if not exists cleaners (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  email text,
  active boolean not null default true,
  role text not null default 'cleaner',
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
alter table cleaners enable row level security;
alter table properties enable row level security;

create policy "anon full access on clients" on clients
  for all to anon using (true) with check (true);

create policy "anon full access on jobs" on jobs
  for all to anon using (true) with check (true);

create policy "anon full access on notes" on notes
  for all to anon using (true) with check (true);

create policy "anon full access on cleaners" on cleaners
  for all to anon using (true) with check (true);

create policy "anon full access on properties" on properties
  for all to anon using (true) with check (true);
