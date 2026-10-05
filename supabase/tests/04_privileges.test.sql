-- GATE 2 must-fix. Supabase grants ALL on new public tables to anon and authenticated, and
-- that set includes TRUNCATE. TRUNCATE is exempt from RLS and does not fire row-level
-- triggers, so it walks straight through both guards built in this slice.
-- Verified before fixing: as anon, results went 1 -> 0 via TRUNCATE TABLE.
begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

select ok(not has_table_privilege('anon', 'public.results', 'TRUNCATE'),
  'anon has no TRUNCATE on results');
select ok(not has_table_privilege('anon', 'public.checks', 'TRUNCATE'),
  'anon has no TRUNCATE on checks');
select ok(not has_table_privilege('anon', 'public.projects', 'TRUNCATE'),
  'anon has no TRUNCATE on projects');
select ok(not has_table_privilege('authenticated', 'public.results', 'TRUNCATE'),
  'authenticated has no TRUNCATE on results');
select ok(not has_table_privilege('authenticated', 'public.checks', 'TRUNCATE'),
  'authenticated has no TRUNCATE on checks');
select ok(not has_table_privilege('authenticated', 'public.projects', 'TRUNCATE'),
  'authenticated has no TRUNCATE on projects');

-- service_role deliberately keeps TRUNCATE: it is the trusted agent role and revoking
-- privileges from it is not a security boundary. So the statement-level guard, not the
-- grant, is what actually protects the log.
select ok(has_table_privilege('service_role', 'public.results', 'TRUNCATE'),
  'service_role still holds TRUNCATE — the guard below is the real protection');
select throws_ok(
  $$truncate public.results$$,
  'P0001', null::text,
  'TRUNCATE on results is refused even for a role that holds the privilege');

select * from finish();
rollback;
