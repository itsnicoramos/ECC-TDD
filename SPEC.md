# Bench Console — SPEC

The second half of `hardware-bringup`. The skill produces bench cards in a terminal; the
operator is across the room with a meter in one hand. This closes that gap: the card appears
on their phone, they tap a result and type a reading, and the agent sees it land.

Consumed by the `spec-to-ship` skill. Slices are sized to be reviewed in one sitting.

## The contract

Three participants, one truth:

```
agent (terminal)  --write checks-->  Supabase  <--read/write results--  phone (Next.js)
                  <--read results--    |
                                       | realtime
                  .bringup/state.md  <-+  generated export, committed
```

**Supabase is the source of truth for check state. `.bringup/state.md` is a generated,
committed export** — human-readable, diffable, and still there when Supabase is down or the
project is archived. One direction only: db → file. Nothing reads the file back as authority.
This is the decision that keeps two writers from creating two truths.

**Bench-card ids (`B-04`) are stable and never reused** — already a hard rule in the skill, and
now a foreign key in practice. The db keys on `(project_id, card_id)`.

## S1 — Schema and RLS

- [x] Supabase project runs locally via `supabase start`; migrations in `supabase/migrations/`
- [x] `projects` table: `id`, `slug` (unique), `name`, `created_at`
- [x] `checks` table: `id`, `project_id`, `card_id` (text, e.g. `B-04`), `title`, `setup`, `action`,
      `expect`, `if_not`, `why`, `risk_rank` (int), `created_at`; unique on `(project_id, card_id)`
- [x] `results` table: `id`, `check_id`, `state` enum `pass | fail | blocked`, `reading` (text, nullable),
      `note` (text, nullable), `observed_at`, `observed_by`
- [x] A check's current state is **derived from its latest result**, never stored on `checks`.
      No result at all means `pending`. Results are append-only — a re-test adds a row, so the
      history of a flaky check is visible rather than overwritten.
- [x] RLS enabled on every table, with deny-by-default policies, from the first migration.
      Not added later. A bench log is not sensitive, but an anon-writable table is a vandalism
      target and a bad thing to teach anyone reading this repo.
- [x] Typed client generated via `supabase gen types typescript`, committed

> **Local service set (recorded during S1).** `supabase/config.toml` disables `realtime`,
> `studio`, `storage`, `local_smtp`, `edge_runtime` and `analytics` so the stack fits the
> 3 GiB Colima VM on the dev machine. `api`, `db` and `auth` stay enabled — `auth` because
> `results.observed_by` references `auth.users`. **S5 must re-enable `realtime`**, which is a
> forward dependency recorded here rather than discovered later as a bug.

## S2 — Agent side

- [ ] `pnpm bench push <card.json>` upserts checks for a project on `(project_id, card_id)`
- [ ] `pnpm bench pull` reads current state and regenerates `.bringup/state.md`
- [ ] Service-role key read from `.env.local` only; `.env.local` gitignored; `.env.example`
      committed with every key named and no values
- [ ] Both commands work against local Supabase with no cloud project configured

## S3 — Console, read path

- [ ] Next.js App Router, TypeScript strict, Tailwind
- [ ] `/p/<slug>` lists that project's checks, **pending first, then by `risk_rank`**
- [ ] A check shows title, setup, action, expect, if-not — `expect` and `if_not` are never
      truncated or hidden behind a tap. An operator who can't see what success looks like
      cannot run the check.
- [ ] Phone-first: readable at arm's length, tap targets usable with one hand
- [ ] Verified checks are visually distinct from pending, and show their recorded reading

## S4 — Console, write path

- [ ] Pass / Fail / Blocked, plus an optional reading and note
- [ ] Reading is a free-text field, not a number — operators write `4.97 V @ 2.1 A` and
      `dips to 4.1 on start`, and forcing a numeric type would lose the useful half
- [ ] Fail requires either a reading or a note before it submits. A bare "fail" tells the
      agent nothing it can diagnose
      > *Deviation (approved at S1 GATE 1): already enforced in the database as
      > `results_fail_needs_evidence`, so the agent writing through `service_role` is held to
      > it too. S4 only needs the UI to surface the error before submitting.*
- [ ] Optimistic UI with rollback on error; a dropped submit must never look like a success

## S5 — Realtime and export

- [ ] Console subscribes to `results` inserts and updates without a refresh
- [ ] `pnpm bench pull` regenerates `.bringup/state.md` in the table format the skill reads
- [ ] Export records the reading and the observation date, not just the state

## S6 — Auth

- [ ] Supabase magic-link email auth
- [ ] A project is visible only to its owner and invited operators
- [ ] RLS policies enforce this at the database, not in the UI

## Out of scope for v1

Multi-project dashboards, photo upload, offline queueing, push notifications, editing cards
from the phone (the agent owns the card; the phone owns the result), anything that writes back
into the agent's repo other than `.bringup/state.md`.

## Deferred from review

Raised at a GATE 2 and consciously not fixed. Each names the slice that should absorb it.

- [ ] **(S1)** Behavioural test that `anon` cannot read through `checks_with_state`. The
      `security_invoker` reloption is asserted, and the behaviour was verified by hand
      (owner sees 1 row, `anon` sees 0), but no test holds it. The reloption assertion already
      catches the obvious regression, which is why this was deferred.
- [ ] **(S3)** Staleness check for `supabase/database.types.ts` — the schema can drift from the
      committed types silently. Needs the `package.json` that arrives with the console.
- [ ] **(S6)** `projects.owner_id`. Absent by design in S1, so S6 is a schema change rather
      than a pure policy change.
- [ ] **(S2)** `checks.updated_at` maintained by trigger. Suggested during S1, outside the
      spec: S2 upserts cards and drift will be hard to debug without it.

## Open questions

1. Does the agent poll for results, or is a result pulled only when asked? Polling costs
   nothing locally but is a bad habit to ship. Leaning: pull on demand, and the skill's gate
   tells the operator to say "done" in chat.
2. `observed_by` before S6 lands — free-text name, or null? Leaning: null, so there's no
   fake identity in the log pre-auth.
3. Does a wiring change invalidate verified checks automatically? The skill says a human must
   say which change invalidated what. Keeping it manual for v1.
