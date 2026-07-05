# Janna's Cleaning Service

Single-file React app for managing a residential cleaning business: jobs,
schedule, clients, and cleaner notes.

## Stack

- **UI:** React 18 (UMD build from CDN)
- **JSX:** Babel Standalone, transpiled in-browser — no build step
- **DB:** Supabase (Postgres), open anon key + RLS, no auth in v1
- **Hosting:** GitHub Pages via the `gh-pages` branch
- **Deploy:** GitHub Actions — push to `main` touching `jannas.html` auto-deploys

## Repo layout

```
/
├── jannas.html             # entire app: HTML + <style> + <script type="text/babel">
├── supabase/schema.sql     # tables + RLS policies to run once on a new Supabase project
├── CLAUDE.md               # commit/deploy rules for future sessions
└── .github/workflows/deploy.yml
```

## Setup

1. Create a Supabase project.
2. Run `supabase/schema.sql` against it (SQL Editor → New query).
3. In `jannas.html`, set `SUPABASE_URL` and `SUPABASE_ANON_KEY` to the
   project's values (Project Settings → API).
4. Push to `main` — GitHub Actions publishes `jannas.html` as `index.html`
   to the `gh-pages` branch.
5. Enable Pages once: Settings → Pages → source = `gh-pages` branch, root.

## Data model

- **clients** — `id, name, phone, email, address` — a real table, not
  derived from job history.
- **jobs** — `id, client_id (FK), address, type, recurring, status, date,
  time, cleaner, notes` — `address` is the job site address, which can
  differ from the client's billing address.
- **notes** — `id, client_id (FK), text, date` — cleaner-facing notes per
  client.

Badge/dot colors are derived client-side from job `status`, not stored.

## Screens

Dashboard, Jobs, Schedule, Clients, Notes — plus global Book Job / Edit
Job / Add Note modals, all inlined directly in the render tree (not inner
component functions, to avoid remounting on every keystroke).

## Deferred (not built yet)

Client-facing login/portal, cleaner accounts, calendar view, push
notifications, auto-generated recurring jobs, invoicing/payments,
multi-tenant support.
