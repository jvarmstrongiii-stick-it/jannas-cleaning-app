-- Incremental migration for projects that already ran schema.sql before
-- `properties` existed. Safe to run once against the live project. New
-- fresh projects should just use the updated schema.sql instead -- this
-- file is only for catching up.
--
-- `properties` holds a client's saved/named job-site addresses (e.g. a
-- renter who has us clean both their own unit and a second rental they
-- manage). It is purely a convenience lookup for autofilling the Book/Edit
-- Job "Job Site Address" field -- jobs.address stays free text, exactly
-- like jobs.cleaner stays free text, so a job's booked address is never
-- retroactively changed by later property edits/deletions, and deleting a
-- property is never blocked by past job references.

create table if not exists properties (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references clients(id) on delete cascade,
  label text,
  address text not null,
  created_at timestamptz not null default now()
);

create index if not exists properties_client_id_idx on properties(client_id);

alter table properties enable row level security;

create policy "anon full access on properties" on properties
  for all to anon using (true) with check (true);
