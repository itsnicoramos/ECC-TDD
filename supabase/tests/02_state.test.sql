-- S1 / R5 — state is derived from the latest result, never stored.
begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

select has_view('public', 'checks_with_state', 'checks_with_state view exists');

-- A view without security_invoker runs with its OWNER's rights and silently bypasses RLS on
-- the tables beneath it. Nothing in the policy definitions would reveal that, so assert it.
select ok(
  exists (
    select 1 from pg_class c, unnest(c.reloptions) o
    where c.oid = 'public.checks_with_state'::regclass
      and o in ('security_invoker=true', 'security_invoker=on')
  ),
  'checks_with_state is security_invoker — without it the view fails open past RLS'
);

select hasnt_column('public', 'checks', 'state',
  'checks has no state column — state is derived, never stored');

insert into public.projects (id, slug, name)
  values ('22222222-2222-2222-2222-222222222222', 'derive', 'Derive');
insert into public.checks (id, project_id, card_id, title, expect)
  values ('33333333-3333-3333-3333-333333333333',
          '22222222-2222-2222-2222-222222222222', 'B-01',
          '5V rail under load', '4.9 V or better at 2 A');

select is((select state from public.checks_with_state
           where id = '33333333-3333-3333-3333-333333333333'),
  'pending', 'a check with no results reads as pending');

insert into public.results (check_id, state, reading, observed_at)
  values ('33333333-3333-3333-3333-333333333333', 'pass', '4.97 V @ 2.1 A',
          now() - interval '2 hours');

select is((select state from public.checks_with_state
           where id = '33333333-3333-3333-3333-333333333333'),
  'pass', 'a single result becomes the state');

-- A later re-test must win. This is the case that makes append-only safe: the history is
-- kept, but the current state is unambiguous.
insert into public.results (check_id, state, note, observed_at)
  values ('33333333-3333-3333-3333-333333333333', 'fail',
          'dips to 4.1 V on start', now());

select is((select state from public.checks_with_state
           where id = '33333333-3333-3333-3333-333333333333'),
  'fail', 'the latest result wins, not the first');
select is((select note from public.checks_with_state
           where id = '33333333-3333-3333-3333-333333333333'),
  'dips to 4.1 V on start', 'the latest result note is surfaced');

select * from finish();
rollback;
