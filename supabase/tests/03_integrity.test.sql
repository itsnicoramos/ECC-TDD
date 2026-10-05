-- S1 — the two integrity rules decided at GATE 1.
--   (2) results are append-only, enforced by trigger because service_role bypasses RLS
--       and the agent uses service_role
--   (3) a fail carries evidence, as a CHECK constraint so the agent cannot bypass it either
--       (SPEC.md places this under S4; see the deviation note there)
begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

insert into public.projects (id, slug, name)
  values ('44444444-4444-4444-4444-444444444444', 'integrity', 'Integrity');
insert into public.checks (id, project_id, card_id, title, expect)
  values ('55555555-5555-5555-5555-555555555555',
          '44444444-4444-4444-4444-444444444444', 'B-01',
          'servo sweep', 'smooth travel 1000-2000 us, no audible buzz');
insert into public.results (id, check_id, state, reading)
  values ('66666666-6666-6666-6666-666666666666',
          '55555555-5555-5555-5555-555555555555', 'pass', '4.97 V @ 2.1 A');

select throws_ok(
  $$update public.results set reading = 'tampered'
    where id = '66666666-6666-6666-6666-666666666666'$$,
  'P0001', null::text, 'a recorded result cannot be updated — append-only');
select throws_ok(
  $$delete from public.results where id = '66666666-6666-6666-6666-666666666666'$$,
  'P0001', null::text, 'a recorded result cannot be deleted — append-only');

select throws_ok(
  $$insert into public.results (check_id, state)
    values ('55555555-5555-5555-5555-555555555555', 'fail')$$,
  '23514', null::text, 'a fail with neither reading nor note is rejected');
select throws_ok(
  $$insert into public.results (check_id, state, reading, note)
    values ('55555555-5555-5555-5555-555555555555', 'fail', '   ', '')$$,
  '23514', null::text, 'whitespace does not count as evidence for a fail');
select lives_ok(
  $$insert into public.results (check_id, state, note)
    values ('55555555-5555-5555-5555-555555555555', 'fail', 'buzzes at the far stop')$$,
  'a fail with a note is accepted');
select lives_ok(
  $$insert into public.results (check_id, state, reading)
    values ('55555555-5555-5555-5555-555555555555', 'fail', '4.1 V on start')$$,
  'a fail with a reading is accepted');
select lives_ok(
  $$insert into public.results (check_id, state)
    values ('55555555-5555-5555-5555-555555555555', 'pass')$$,
  'a pass needs no written evidence — only a fail must be diagnosable');

-- Discovered during T8, not in the plan: the append-only guard also blocks ON DELETE
-- CASCADE, so a project holding results cannot be removed. Kept deliberately — an audit log
-- you can quietly purge is not an audit log — and asserted here so it is a chosen behaviour
-- rather than a surprise. Raised at GATE 2.
select throws_ok(
  $$delete from public.projects where id = '44444444-4444-4444-4444-444444444444'$$,
  'P0001', null::text,
  'deleting a project with results is blocked by the append-only guard (known consequence)');

select * from finish();
rollback;
