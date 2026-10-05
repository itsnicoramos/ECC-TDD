# Plan — S1: Schema and RLS

Slice: `SPEC.md` § S1. Stack: Postgres via Supabase local, tested with **pgTAP** (`supabase
test db`). No npm dependencies in this slice.

## Blocking prerequisite

| Need | State | Why it blocks |
|---|---|---|
| Supabase CLI | **not installed** | no `supabase start`, no `supabase test db` |
| Docker daemon | **not running** | local Postgres runs in Docker |

Until both are up, every test in this slice is unrunnable. Writing the migrations anyway and
calling them done would be an `unverified` claim dressed as a verified one — the thing
`skill/SKILL.md` exists to stop. So T1 comes first and nothing is reported as passing until it
has actually run.

## Requirement map

| # | Spec requirement | Task | Test that proves it |
|---|---|---|---|
| R1 | local stack, migrations in `supabase/migrations/` | T2 | `supabase db reset` applies from zero; `supabase test db` runs |
| R2 | `projects` table | T4 | `00_schema`: `has_table`, `has_column`, `col_is_unique(slug)` |
| R3 | `checks` table, unique `(project_id, card_id)` | T4 | `00_schema`: columns, types, FK, `col_is_unique` on the pair |
| R4 | `results` table, state enum | T4 | `00_schema`: `has_enum`, enum labels, FK, nullability |
| R5 | state derived from latest result, append-only | T8 | `02_state`: no result → `pending`; later result wins; UPDATE/DELETE denied |
| R6 | RLS on every table, deny-by-default, first migration | T6 | `01_rls`: `rowsecurity` true on all three; as `anon` select → 0 rows, insert → raises |
| R7 | typed client committed | T9 | none — generated artifact, correctness is the migration's. Staleness check deferred to CI (not in this slice) |

## Task order

1. **T1** Install Supabase CLI, start Docker, `supabase start`. *Blocking.*
2. **T2** `supabase init`; gitignore `supabase/.temp`, `supabase/.branches`.
3. **T3 RED** `supabase/tests/00_schema.test.sql` — fails, no tables exist.
4. **T4 GREEN** `supabase/migrations/<ts>_init_bench_schema.sql` — enum + three tables.
5. **T5 RED** `supabase/tests/01_rls.test.sql` — fails, RLS not enabled.
6. **T6 GREEN** enable RLS on all three tables; **no policies at all** — deny-by-default is
   the absence of policy, not a policy that denies.
7. **T7 RED** `supabase/tests/02_state.test.sql` — fails, no view.
8. **T8 GREEN** `checks_with_state` view, `security_invoker = true`.
9. **T9** `supabase gen types typescript > supabase/database.types.ts`, committed.
10. **T10** Verify: `supabase db reset` (migrations apply clean from zero) + `supabase test db`.

## Schema shape

```sql
create type check_result_state as enum ('pass', 'fail', 'blocked');

create table checks (
  ...
  expect     text not null,          -- see note
  risk_rank  int  not null default 0,
  unique (project_id, card_id)
);

create view checks_with_state with (security_invoker = true) as
select c.*, coalesce(r.state::text, 'pending') as state, r.reading, r.observed_at
from checks c
left join lateral (
  select state, reading, observed_at from results
  where check_id = c.id order by observed_at desc, id desc limit 1
) r on true;
```

Two deliberate details:

- **`expect` is `NOT NULL`.** The skill's hard rule — never ask for an observation without
  stating what success looks like — becomes a database constraint. A card step with no expected
  reading cannot be stored at all.
- **`security_invoker = true` on the view.** Without it a view runs with its owner's rights and
  **silently bypasses RLS** on the tables beneath. That is a fail-open bug that no amount of
  reading the policies would reveal, so `01_rls` asserts the view is filtered too.

## Files touched

`supabase/config.toml`, `supabase/migrations/<ts>_init_bench_schema.sql`,
`supabase/tests/{00_schema,01_rls,02_state}.test.sql`, `supabase/database.types.ts`,
`.gitignore`.

## Decisions (GATE 1, approved 2026-10-04)

1. **RLS deny-by-default contradicts S3.** → **server-side reads until S6.** With no policies and no auth until S6, the console
   cannot read anything with the anon key — so S3 as written is unbuildable between S1 and S6.
   *Lean:* S3/S4 read and write **server-side only**, using the service-role key in Next.js
   route handlers (never shipped to the browser); S6 replaces that with real user policies.
   Good architecture regardless, and it means no temporary permissive policy is ever created —
   those survive into production.
2. **Append-only enforcement.** → **trigger, as leaned.** Deny-by-default RLS already blocks UPDATE/DELETE for `anon`
   and `authenticated`, but **`service_role` bypasses RLS entirely**, and the agent uses
   `service_role`. True append-only needs a `before update or delete` trigger that raises.
   *Lean:* add the trigger. Cost: fixing a mistyped reading then needs a migration, not an
   `UPDATE`. That cost is the point of an append-only log.
3. **`fail` requires a reading or a note** → **constraint lands in S1.** — the spec places this in S4 (console write path),
   but a `CHECK` constraint in S1 is the only place it cannot be bypassed, including by the
   agent. *Lean:* put it in S1 and note the deviation under the S4 item.
4. **`pnpm` is not installed** → **spec switches to `npm` at S2.**, and S2's commands are written as `pnpm bench push`. Doesn't
   block S1. *Lean:* switch the spec to `npm` rather than add a package manager.

## Out of scope for S1

The Next.js app, the `bench` CLI (S2), auth and `projects.owner_id` (S6), realtime
configuration, seed data beyond test fixtures, CI.

## Suggestions (not building — outside the spec)

- `checks.updated_at`, maintained by trigger — S2 upserts cards, and drift will be hard to
  debug without it.
- Add `projects.owner_id` (nullable) now so S6 is a policy change rather than a schema change.

## Corrections made during execution

- **One migration file, grown across the three RED/GREEN cycles** — not three files. R6 says
  RLS ships *in the first migration, not added later*; a separate RLS migration would mean
  migration 1 creates briefly-open tables. The file is edited in place and re-applied with
  `supabase db reset` between cycles.
- **Docker is Colima here, not Docker Desktop.** `colima start` (profile: 2 CPU / 3 GiB /
  8 GiB), not `open -a Docker`. T1 as originally written was wrong about this machine.
- **Supabase services trimmed to fit 3 GiB.** `realtime`, `studio`, `storage`, `local_smtp`,
  `edge_runtime` and `analytics` disabled in `supabase/config.toml`; `api`, `db` and `auth`
  stay (auth because `results.observed_by` references `auth.users`). **S5 must re-enable
  `realtime`** — that is a forward dependency, recorded here so it is not discovered as a bug.
- **pgTAP is created inside each test's transaction and rolled back**, rather than enabled by a
  migration. Keeps a test framework out of the production schema.
