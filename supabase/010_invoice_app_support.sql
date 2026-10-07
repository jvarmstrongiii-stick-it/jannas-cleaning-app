-- App support for the Invoices screen (r26). Builds on the Sep 30 Cowork
-- schema (005-009): invoices / invoice_items / payments / accounts /
-- ledger_entries, all owner-only via is_owner() (real Supabase Auth login).
--
--   jobs.price              optional per-job price; the app pre-fills it from
--                           the client's last priced job (same address first)
--                           so repeat cleanings remember their rate.
--   invoice_items.job_id    which job a line bills; a completed job with no
--                           invoice_items row is "un-invoiced".
--   save_invoice / record_payment / delete_payment / delete_invoice
--                           do invoice + items + payments + ledger in ONE
--                           transaction so the books never half-update.
--                           SECURITY INVOKER (RLS still applies) plus an
--                           explicit is_owner() check.
-- Ledger convention (same as the import): invoice = Dr 1100 A/R total,
-- Cr 4000 Revenue subtotal, Cr 2100 Sales Tax tax; payment = Dr 1000 Bank,
-- Cr 1100 A/R.

alter table public.jobs add column if not exists price numeric(12,2);
alter table public.invoice_items add column if not exists job_id uuid references public.jobs(id) on delete set null;
create index if not exists invoice_items_job_id_idx on public.invoice_items(job_id);

create or replace function public.refresh_invoice_paid(p_invoice uuid) returns void
language plpgsql set search_path = public as $$
declare v_paid numeric; v_total numeric;
begin
  select coalesce(sum(amount),0) into v_paid from payments where invoice_id = p_invoice;
  select total into v_total from invoices where id = p_invoice;
  update invoices set amount_paid = v_paid,
    status = case when status in ('void','draft') then status
                  when v_total > 0 and v_paid >= v_total then 'paid'
                  when v_paid > 0 then 'partial'
                  else 'sent' end
  where id = p_invoice;
end $$;

create or replace function public.save_invoice(p jsonb) returns uuid
language plpgsql set search_path = public as $$
declare
  v_id uuid := nullif(p->>'id','')::uuid;
  v_rate numeric := coalesce((p->>'tax_rate')::numeric, 0.06625);
  v_sub numeric; v_taxable numeric; v_tax numeric; v_total numeric;
  v_date date := (p->>'invoice_date')::date;
  it jsonb; i int := 0;
begin
  if not is_owner() then raise exception 'Only the owner can save invoices'; end if;
  if v_id is not null and exists (select 1 from invoices where id = v_id and source = 'invoice_simple_import') then
    raise exception 'Imported Invoice Simple invoices can''t be edited (no line items)';
  end if;

  select coalesce(sum(round((x->>'quantity')::numeric * (x->>'unit_price')::numeric, 2)),0),
         coalesce(sum(round((x->>'quantity')::numeric * (x->>'unit_price')::numeric, 2)) filter (where (x->>'taxable')::boolean),0)
    into v_sub, v_taxable
    from jsonb_array_elements(coalesce(p->'items','[]'::jsonb)) x;
  v_tax := round(v_taxable * v_rate, 2);
  v_total := v_sub + v_tax;

  if v_id is null then
    insert into invoices(invoice_number, client_id, invoice_date, due_date, po_number, notes, status,
                         subtotal, taxable_amount, tax_rate, tax_amount, total, source)
    values (p->>'invoice_number', (p->>'client_id')::uuid, v_date, nullif(p->>'due_date','')::date,
            nullif(p->>'po_number',''), nullif(p->>'notes',''), 'sent',
            v_sub, v_taxable, v_rate, v_tax, v_total, 'app')
    returning id into v_id;
  else
    update invoices set invoice_number = p->>'invoice_number', client_id = (p->>'client_id')::uuid,
      invoice_date = v_date, due_date = nullif(p->>'due_date','')::date,
      po_number = nullif(p->>'po_number',''), notes = nullif(p->>'notes',''),
      subtotal = v_sub, taxable_amount = v_taxable, tax_rate = v_rate, tax_amount = v_tax, total = v_total
    where id = v_id;
  end if;

  delete from invoice_items where invoice_id = v_id;
  for it in select * from jsonb_array_elements(coalesce(p->'items','[]'::jsonb)) loop
    insert into invoice_items(invoice_id, description, quantity, unit_price, taxable, sort_order, job_id)
    values (v_id, coalesce(it->>'description',''), (it->>'quantity')::numeric, (it->>'unit_price')::numeric,
            coalesce((it->>'taxable')::boolean, true), i, nullif(it->>'job_id','')::uuid);
    -- remember the billed rate on the job so the next booking pre-fills it
    if nullif(it->>'job_id','') is not null and (it->>'quantity')::numeric = 1 then
      update jobs set price = (it->>'unit_price')::numeric where id = (it->>'job_id')::uuid;
    end if;
    i := i + 1;
  end loop;

  delete from ledger_entries where invoice_id = v_id and source = 'invoice';
  insert into ledger_entries(entry_date, account_id, debit, credit, memo, invoice_id, source)
  select v_date, (select id from accounts where code='1100'), v_total, 0, 'Invoice '||(p->>'invoice_number'), v_id, 'invoice'
  union all
  select v_date, (select id from accounts where code='4000'), 0, v_sub, 'Invoice '||(p->>'invoice_number'), v_id, 'invoice'
  union all
  select v_date, (select id from accounts where code='2100'), 0, v_tax, 'Invoice '||(p->>'invoice_number'), v_id, 'invoice'
  where v_tax > 0;

  perform refresh_invoice_paid(v_id);
  return v_id;
end $$;

create or replace function public.record_payment(p_invoice uuid, p_amount numeric, p_date date, p_method text, p_reference text)
returns uuid language plpgsql set search_path = public as $$
declare v_pid uuid; v_num text; v_client uuid;
begin
  if not is_owner() then raise exception 'Only the owner can record payments'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'Payment amount must be more than $0'; end if;
  select invoice_number, client_id into v_num, v_client from invoices where id = p_invoice;
  if v_num is null then raise exception 'Invoice not found'; end if;
  insert into payments(invoice_id, client_id, amount, paid_date, method, reference)
  values (p_invoice, v_client, round(p_amount,2), p_date, nullif(p_method,''), nullif(p_reference,''))
  returning id into v_pid;
  insert into ledger_entries(entry_date, account_id, debit, credit, memo, invoice_id, payment_id, source)
  select p_date, (select id from accounts where code='1000'), round(p_amount,2), 0, 'Payment '||v_num||' ('||coalesce(p_method,'')||')', p_invoice, v_pid, 'payment'
  union all
  select p_date, (select id from accounts where code='1100'), 0, round(p_amount,2), 'Payment '||v_num||' ('||coalesce(p_method,'')||')', p_invoice, v_pid, 'payment';
  perform refresh_invoice_paid(p_invoice);
  return v_pid;
end $$;

create or replace function public.delete_payment(p_payment uuid) returns void
language plpgsql set search_path = public as $$
declare v_inv uuid;
begin
  if not is_owner() then raise exception 'Only the owner can delete payments'; end if;
  select invoice_id into v_inv from payments where id = p_payment;
  delete from ledger_entries where payment_id = p_payment;
  delete from payments where id = p_payment;
  if v_inv is not null then perform refresh_invoice_paid(v_inv); end if;
end $$;

create or replace function public.delete_invoice(p_invoice uuid) returns void
language plpgsql set search_path = public as $$
begin
  if not is_owner() then raise exception 'Only the owner can delete invoices'; end if;
  delete from ledger_entries where invoice_id = p_invoice;
  delete from payments where invoice_id = p_invoice;
  delete from invoices where id = p_invoice;  -- invoice_items cascade; billed jobs become un-invoiced
end $$;

revoke all on function public.refresh_invoice_paid(uuid), public.save_invoice(jsonb),
  public.record_payment(uuid,numeric,date,text,text), public.delete_payment(uuid), public.delete_invoice(uuid)
  from public, anon;
grant execute on function public.refresh_invoice_paid(uuid), public.save_invoice(jsonb),
  public.record_payment(uuid,numeric,date,text,text), public.delete_payment(uuid), public.delete_invoice(uuid)
  to authenticated;
