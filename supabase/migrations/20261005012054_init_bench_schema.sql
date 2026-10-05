-- S1 — bench console schema.
-- Grown in place across this slice RED/GREEN cycles: SPEC.md R6 requires RLS in the first
-- migration rather than bolted on afterwards, so there is never a migration that leaves
-- these tables open.

create type public.check_result_state as enum ('pass', 'fail', 'blocked');

-- A bench project. One per board or repo under bring-up.
create table public.projects (
  id          uuid primary key default gen_random_uuid(),
  slug        text        not null unique,
  name        text        not null,
  created_at  timestamptz not null default now()
);

-- One step of a bench card, written by the agent.
-- expect is NOT NULL on purpose: the skill rule is that an observation is never requested
-- without stating what success looks like, so a step without one cannot exist.
create table public.checks (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid        not null references public.projects (id) on delete cascade,
  card_id     text        not null,
  title       text        not null,
  setup       text,
  action      text,
  expect      text        not null,
  if_not      text,
  why         text,
  risk_rank   integer     not null default 0,
  created_at  timestamptz not null default now(),
  -- bench-card ids are stable and never reused, which makes this pair a real key
  unique (project_id, card_id)
);

-- What an operator observed. Append-only; a re-test is a new row.
create table public.results (
  id           uuid primary key default gen_random_uuid(),
  check_id     uuid        not null references public.checks (id) on delete cascade,
  state        public.check_result_state not null,
  reading      text,
  note         text,
  observed_at  timestamptz not null default now(),
  observed_by  uuid references auth.users (id)
);

-- Supports "latest result for this check", which is how state is derived.
create index results_check_latest_idx
  on public.results (check_id, observed_at desc, id desc);

-- R6 — row level security, in this same migration so that no version of this schema has
-- ever been open. Deny by default means RLS on and deliberately NO policies: nothing reaches
-- these tables through the anon or authenticated roles. Supabase grants new public tables to
-- anon by default, so without this the bench log is world-readable and world-writable.
--
-- Until S6 adds real user policies, the console reads and writes server-side with the
-- service-role key, which bypasses RLS by design and never reaches the browser.
alter table public.projects enable row level security;
alter table public.checks   enable row level security;
alter table public.results  enable row level security;

-- R5 — current state, derived. A check with no result is pending; otherwise the newest
-- result wins. Deliberately a view and not a column: a stored state can disagree with the
-- results it is supposed to summarise, and then nobody knows which to trust.
--
-- security_invoker is load-bearing. Without it a view executes with its OWNER's privileges
-- and silently returns rows that RLS would have hidden. Nothing in the policy definitions
-- would reveal that; it is asserted in 02_state.test.sql instead.
create view public.checks_with_state
  with (security_invoker = true) as
select
  c.*,
  coalesce(r.state::text, 'pending') as state,
  r.reading,
  r.note,
  r.observed_at
from public.checks c
left join lateral (
  select state, reading, note, observed_at
  from public.results
  where check_id = c.id
  order by observed_at desc, id desc
  limit 1
) r on true;

-- GATE 1 decision 3: a fail must carry evidence. A bare "it failed" gives the agent nothing
-- to diagnose, and the diagnosis rules in skill/SKILL.md need a measurement. Enforced as a
-- CHECK rather than in the UI so that service_role — the agent itself — is held to it too.
alter table public.results
  add constraint results_fail_needs_evidence
  check (
    state <> 'fail'
    or coalesce(nullif(btrim(reading), ''), nullif(btrim(note), '')) is not null
  );

-- GATE 1 decision 2: append-only. RLS already stops anon and authenticated, but service_role
-- bypasses RLS entirely and that is the role the agent uses, so the guard has to live in a
-- trigger. Cost, accepted knowingly: correcting a mistyped reading means a new row, and a
-- project with results cannot be deleted because the cascade hits this guard.
create or replace function public.results_are_append_only()
returns trigger
language plpgsql
as $$
begin
  raise exception
    'results are append-only: a re-test is a new row, not an edit (attempted % on result %)',
    tg_op, coalesce(old.id::text, '(unknown)');
end;
$$;

create trigger results_no_update
  before update on public.results
  for each row execute function public.results_are_append_only();

create trigger results_no_delete
  before delete on public.results
  for each row execute function public.results_are_append_only();

-- GATE 2 must-fix. Supabase grants ALL on new public tables to anon and authenticated, and
-- that set includes TRUNCATE. TRUNCATE is exempt from RLS and does not fire row-level
-- triggers, so an anonymous client could wipe this append-only log straight through both
-- guards above. Demonstrated before fixing: as anon, results went 1 -> 0 via TRUNCATE TABLE.
revoke truncate, trigger, references
  on public.projects, public.checks, public.results
  from anon, authenticated;

-- Defence in depth. service_role keeps TRUNCATE on purpose — it is the trusted agent role and
-- revoking from it is not a security boundary — so the guarantee has to be a trigger, not a
-- grant. Statement-level, because TRUNCATE has no rows to fire per-row triggers on.
create or replace function public.results_no_truncate()
returns trigger
language plpgsql
as $$
begin
  raise exception
    'results are append-only: TRUNCATE is not permitted (drop this trigger deliberately if you truly mean to purge)';
end;
$$;

create trigger results_no_truncate
  before truncate on public.results
  for each statement execute function public.results_no_truncate();
