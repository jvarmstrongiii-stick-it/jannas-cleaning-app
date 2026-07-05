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

## Supabase setup required before this app works
`SUPABASE_URL` / `SUPABASE_ANON_KEY` near the top of jannas.html are
placeholders. Create a Supabase project, run `supabase/schema.sql` against
it (SQL Editor → New query), then paste the project URL and anon key in.
Until that's done the app will load but every fetch/insert will fail.

## Data model
`clients` is a real table (id, name, phone, email, address) — not derived
from jobs. `jobs.client_id` and `notes.client_id` are foreign keys into it.
Job/client forms use a client picker (select existing, or "+ New client…"
inline) since there's no dedicated client-creation screen yet.

`jobs.color` / `notes.color` were dropped from the original prototype's
mock data — badge and dot colors are derived client-side from `status`
(dotColor map) or a hash of the row's id (colorFor), not stored.

## Self-Update Protocol
Before every commit, ask: would a new session be confused by something
introduced here? If yes, update this file in the same commit.
