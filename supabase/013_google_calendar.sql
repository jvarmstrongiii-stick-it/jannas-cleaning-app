-- Google Calendar sync (r37). Owner-only, like the books.
-- The browser (signed-in owner) reads her work calendar with a short-lived
-- Google token (Google Identity Services, calendar.readonly) and writes here.
--
--   calendar_events  one row per event instance (singleEvents=true ids are
--                    unique per occurrence). client_id null = "Needs a client".
--   calendar_aliases normalized event title -> client, learned when Janna
--                    assigns an unmatched event ("Remember" checkbox).
--   app_settings     key/value, e.g. gcal = {calendar_id, calendar_name, last_sync}.
--   jobs.gcal_event_id  the job a calendar event created (unique).

create table if not exists public.calendar_events (
  id text primary key,
  calendar_id text not null,
  summary text,
  location text,
  description text,
  start_date date,
  start_time text,
  end_time text,
  all_day boolean not null default false,
  status text,
  recurring_event_id text,
  html_link text,
  google_updated timestamptz,
  client_id uuid references public.clients(id) on delete set null,
  job_id uuid references public.jobs(id) on delete set null,
  ignored boolean not null default false,
  synced_at timestamptz not null default now()
);
create index if not exists calendar_events_start_idx on public.calendar_events(start_date);

create table if not exists public.calendar_aliases (
  key text primary key,
  client_id uuid not null references public.clients(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.app_settings (
  key text primary key,
  value jsonb,
  updated_at timestamptz not null default now()
);

alter table public.jobs add column if not exists gcal_event_id text;
create unique index if not exists jobs_gcal_event_id_key on public.jobs(gcal_event_id) where gcal_event_id is not null;

alter table public.calendar_events enable row level security;
alter table public.calendar_aliases enable row level security;
alter table public.app_settings enable row level security;
create policy "owner full access" on public.calendar_events for all to authenticated using (public.is_owner()) with check (public.is_owner());
create policy "owner full access" on public.calendar_aliases for all to authenticated using (public.is_owner()) with check (public.is_owner());
create policy "owner full access" on public.app_settings for all to authenticated using (public.is_owner()) with check (public.is_owner());
