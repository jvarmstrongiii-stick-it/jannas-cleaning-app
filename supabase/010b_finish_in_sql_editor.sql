-- PASTE THIS WHOLE FILE into Supabase → SQL Editor → New query → Run.
-- Finishes migration 010 (the parts the Supabase MCP couldn't apply because
-- they contain DELETE and its confirmation prompt timed out). Safe to run
-- more than once. It only DEFINES functions; it deletes no data.

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
