-- Incremental migration for projects that already ran 002_add_cleaners.sql
-- (which didn't have a role column). Safe to run once against the live
-- project. New fresh projects should just use the updated schema.sql
-- instead -- this file is only for catching up.

alter table cleaners add column if not exists role text not null default 'cleaner';

-- One-time: promote Janna's own roster row to owner so she can access
-- Book/Edit Job and Team management. Everyone else defaults to 'cleaner'
-- (view + notes + mark-complete only). Adjust the name below if hers
-- doesn't match exactly.
update cleaners set role = 'owner' where name = 'Janna';
