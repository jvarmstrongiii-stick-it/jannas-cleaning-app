-- Incremental migration for projects that already ran the original
-- schema.sql (which didn't have a cleaners table). Safe to run once
-- against the live project. New fresh projects should just use the
-- updated schema.sql instead — this file is only for catching up.

create table if not exists cleaners (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  email text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table cleaners enable row level security;

create policy "anon full access on cleaners" on cleaners
  for all to anon using (true) with check (true);
