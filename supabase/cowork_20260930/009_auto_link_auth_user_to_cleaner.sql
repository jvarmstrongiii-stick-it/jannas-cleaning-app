-- Applied 2026-09-30 by Cowork (20260930172931 "auto_link_auth_user_to_cleaner").
-- Verbatim copy. Do NOT re-run on live. A new Supabase Auth user is linked
-- to the cleaners row with the same email (that's how Janna becomes owner).

create or replace function public.link_auth_user_to_cleaner() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update public.cleaners set auth_user_id = new.id
   where auth_user_id is null and lower(email) = lower(new.email);
  return new;
end $$;
drop trigger if exists on_auth_user_created_link_cleaner on auth.users;
create trigger on_auth_user_created_link_cleaner after insert on auth.users
  for each row execute function public.link_auth_user_to_cleaner();
