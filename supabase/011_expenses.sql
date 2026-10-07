-- Expenses for the Books tab (r29). Owner-only like the rest of the books.
-- Each expense = Dr <expense account or 2100 Sales Tax Payable> / Cr 1000 Bank.
-- ledger_entries.expense_id cascades, so deleting an expense row (plain
-- client delete, RLS owner-only) also removes its two ledger rows.

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  expense_date date not null,
  amount numeric(12,2) not null check (amount > 0),
  account_id uuid not null references public.accounts(id),
  vendor text,
  note text,
  created_at timestamptz not null default now()
);
create index if not exists expenses_date_idx on public.expenses(expense_date);
alter table public.expenses enable row level security;
create policy "owner full access" on public.expenses
  for all to authenticated using (public.is_owner()) with check (public.is_owner());

alter table public.ledger_entries add column if not exists expense_id uuid references public.expenses(id) on delete cascade;
create index if not exists ledger_entries_expense_id_idx on public.ledger_entries(expense_id);

create or replace function public.record_expense(p_date date, p_amount numeric, p_account_code text, p_vendor text, p_note text)
returns uuid language plpgsql set search_path = public as $$
declare v_id uuid; v_acct uuid; v_memo text;
begin
  if not is_owner() then raise exception 'Only the owner can record expenses'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'Amount must be more than $0'; end if;
  select id into v_acct from accounts where code = p_account_code and (type = 'expense' or code = '2100');
  if v_acct is null then raise exception 'Unknown expense category'; end if;
  insert into expenses(expense_date, amount, account_id, vendor, note)
  values (p_date, round(p_amount,2), v_acct, nullif(p_vendor,''), nullif(p_note,''))
  returning id into v_id;
  v_memo := coalesce(nullif(p_vendor,''), (select name from accounts where id = v_acct))
            || coalesce(' — ' || nullif(p_note,''), '');
  insert into ledger_entries(entry_date, account_id, debit, credit, memo, expense_id, source)
  select p_date, v_acct, round(p_amount,2), 0, v_memo, v_id, 'expense'
  union all
  select p_date, (select id from accounts where code='1000'), 0, round(p_amount,2), v_memo, v_id, 'expense';
  return v_id;
end $$;
revoke all on function public.record_expense(date,numeric,text,text,text) from public, anon;
grant execute on function public.record_expense(date,numeric,text,text,text) to authenticated;
