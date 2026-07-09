# CRITICAL — Read Before Writing Any Code

1. **ALWAYS push to `main`.** Never leave work only on a feature branch.
2. **ALWAYS bump `APP_REV`** in jannas.html on every commit.
3. Set git identity before first commit:
   `git config user.email "..." && git config user.name "Claude"`
4. Deploy takes ~1 minute after push to main (GitHub Actions → gh-pages).
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
Job/client forms use a client picker (select existing, or "+ New client…"
inline) since there's no dedicated client-creation screen yet.

`jobs.color` / `notes.color` were dropped from the original prototype's
mock data — badge and dot colors are derived client-side from `status`
(dotColor map) or a hash of the row's id (colorFor), not stored.

`cleaners` is a real table (id, name, phone, email, active, role) managed
on the Team screen (owner-only). `jobs.cleaner` stays free text (not a FK)
so existing job history survives roster changes — the Assign Cleaner
dropdown is just populated from `cleaners.filter(active)`.

## Roles: owner vs cleaner
`cleaners.role` is `'owner'` or `'cleaner'` (default `'cleaner'` on every
new row, including self-adds via the picker — nobody can grant themselves
owner). `isOwner` is computed each render from `cleaners.find(c => c.id
=== currentUser.id)`, not cached in localStorage, so a role change takes
effect on the next data refresh without needing to re-auth that device.
Owner-only: Book Job, Edit/Delete Job, and all of Team (add/edit/deactivate
cleaners, including who's owner). Everyone (owner + cleaners): view all
screens, mark a job complete, add notes. This is enforced both in the UI
(buttons/nav hidden) and inside the mutating handlers via `requireOwner()`
— defense in depth, though ultimately still just UX since RLS is open.
There is exactly one bootstrapping wrinkle: since Team is owner-gated and
new `cleaners` rows default to `'cleaner'`, the very first owner has to be
promoted directly in SQL (see `supabase/003_add_cleaner_role.sql`) — after
that, promotions/demotions can happen from the Edit Cleaner modal's Role
field.

## Trusted-device gate (not real auth)
`APP_PASSPHRASE` near the top of jannas.html is a placeholder — set a real
shared passphrase before handing devices to staff. On first load a device
must enter it once; that unlocks `localStorage[jannas_trusted_v1]="true"`
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
