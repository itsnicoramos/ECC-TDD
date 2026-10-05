-- S1 / R2, R3, R4 — table shape.
-- pgtap is created inside the transaction and rolled back with it, so the test
-- framework never ships to production in a migration.
begin;
create extension if not exists pgtap with schema extensions;
select plan(28);

-- result state enum
select has_enum('public', 'check_result_state', 'check_result_state enum exists');
select enum_has_labels('public', 'check_result_state', ARRAY['pass','fail','blocked'],
  'enum labels are exactly pass/fail/blocked');

-- projects
select has_table('public', 'projects', 'projects table exists');
select col_is_pk('public', 'projects', 'id', 'projects.id is the primary key');
select col_is_unique('public', 'projects', 'slug', 'projects.slug is unique');
select col_not_null('public', 'projects', 'name', 'projects.name is not null');
select col_type_is('public', 'projects', 'created_at', 'timestamp with time zone',
  'projects.created_at is timestamptz');

-- checks
select has_table('public', 'checks', 'checks table exists');
select col_is_pk('public', 'checks', 'id', 'checks.id is the primary key');
select col_not_null('public', 'checks', 'project_id', 'checks.project_id is not null');
select col_not_null('public', 'checks', 'card_id', 'checks.card_id is not null');
select col_not_null('public', 'checks', 'title', 'checks.title is not null');
select col_not_null('public', 'checks', 'expect',
  'checks.expect is NOT NULL — a card step with no expected reading cannot be stored');
select col_is_null('public', 'checks', 'setup', 'checks.setup is nullable');
select col_is_null('public', 'checks', 'action', 'checks.action is nullable');
select col_is_null('public', 'checks', 'if_not', 'checks.if_not is nullable');
select col_is_null('public', 'checks', 'why', 'checks.why is nullable');
select col_not_null('public', 'checks', 'risk_rank', 'checks.risk_rank is not null');
select col_is_unique('public', 'checks', ARRAY['project_id','card_id'],
  'checks is unique on (project_id, card_id) — bench-card ids are stable keys');
select fk_ok('public', 'checks', 'project_id', 'public', 'projects', 'id',
  'checks.project_id references projects.id');

-- results
select has_table('public', 'results', 'results table exists');
select col_is_pk('public', 'results', 'id', 'results.id is the primary key');
select col_not_null('public', 'results', 'check_id', 'results.check_id is not null');
select col_type_is('public', 'results', 'state', 'check_result_state',
  'results.state uses the enum, not free text');
select col_is_null('public', 'results', 'reading', 'results.reading is nullable');
select col_is_null('public', 'results', 'note', 'results.note is nullable');
select col_is_null('public', 'results', 'observed_by',
  'results.observed_by is nullable until auth lands in S6');
select fk_ok('public', 'results', 'check_id', 'public', 'checks', 'id',
  'results.check_id references checks.id');

select * from finish();
rollback;
