-- Applied to the live DB on 2026-09-30 by a Cowork session (migration
-- 20260930171947 "invoicing_and_ledger_schema"). Copied here verbatim from
-- supabase_migrations.schema_migrations so the repo matches the live DB.
-- Do NOT re-run against the live project.

alter table public.clients add column if not exists mobile text;
alter table public.clients add column if not exists client_type text default 'residential';
alter table public.clients add column if not exists source_ref text;
create unique index if not exists clients_source_ref_key on public.clients(source_ref) where source_ref is not null;

create table public.invoices (
  id uuid primary key default gen_random_uuid(),
  invoice_number text not null unique,
  client_id uuid not null references public.clients(id),
  job_id uuid references public.jobs(id),
  invoice_date date not null,
  due_date date,
  status text not null default 'sent' check (status in ('draft','sent','partial','paid','void')),
  subtotal numeric(12,2) not null default 0,
  taxable_amount numeric(12,2) not null default 0,
  tax_rate numeric(6,5) not null default 0.06625,
  tax_amount numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0,
  amount_paid numeric(12,2) not null default 0,
  balance_due numeric(12,2) generated always as (total - amount_paid) stored,
  po_number text,
  notes text,
  source text default 'manual',
  created_at timestamptz not null default now()
);
create index on public.invoices(client_id);
create index on public.invoices(invoice_date);

create table public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  description text not null,
  quantity numeric(10,2) not null default 1,
  unit_price numeric(12,2) not null default 0,
  taxable boolean not null default true,
  amount numeric(12,2) generated always as (quantity * unit_price) stored,
  sort_order int default 0
);
create index on public.invoice_items(invoice_id);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id),
  client_id uuid not null references public.clients(id),
  amount numeric(12,2) not null,
  paid_date date not null,
  method text,
  reference text,
  created_at timestamptz not null default now()
);
create index on public.payments(invoice_id);

create table public.accounts (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  type text not null check (type in ('asset','liability','equity','revenue','expense')),
  active boolean not null default true
);

create table public.ledger_entries (
  id uuid primary key default gen_random_uuid(),
  entry_date date not null,
  account_id uuid not null references public.accounts(id),
  debit numeric(12,2) not null default 0,
  credit numeric(12,2) not null default 0,
  memo text,
  invoice_id uuid references public.invoices(id),
  payment_id uuid references public.payments(id),
  source text default 'system',
  created_at timestamptz not null default now(),
  check (debit >= 0 and credit >= 0 and (debit = 0 or credit = 0))
);
create index on public.ledger_entries(entry_date);
create index on public.ledger_entries(account_id);

-- Financial data: RLS on, deliberately NO anon policies (locked until real auth exists)
alter table public.invoices enable row level security;
alter table public.invoice_items enable row level security;
alter table public.payments enable row level security;
alter table public.accounts enable row level security;
alter table public.ledger_entries enable row level security;

insert into public.accounts(code,name,type) values
 ('1000','Checking / Bank','asset'),
 ('1100','Accounts Receivable','asset'),
 ('2100','Sales Tax Payable','liability'),
 ('3000','Owner Equity','equity'),
 ('4000','Cleaning Service Revenue','revenue'),
 ('5000','Supplies','expense'),
 ('5100','Labor / Subcontractors','expense'),
 ('5200','Vehicle & Fuel','expense'),
 ('5900','Other Expenses','expense');
