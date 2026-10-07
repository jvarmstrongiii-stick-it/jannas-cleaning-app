-- Applied 2026-09-30 by Cowork (20260930172030 "import_invoice_simple_history").
-- Do NOT re-run on live. Logic is a verbatim copy; the 83 staging rows were
-- regenerated from the Invoice Simple export (Drive: "Janna cleaning app" /
-- Invoice-Summary-[2026-01-01]-[2026-12-31].xlsx) and match the live data
-- (unpaid total $12,127.56). Note: at the time, clients got their number in
-- `mobile` (not `phone`) when Invoice Simple listed it as Mobile.

insert into public.clients(name, phone, mobile, email, client_type, source_ref) values
 ('Mallory (Property Management)', null, '(609) 517-4167', 'pmcpayables@comcast.net', 'property_management', 'mallory'),
 ('Lisa Schatz 1705 Wesley', '(610) 733-7227', null, '1705wesleyave@gmail.com', 'residential', 'lisa'),
 ('Somers Point Paddle Club', null, '(609) 846-3912', 'katiejo@scarboroughproperties.com', 'commercial', 'paddle'),
 ('Harbour Cove marina/KatieJo', null, null, 'katiejo@scarboroughproperties.com', 'commercial', 'harbour'),
 ('Rachel All Seasons', null, '(609) 231-4902', 'ap@allseasonsmarina.com', 'commercial', 'rachel'),
 ('Dave VanOcker', null, '(610) 283-6524', 'cvmvan@comcast.net', 'residential', 'vanocker'),
 ('Dave Creamer', '(215) 917-1500', '(215) 917-1500', 'Dave@witmerllc.com', 'residential', 'creamer'),
 ('Ed Paone', null, null, 'epaone@live.com', 'residential', 'paone'),
 ('Kristin Borelli 1109 Central', null, '2676641185', 'kristin.nace@gmail.com', 'residential', 'borelli');

create temp table stg(inv text, d date, k text, sub numeric, taxable numeric, tax numeric, tot numeric, paid numeric, pd date, m text) on commit drop;
insert into stg values
('INV1073','2026-09-29','mallory',750,750,49.69,799.69,0,null,null),
('INV1072','2026-09-29','mallory',320,320,21.20,341.20,0,null,null),
('INV1071','2026-09-29','mallory',1210,1210,80.16,1290.16,0,null,null),
('INV1070','2026-09-29','mallory',960,880,58.30,1018.30,0,null,null),
('INV1069','2026-09-27','harbour',2509,2509,166.22,2675.22,0,null,null),
('INV1068','2026-09-27','paddle',3780,3780,250.43,4030.43,0,null,null),
('INV1067','2026-09-27','vanocker',1890,1890,125.21,2015.21,2015.21,'2026-09-29','CHECK'),
('INV1066','2026-09-26','rachel',1850,1850,122.56,1972.56,0,null,null),
('INV1065','2026-09-23','lisa',296,296,19.61,315.61,315.61,'2026-09-29','BANK'),
('INV1064','2026-09-05','lisa',296,296,19.61,315.61,315.61,'2026-09-11','BANK'),
('INV1063','2026-08-31','creamer',275,275,18.22,293.22,293.22,'2026-09-12','CHECK'),
('INV1062','2026-08-31','harbour',3667,3667,242.94,3909.94,3909.94,'2026-09-12','CHECK'),
('INV1061','2026-08-31','paddle',6420,6420,425.33,6845.33,6845.33,'2026-09-12','CHECK'),
('INV1060','2026-08-31','mallory',1566,1566,103.75,1669.75,1669.75,'2026-09-02','CHECK'),
('INV1059','2026-08-31','mallory',1380,1380,91.42,1471.42,1471.42,'2026-09-02','CHECK'),
('INV1058','2026-08-31','mallory',1030,950,62.94,1092.94,1092.94,'2026-09-02','CHECK'),
('INV1057','2026-08-31','mallory',320,320,21.20,341.20,341.2,'2026-09-02','CHECK'),
('INV1056','2026-08-30','vanocker',2020,2020,133.83,2153.83,2153.83,'2026-09-01','BANK'),
('INV1055','2026-08-30','paone',640,640,42.40,682.40,682.4,'2026-09-05','CHECK'),
('INV1054','2026-08-30','rachel',3230,3230,213.99,3443.99,3443.99,'2026-09-05','CHECK'),
('INV1053','2026-08-22','borelli',592,592,39.22,631.22,631.22,'2026-08-28','BANK'),
('INV1052','2026-08-22','lisa',296,296,19.61,315.61,315.61,'2026-08-28','BANK'),
('INV1051','2026-08-08','lisa',296,296,19.61,315.61,315.61,'2026-08-14','BANK'),
('INV1050','2026-08-01','mallory',1566,1566,103.75,1669.75,1669.75,'2026-08-14','CHECK'),
('INV1049','2026-08-01','mallory',1210,1210,80.16,1290.16,1290.16,'2026-08-14','CHECK'),
('INV1048','2026-08-01','mallory',320,320,21.20,341.20,341.2,'2026-08-14','CHECK'),
('INV1047','2026-08-01','mallory',1110,1110,73.54,1183.54,1183.54,'2026-08-14','CHECK'),
('INV1046','2026-08-01','paddle',6420,6420,425.33,6845.33,6845.33,'2026-08-14','CHECK'),
('INV1045','2026-07-31','harbour',3281,3281,217.37,3498.37,3498.37,'2026-08-14','CHECK'),
('INV1044','2026-07-30','rachel',3170,3170,210.01,3380.01,3380.01,'2026-08-08','CHECK'),
('INV1043','2026-07-29','creamer',350,350,23.19,373.19,373.19,'2026-08-08','CHECK'),
('INV1042','2026-07-25','paone',320,320,21.20,341.20,341.2,'2026-08-07','CHECK'),
('INV1041','2026-07-25','borelli',592,592,39.22,631.22,631.22,'2026-07-31','BANK'),
('INV1040','2026-07-25','lisa',296,296,19.61,315.61,315.61,'2026-08-06','CHECK'),
('INV1039','2026-07-15','lisa',296,296,19.61,315.61,315.61,'2026-07-25','CHECK'),
('INV1038','2026-06-30','paddle',4840,4840,320.65,5160.65,5160.65,'2026-07-25','CHECK'),
('INV1037','2026-06-30','harbour',2509,2509,166.22,2675.22,2675.22,'2026-07-15','CHECK'),
('INV1036','2026-06-30','rachel',3120,3120,206.71,3326.71,3326.71,'2026-07-15','CHECK'),
('INV1035','2026-06-29','borelli',296,296,19.61,315.61,315.61,'2026-07-05','BANK'),
('INV1034','2026-06-29','mallory',1170,1170,77.52,1247.52,1247.52,'2026-07-05','CHECK'),
('INV1033','2026-06-29','mallory',320,320,21.20,341.20,341.2,'2026-07-05','CHECK'),
('INV1032','2026-06-29','mallory',1210,1210,80.16,1290.16,1290.16,'2026-07-05','CHECK'),
('INV1031','2026-06-29','mallory',880,880,58.30,938.30,938.3,'2026-07-05','CHECK'),
('INV1030','2026-06-27','lisa',296,296,19.61,315.61,315.61,'2026-06-29','BANK'),
('INV1029','2026-06-22','paone',320,320,21.20,341.20,341.2,'2026-07-07','CHECK'),
('INV1027','2026-06-02','paddle',2160,2160,143.10,2303.10,2303.1,'2026-06-29','CHECK'),
('INV1024','2026-05-30','rachel',2010,2010,133.16,2143.16,2143.16,'2026-06-05','CHECK'),
('INV1023','2026-05-30','lisa',296,296,19.61,315.61,315.61,'2026-06-02','BANK'),
('INV1022','2026-05-29','harbour',1737,1737,115.08,1852.08,1852.08,'2026-06-20','CHECK'),
('INV1021','2026-05-28','mallory',945,945,62.61,1007.61,1007.61,'2026-05-29','CHECK'),
('INV1020','2026-05-28','mallory',600,600,39.75,639.75,639.75,'2026-05-29','CHECK'),
('INV1019','2026-05-28','mallory',160,160,10.60,170.60,170.6,'2026-05-29','CHECK'),
('INV1018','2026-05-28','mallory',870,820,54.33,924.33,924.33,'2026-05-29','CHECK'),
('INV1017','2026-05-26','creamer',1812.37,525,34.78,1847.15,1847.15,'2026-06-05','CHECK'),
('INV1016','2026-05-17','lisa',296,296,19.61,315.61,315.61,'2026-05-28','BANK'),
('INV1015','2026-05-04','lisa',296,296,19.61,315.61,315.61,'2026-05-28','BANK'),
('INV1014','2026-04-29','mallory',750,750,49.69,799.69,799.69,'2026-05-01','CHECK'),
('INV1013','2026-04-29','mallory',715,685,45.38,760.38,760.38,'2026-05-01','CHECK'),
('INV1012','2026-04-29','mallory',320,320,21.20,341.20,341.2,'2026-05-01','CHECK'),
('INV1011','2026-04-29','mallory',320,320,21.20,341.20,341.2,'2026-05-01','CHECK'),
('INV1010','2026-04-27','rachel',250,250,16.56,266.56,266.56,'2026-06-01','CHECK'),
('INV1009','2026-04-27','harbour',1029,1029,68.17,1097.17,1097.17,'2026-06-01','CHECK'),
('INV1008','2026-04-20','lisa',280,280,18.55,298.55,298.55,'2026-04-29','BANK'),
('INV1007','2026-04-06','lisa',280,280,18.55,298.55,298.55,'2026-04-20','CHECK'),
('INV1006','2026-03-26','mallory',370,320,21.20,391.20,391.2,'2026-04-20','CHECK'),
('INV1005','2026-03-26','mallory',160,160,10.60,170.60,170.6,'2026-04-20','CHECK'),
('INV1004','2026-03-26','mallory',265,265,17.56,282.56,282.56,'2026-04-20','CHECK'),
('INV1003','2026-03-26','mallory',600,600,39.75,639.75,639.75,'2026-04-20','CHECK'),
('INV1002','2026-03-26','creamer',275,275,18.22,293.22,293.22,'2026-04-17','CHECK'),
('INV1001','2026-02-27','mallory',600,600,39.75,639.75,639.75,'2026-03-10','CHECK'),
('INV1000','2026-02-27','mallory',160,160,10.60,170.60,170.6,'2026-03-10','CHECK'),
('INV0999','2026-02-27','mallory',265,265,17.56,282.56,282.56,'2026-03-10','CHECK'),
('INV0998','2026-02-27','mallory',320,320,21.20,341.20,341.2,'2026-03-10','CHECK'),
('INV0997','2026-02-21','lisa',140,140,9.28,149.28,149.28,'2026-03-10','BANK'),
('INV0996','2026-01-30','mallory',160,160,10.60,170.60,170.6,'2026-03-10','CHECK'),
('INV0995','2026-01-30','mallory',265,265,17.56,282.56,282.56,'2026-03-10','CHECK'),
('INV0994','2026-01-30','mallory',750,750,49.69,799.69,799.69,'2026-03-10','CHECK'),
('INV0993','2026-01-30','mallory',360,320,21.20,381.20,381.2,'2026-03-10','CHECK'),
('INV0992','2026-01-12','lisa',140,140,9.28,149.28,149.28,'2026-01-29','BANK'),
('INV0991','2026-01-01','mallory',170,170,11.26,181.26,181.26,'2026-01-29','CHECK'),
('INV0990','2026-01-01','mallory',600,600,39.75,639.75,639.75,'2026-01-29','CHECK'),
('INV0989','2026-01-01','mallory',265,265,17.56,282.56,282.56,'2026-01-29','CHECK'),
('INV0988','2026-01-01','mallory',480,480,31.80,511.80,511.8,'2026-01-29','CHECK');

insert into public.invoices(invoice_number, client_id, invoice_date, status, subtotal, taxable_amount, tax_amount, total, amount_paid, source)
select s.inv, c.id, s.d, case when s.paid >= s.tot then 'paid' else 'sent' end, s.sub, s.taxable, s.tax, s.tot, s.paid, 'invoice_simple_import'
from stg s join public.clients c on c.source_ref = s.k;

insert into public.payments(invoice_id, client_id, amount, paid_date, method, reference)
select i.id, i.client_id, s.paid, s.pd, initcap(s.m), 'Imported from Invoice Simple'
from stg s join public.invoices i on i.invoice_number = s.inv where s.paid > 0;

-- Ledger: invoice = Dr A/R, Cr Revenue + Cr Sales Tax Payable; payment = Dr Bank, Cr A/R
insert into public.ledger_entries(entry_date, account_id, debit, credit, memo, invoice_id, source)
select i.invoice_date, (select id from public.accounts where code='1100'), i.total, 0, 'Invoice '||i.invoice_number, i.id, 'invoice' from public.invoices i
union all
select i.invoice_date, (select id from public.accounts where code='4000'), 0, i.subtotal, 'Invoice '||i.invoice_number, i.id, 'invoice' from public.invoices i
union all
select i.invoice_date, (select id from public.accounts where code='2100'), 0, i.tax_amount, 'Invoice '||i.invoice_number, i.id, 'invoice' from public.invoices i where i.tax_amount > 0;

insert into public.ledger_entries(entry_date, account_id, debit, credit, memo, invoice_id, payment_id, source)
select p.paid_date, (select id from public.accounts where code='1000'), p.amount, 0, 'Payment '||i.invoice_number||' ('||p.method||')', p.invoice_id, p.id, 'payment' from public.payments p join public.invoices i on i.id=p.invoice_id
union all
select p.paid_date, (select id from public.accounts where code='1100'), 0, p.amount, 'Payment '||i.invoice_number||' ('||p.method||')', p.invoice_id, p.id, 'payment' from public.payments p join public.invoices i on i.id=p.invoice_id;
