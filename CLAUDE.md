# CRITICAL — Read Before Writing Any Code

1. **ALWAYS push to `main`.** Never leave work only on a feature branch.
2. **ALWAYS bump `APP_REV`** in jannas.html on every commit.
3. Set git identity before first commit:
   `git config user.email "..." && git config user.name "Claude"`
4. Deploy takes ~1 minute after push to main (Vercel project
   `insight17/jannas-cleaning-app`, connected via the Vercel dashboard).
   Live URL: https://jannas-cleaning-app.vercel.app — the long
   `jannas-cleaning-<hash>-insight17.vercel.app` URLs are frozen per-deploy
   snapshots, never share those. `vercel.json` rewrites `/` → `/jannas.html`
   (the file is NOT renamed to index.html) — that rewrite is what prevents
   the root-URL 404. `.vercelignore` keeps docs/SQL off the public site.
   GitHub Pages / the `gh-pages` branch is retired as of r18; don't re-add
   a Pages workflow.
   Gotcha (hit at r18): Vercel's Production Branch is copied from the
   GitHub repo's *default branch* at import time. This repo's default was
   a stale `claude/...` branch, so Vercel shipped r2. Both are now `main`
   — if a deploy ever shows an old APP_REV, check GitHub Settings →
   Default branch and Vercel Settings → Git → Production Branch first.
5. Prefix every commit message with `rNNN:` matching the new APP_REV.

## jannas.html IS the app
All user-facing changes go in jannas.html. No auth, no backend server —
Supabase JS client direct from the browser, RLS-gated.

## Supabase project
`SUPABASE_URL` / `SUPABASE_ANON_KEY` near the top of jannas.html are wired
to the live project (`hcoslltuiltkkbqcgtzm`). Run `supabase/schema.sql`
against it (SQL Editor → New query) if the tables aren't there yet —
until that's done the app loads but every fetch/insert will fail.

## Data model
`clients` is a real table (id, name, phone, email, address) — not derived
from jobs. `jobs.client_id` and `notes.client_id` are foreign keys into it.
Job/note forms use a client picker (select existing, or "+ New client…"
inline). There's also now a dedicated "+ Add Client" button and ✏️ edit
per row on the Clients screen (owner-only, like Book/Edit Job) for
creating/editing a client without going through a job or note. Clicking
the client's avatar/name opens the same Edit Client modal (owner-only;
inert for cleaners, matching the Schedule slot click pattern).

`jobs.color` / `notes.color` were dropped from the original prototype's
mock data — badge and dot colors are derived client-side from `status`
(dotColor map) or a hash of the row's id (colorFor), not stored.

`cleaners` is a real table (id, name, phone, email, active, role) managed
on the Team screen (owner-only). `jobs.cleaner` stays free text (not a FK)
so existing job history survives roster changes — the Assign Cleaner
dropdown is just populated from `cleaners.filter(active)`.

`properties` is a real table (id, client_id FK, label, address) holding a
client's saved/named job-site addresses (e.g. a renter who has us clean
both their own unit and a second rental they manage) — managed inline
inside the (owner-only) Edit Client modal, no separate screen. `jobs.address`
stays free text (not a FK to this table either), exactly like
`jobs.cleaner` — the "Saved Property" dropdown in Book/Edit Job is a
one-way autofill convenience only, so editing/deleting a property never
retroactively touches already-booked jobs. New clients auto-seed a first
`properties` row from whatever address was typed at creation time (via
`resolveClientId()` for the ClientPicker's "+ New client…" inline path,
via `handleAddClient()` for the standalone Add Client modal, and via
`handleEditClientSave()` when an address is saved on a client that has no
properties yet — e.g. Invoice Simple imports, which arrive address-less) — that
insert is wrapped in its own non-fatal try/catch so a failure there never
blocks the client/job/note creation that triggered it.

## Address suggestions (AddressInput)
Every address field (Book/Edit Job, Add/Edit Client, ClientPicker's new
client, Edit Client's Add Property) is `<AddressInput value onChange>` —
a top-level component (not an inner one, so no remount-per-keystroke).
Type-ahead comes from Photon (photon.komoot.io, free OpenStreetMap data,
no key), debounced 300ms, min 4 chars, biased to Somers Point NJ and
boxed to NJ/PA/DE/NY/MD (`PHOTON_BIAS` / `PHOTON_BBOX`). It's a
convenience only: the value is still free text, and lookup failures are
swallowed, so if Photon is down people just type. Upgrade path if quality
is ever not enough: swap the fetch in `AddressInput` for Google Places.
Note: Claude's cloud sandbox can't reach photon.komoot.io, so test live.

## Importing clients from Invoice Simple
Janna's billing lives in Invoice Simple; its "Invoice Summary" .xlsx export
(copy in Google Drive → "Janna cleaning app" folder) was the source of the
Sep 30 2026 client import. Gotchas: it has TWO phone columns (`Mobile` and
`Phone`) — read both, prefer Mobile; the first import only read `Phone` and
dropped 5 numbers (fixed r22). It has NO address column — Janna sometimes
types the address into the client name (e.g. "Lisa Schatz 1705 Wesley"),
so split that into `address` and seed a `properties` row. One row per
invoice, so de-dupe clients by name.

## Live DB can be ahead of this repo — check before building
Cowork sessions have changed the live Supabase DB directly without leaving
files here (that happened Sep 30 2026 — copies now in
`supabase/cowork_20260930/005-009`, do NOT re-run them). Before any schema
work, compare `supabase_migrations.schema_migrations` on the live project
with the files in `supabase/`. Gotcha: the Supabase MCP asks the user to
confirm any SQL containing DELETE (even inside a function body) and times
out after 60s if nobody approves — put such SQL in a file and have the user
paste it into the SQL Editor (that's what `010b_finish_in_sql_editor.sql` was).

## Invoicing (owner-only, real login)
Tables (from the Cowork schema): `invoices` (invoice_number, invoice_date,
due_date, status sent/partial/paid/void/draft, subtotal, taxable_amount,
tax_rate as a FRACTION e.g. 0.06625, tax_amount, total, amount_paid,
`balance_due` GENERATED, source `invoice_simple_import` | `app`),
`invoice_items` (unit_price, `amount` GENERATED, sort_order, job_id),
`payments` (paid_date, method, reference), `accounts` + `ledger_entries`
(double-entry: invoice = Dr 1100 A/R / Cr 4000 Revenue / Cr 2100 Sales Tax;
payment = Dr 1000 Bank / Cr 1100 A/R). 83 Invoice Simple invoices + 76
payments were imported as totals only (no line items) — the app shows them
read-only (print/pay/delete, no Edit).

RLS: these tables have NO anon policy; only `authenticated` + `is_owner()`
(cleaners row with role owner whose `auth_user_id` = auth.uid()). So Janna
signs in with Supabase Auth (email+password, avatar menu → "Sign in as
owner"); a trigger links a new auth user to the cleaners row with the same
email (jannalflexer@gmail.com). IMPORTANT: once signed in, requests run as
`authenticated`, so the anon policies on clients/jobs/etc. no longer apply —
the owner policies cover them. A signed-in non-owner would see an EMPTY app,
which is why `handleSignIn` checks `rpc('is_owner')` and signs back out if
false. Switch user / Lock device also sign out.

All invoice writes go through RPCs (migration 010/010b, SECURITY INVOKER +
is_owner() check, one transaction each): `save_invoice(p jsonb)` (recomputes
totals server-side, replaces items, rewrites the invoice's ledger rows,
copies a qty-1 job line's rate onto `jobs.price`), `record_payment`,
`delete_payment`, `delete_invoice`. Never write these tables directly from
the client or the ledger will drift.

`jobs.price` (optional, anon-visible like the rest of jobs) + `lastPriceFor()`
= repeat-cleaning price memory: Book Job pre-fills the client's last priced
job (same address first) until the user types a price (`priceTouched`).
A completed job is "un-invoiced" when no `invoice_items.job_id` points at it.
Business name/address/phone/email, default terms and footer are
PLACEHOLDERS in the `BUSINESS` / `DEFAULT_TERMS` / `INVOICE_FOOTER`
constants (values in [brackets] render red on screen). Print/PDF uses
`window.print()` + an `@media print` block that shows only `.invoice-doc`.
Email = `mailto:` (user attaches the PDF). No online payments.

## Roles: owner vs cleaner
`cleaners.role` is `'owner'` or `'cleaner'` (default `'cleaner'` on every
new row, including self-adds via the picker — nobody can grant themselves
owner). `isOwner` is computed each render from `cleaners.find(c => c.id
=== currentUser.id)`, not cached in localStorage, so a role change takes
effect on the next data refresh without needing to re-auth that device.
Owner-only: Book Job, Edit/Delete Job, Add/Edit Client, and all of Team
(add/edit/deactivate cleaners, including who's owner). Everyone (owner +
cleaners): view all screens, mark a job complete, add notes (including the
"+ New client…" inline path in that modal, which is not owner-gated).
This is enforced both in the UI
(buttons/nav hidden) and inside the mutating handlers via `requireOwner()`
— defense in depth, though ultimately still just UX since RLS is open.
There is exactly one bootstrapping wrinkle: since Team is owner-gated and
new `cleaners` rows default to `'cleaner'`, the very first owner has to be
promoted directly in SQL (see `supabase/003_add_cleaner_role.sql`) — after
that, promotions/demotions can happen from the Edit Cleaner modal's Role
field.

## Schedule screen: calendar + list toggle
`scheduleView` (`'calendar'` default, or `'list'`) picks between a month
grid and the original day-grouped list — both read the same `scheduleDays`
map, and `renderDayPanel(date, dayJobs)` is the single shared renderer for
"a day's jobs" so the two views never drift apart. `calendarMonth` is a
`Date` always built via the numeric `Date(y, m, 1)` constructor (never
string-parsed) — that's a deliberate, different code path from this
file's usual `dateString + "T12:00:00"` idiom, which exists only to
defuse ambiguity when parsing a *stored* `"YYYY-MM-DD"` string; building a
Date from plain numbers has no such ambiguity, so don't "fix" it by adding
`T12:00:00` there. `selectedDate` defaults to today (calendar opens with
today's cell highlighted and its jobs already expanded below the grid).
The owner-only "+ Book this day" button is a *second* call site that
seeds `bookForm` (from `EMPTY_BOOK_FORM`, with `date` overridden) before
calling the existing `setShowBookModal(true)` — the topbar's "+ Book Job"
button is not the only way into that modal.

## Trusted-device gate (not real auth)
`APP_PASSPHRASE` near the top of jannas.html holds the current shared
passphrase for staff devices. On first load a device must enter it once;
that unlocks `localStorage[jannas_trusted_v1]="true"`
permanently on that device (no expiry, no per-user check). After that, the
user picks their name from `cleaners` (or adds themselves inline if the
roster is empty) and it's stored as `localStorage[jannas_user_v1]`. This
is a UX-level "who's on this device" convenience, not security — RLS still
grants the open anon key full read/write, matching the rest of the app's
security posture. Switching users doesn't re-prompt the passphrase by
design (shared-tablet model); "Lock device" in the avatar menu clears both
localStorage keys and re-shows the passphrase gate.

## Self-Update Protocol
Before every commit, ask: would a new session be confused by something
introduced here? If yes, update this file in the same commit.
