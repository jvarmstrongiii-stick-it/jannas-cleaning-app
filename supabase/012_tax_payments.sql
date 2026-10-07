-- NJ sales tax payments with check # / EFT # (r31).
-- Stored as `expenses` rows on account 2100 (Dr 2100 Sales Tax Payable /
-- Cr 1000 Bank), plus method / reference / tax_period so the Books tab can
-- show "Check #1234" and attribute the payment to the quarter it covers
-- (a Q3 return is paid in October).

alter table public.expenses add column if not exists method text;
alter table public.expenses add column if not exists reference text;
alter table public.expenses add column if not exists tax_period text;

create or replace function public.record_tax_payment(p_date date, p_amount numeric, p_method text, p_reference text, p_period text)
returns uuid language plpgsql set search_path = public as $$
declare v_id uuid; v_memo text;
begin
  if not is_owner() then raise exception 'Only the owner can record tax payments'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'Amount must be more than $0'; end if;
  insert into expenses(expense_date, amount, account_id, vendor, note, method, reference, tax_period)
  values (p_date, round(p_amount,2), (select id from accounts where code='2100'), 'NJ Division of Taxation',
          nullif(p_period,''), nullif(p_method,''), nullif(p_reference,''), nullif(p_period,''))
  returning id into v_id;
  v_memo := 'NJ sales tax' || coalesce(' ' || nullif(p_period,''), '')
            || coalesce(' — ' || nullif(p_method,'') || coalesce(' #' || nullif(p_reference,''), ''), '');
  insert into ledger_entries(entry_date, account_id, debit, credit, memo, expense_id, source)
  select p_date, (select id from accounts where code='2100'), round(p_amount,2), 0, v_memo, v_id, 'expense'
  union all
  select p_date, (select id from accounts where code='1000'), 0, round(p_amount,2), v_memo, v_id, 'expense';
  return v_id;
end $$;
revoke all on function public.record_tax_payment(date,numeric,text,text,text) from public, anon;
grant execute on function public.record_tax_payment(date,numeric,text,text,text) to authenticated;
