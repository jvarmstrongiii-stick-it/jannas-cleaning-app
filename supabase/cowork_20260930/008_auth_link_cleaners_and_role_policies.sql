-- Applied 2026-09-30 by Cowork (20260930172839 "auth_link_cleaners_and_role_policies").
-- Verbatim copy. Do NOT re-run on live.

drop table if exists public.profiles cascade;

alter table public.cleaners add column if not exists auth_user_id uuid unique references auth.users(id) on delete set null;

create or replace function public.is_owner() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.cleaners where auth_user_id = auth.uid() and role = 'owner' and active);
$$;
create or replace function public.is_staff() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.cleaners where auth_user_id = auth.uid() and active);
$$;
revoke all on function public.is_owner(), public.is_staff() from public, anon;
grant execute on function public.is_owner(), public.is_staff() to authenticated;

-- staff (owner or cleaner): same things the app lets cleaners do today
create policy "staff read clients" on public.clients for select to authenticated using (public.is_staff());
create policy "staff add clients" on public.clients for insert to authenticated with check (public.is_staff());
create policy "staff read jobs" on public.jobs for select to authenticated using (public.is_staff());
create policy "staff update jobs" on public.jobs for update to authenticated using (public.is_staff()) with check (public.is_staff());
create policy "staff read notes" on public.notes for select to authenticated using (public.is_staff());
create policy "staff add notes" on public.notes for insert to authenticated with check (public.is_staff());
create policy "staff read properties" on public.properties for select to authenticated using (public.is_staff());
create policy "staff add properties" on public.properties for insert to authenticated with check (public.is_staff());
create policy "staff read cleaners" on public.cleaners for select to authenticated using (public.is_staff());
