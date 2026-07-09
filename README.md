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
├── jannas.html                       # entire app: HTML + <style> + <script type="text/babel">
├── supabase/schema.sql               # full schema + RLS policies, for a fresh Supabase project
├── supabase/002_add_cleaners.sql     # incremental migration adding `cleaners` to an already-live project
├── supabase/003_add_cleaner_role.sql # incremental migration adding `cleaners.role` (owner vs cleaner)
├── CLAUDE.md                         # commit/deploy rules for future sessions
└── .github/workflows/deploy.yml
```

## Setup

`SUPABASE_URL` / `SUPABASE_ANON_KEY` in `jannas.html` already point at the
live project (`hcoslltuiltkkbqcgtzm`).

1. Run `supabase/schema.sql` against it (SQL Editor → New query) if the
   `clients` / `jobs` / `notes` / `cleaners` tables aren't there yet. If
   you already ran an older version that predates `cleaners` or its
   `role` column, run `supabase/002_add_cleaners.sql` and/or
   `supabase/003_add_cleaner_role.sql` instead to catch up.
2. Promote the one owner: `003_add_cleaner_role.sql` includes a one-time
   `update cleaners set role = 'owner' where name = '...'` — run it (or
   the equivalent) once so someone can reach Team/Book/Edit Job. After
   that, ownership can be reassigned from the Edit Cleaner modal's Role
   field instead of SQL.
3. Set `APP_PASSPHRASE` in `jannas.html` to a real shared passphrase before
   handing devices to staff (see Trusted-device gate below).
4. Push to `main` — GitHub Actions publishes `jannas.html` as `index.html`
   to the `gh-pages` branch.
5. Enable Pages once: Settings → Pages → source = `gh-pages` branch, root.

To point the app at a different Supabase project, swap the two Supabase
constants near the top of `jannas.html` (Project Settings → API for the
URL and anon/publishable key).

## Data model

- **clients** — `id, name, phone, email, address` — a real table, not
  derived from job history.
- **jobs** — `id, client_id (FK), address, type, recurring, status, date,
  time, cleaner, notes` — `address` is the job site address, which can
  differ from the client's billing address.
- **notes** — `id, client_id (FK), text, date` — cleaner-facing notes per
  client.
- **cleaners** — `id, name, phone, email, active, role` — staff roster,
  managed on the Team screen (owner-only). `jobs.cleaner` is still free
  text (not a FK to this table) so existing job history isn't disturbed
  by roster changes.

Badge/dot colors are derived client-side from job `status`, not stored.

## Roles

`cleaners.role` is `'owner'` (Janna) or `'cleaner'` (everyone else,
including anyone who self-adds via the trusted-device picker — new rows
always default to `'cleaner'`). Only the owner can book/edit/delete jobs,
add/edit clients, or manage the Team roster; cleaners can view every
screen, mark a job complete, and add notes (including creating a new
client inline from that modal — the only client-creation path that isn't
owner-gated). This is a UX-level restriction (buttons/nav hidden, mutating
handlers double-check `isOwner`) — it is not real per-user auth, since the
Supabase anon key is still open + RLS-gated the same as the rest of the
app.

## Screens

Dashboard, Jobs, Schedule, Clients, Notes, Team — plus global Book Job /
Edit Job / Add Note / Add Client / Edit Client / Add Cleaner / Edit
Cleaner modals, all inlined directly in the render tree (not inner
component functions, to avoid
remounting on every keystroke).

## Trusted-device gate

On first load, a device must enter a shared passphrase (`APP_PASSPHRASE`
in jannas.html) before seeing any data. This is a lightweight "who's on
this device" gate for a shared tablet/phone, not real authentication — the
Supabase anon key is still open + RLS-gated the same as everywhere else in
the app. Once unlocked, the device stays unlocked (`localStorage`, no
expiry) and the user picks their name from the `cleaners` roster (or adds
themselves inline if the roster is empty). Switching users doesn't
re-prompt the passphrase; "Lock device" in the avatar menu does.

## Deferred (not built yet)

Client-facing login/portal, real per-user auth/permissions, calendar view,
push notifications, auto-generated recurring jobs, invoicing/payments,
multi-tenant support.
