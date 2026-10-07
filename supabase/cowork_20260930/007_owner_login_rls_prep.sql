-- Applied 2026-09-30 by Cowork (20260930172645 "owner_login_rls_prep").
-- Verbatim copy. Superseded in part by 008 (profiles dropped, is_owner
-- redefined against cleaners.auth_user_id). Do NOT re-run on live.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text not null default 'pending' check (role in ('owner','cleaner','client','pending')),
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;

create or replace function public.is_owner() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'owner');
$$;
revoke all on function public.is_owner() from public, anon;
grant execute on function public.is_owner() to authenticated;

create policy "users read own profile" on public.profiles for select to authenticated using (id = auth.uid());
create policy "owner manages profiles" on public.profiles for all to authenticated using (public.is_owner()) with check (public.is_owner());

do $$
declare t text;
begin
  foreach t in array array['clients','jobs','notes','cleaners','properties','invoices','invoice_items','payments','accounts','ledger_entries']
  loop
    execute format('create policy "owner full access" on public.%I for all to authenticated using (public.is_owner()) with check (public.is_owner())', t);
  end loop;
end $$;
