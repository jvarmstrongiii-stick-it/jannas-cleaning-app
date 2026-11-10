-- r40 (2026-11-10): everyone signs in; the open anon key no longer reads or
-- writes anything. Apply AFTER the r40 app is live (r39 still relied on anon).
--
-- Why: the anon key ships in jannas.html (and the repo is public), so the old
-- "anon full access" policies exposed every client's name/phone/address and let
-- anyone write `cleaners` — including inserting a role='owner' row with their
-- own email, then signing up so link_auth_user_to_cleaner() made them owner
-- (= full access to invoices, payments and the books).
--
-- What still works after this (policies already in place from 008):
--   owner  (is_owner): full access to every table
--   staff  (is_staff): read clients/jobs/notes/properties/cleaners,
--                      add clients/notes/properties, update jobs (mark complete)

drop policy if exists "anon full access on clients"    on public.clients;
drop policy if exists "anon full access on jobs"       on public.jobs;
drop policy if exists "anon full access on notes"      on public.notes;
drop policy if exists "anon full access on properties" on public.properties;
drop policy if exists "anon full access on cleaners"   on public.cleaners;

-- Belt and braces: anon gets no table privileges at all in public.
revoke all on all tables in schema public from anon;
alter default privileges in schema public revoke all on tables from anon;

-- Signed-out callers can't run the RPCs either (each already checks is_owner()).
revoke execute on all functions in schema public from anon;
alter default privileges in schema public revoke execute on functions from anon;
