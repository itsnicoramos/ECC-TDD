-- S1 / R6 — row level security.
-- Deny-by-default is the ABSENCE of any policy, not a policy that denies. These tests assert
-- both the flag and the behaviour, because a table with RLS enabled and a careless policy
-- fails open and looks identical in the schema.
begin;
create extension if not exists pgtap with schema extensions;
select plan(12);

select is((select relrowsecurity from pg_class where oid = 'public.projects'::regclass), true,
  'projects has row level security enabled');
select is((select relrowsecurity from pg_class where oid = 'public.checks'::regclass), true,
  'checks has row level security enabled');
select is((select relrowsecurity from pg_class where oid = 'public.results'::regclass), true,
  'results has row level security enabled');

select policies_are('public', 'projects', '{}'::text[],
  'projects has no policies at all (deny by default)');
select policies_are('public', 'checks', '{}'::text[],
  'checks has no policies at all (deny by default)');
select policies_are('public', 'results', '{}'::text[],
  'results has no policies at all (deny by default)');

-- Seed as the migration owner, which bypasses RLS, then prove anon cannot reach it.
insert into public.projects (id, slug, name)
  values ('11111111-1111-1111-1111-111111111111', 'dum-e', 'DUM-E');
insert into public.checks (project_id, card_id, title, expect)
  values ('11111111-1111-1111-1111-111111111111', 'B-01',
          '5V rail under four-servo load', '4.9 V or better at 2 A');

set local role anon;
select is((select count(*) from public.projects), 0::bigint, 'anon reads no projects');
select is((select count(*) from public.checks), 0::bigint, 'anon reads no checks');
select throws_ok(
  $$insert into public.projects (slug, name) values ('sneaky', 'Sneaky')$$,
  '42501', null,
  'anon cannot insert a project'
);
reset role;

-- GATE 2 should-fix: authenticated carries grants identical to anon and was untested. S6 is
-- when authenticated users start existing, so this gap matures exactly when it gets dangerous.
set local role authenticated;
select is((select count(*) from public.projects), 0::bigint, 'authenticated reads no projects');
select is((select count(*) from public.checks), 0::bigint, 'authenticated reads no checks');
select throws_ok(
  $$insert into public.projects (slug, name) values ('sneaky-auth', 'Sneaky Auth')$$,
  '42501', null::text,
  'authenticated cannot insert a project');
reset role;

select * from finish();
rollback;
