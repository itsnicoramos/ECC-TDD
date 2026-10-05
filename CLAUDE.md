# Working on this repo

This repo has two halves of one system:

- **`skill/`** — the `hardware-bringup` skill. The primary product; everything else exists to
  keep that file honest.
- **`apps/console/`** — the bench console, a Next.js + Supabase app the operator uses at the
  bench. Its source of truth is `SPEC.md`, and `spec-to-ship` owns its build loop.

Unless a section says otherwise, the rules below are about `skill/`.

The reader of SKILL.md is **an agent under context pressure, mid-task, with a user waiting** —
not a human browsing documentation. That single fact drives every rule below.

## What the skill is for

Agents claim hardware works when they have observed nothing. The skill's entire reason to
exist is making that specific failure impossible. Any change that doesn't serve that — or that
dilutes it with general embedded advice the model already knows — makes the skill worse even
if the prose is good.

## Hard rules for editing SKILL.md

1. **Only write diffs against default behaviour.** If the model already does it unprompted,
   deleting it makes the skill stronger. "Run the test suite" is noise. "A test that was never
   seen red is not evidence" is the product.
2. **Never touch `description:` without running `evals/triggers.md` before and after.** The
   description is the entire activation surface and the only part always in context. A skill
   that doesn't fire is worth exactly zero, regardless of how good the body is.
3. **Every rule you care about carries a counterexample.** A bare rule gets paraphrased into
   compliance-shaped prose; a wrong-version pinned beside it gives the model something to
   pattern-match itself against. See the "the servo sweeps smoothly" line.
4. **Load-bearing rules go at the top.** Rule 0 precedes toolchain detection on purpose. The
   middle of a long file is what gets skimmed.
5. **SKILL.md stays under ~200 lines.** Detail goes to `skill/references/`, which loads on
   demand. Growth in the main file is a regression, not progress.
6. **Name the cost of expensive rules.** "One new variable per flash, even when it feels
   slower." A rule that ignores the pull it's fighting loses to that pull.
7. **No rule ships without an eval**, or it goes in BACKLOG as unproven. Untested rules are
   how a skill rots into a wish list.
8. **Bench-card ids are stable and never reused.** A revised check keeps its id and gains a
   note. Users' `.bringup/state.md` files point at those ids.

## Rules for references/

Loaded only when needed, so they can be long — but they earn their place by being *specific*.
`symptoms.md` is worthless if it says "check your grounds." It is valuable when it says what a
symptom looked like, what it pointed at, and what it actually was. Prefer one real scar to
twenty plausible entries.

## The loop

`/forge`, or the `advancing-the-bench` skill it invokes, advances the repo by one evaluated,
logged step — routing between the skill half and the console half, and re-baselining before it
adds anything.

**One change per run.** Same reason as the skill's own "one new variable per flash": if the
description and a rule both moved and the evals shifted, nothing was learned.

**Re-baseline before adding.** Rule 1 above — only diffs against default behaviour — is a claim
with an expiry date. Models improve, and a rule can quietly become something the model already
does unprompted, at which point it is noise competing for context. The loop re-measures against
a fresh no-skill baseline and **deletes** rules that have gone stale. A deletion is a successful
run, not a failed one.

**Eval mechanics are delegated.** `skill-creator` already runs paired with-skill/baseline
subagents, grades them, and optimises descriptions. Don't rebuild that here. What this repo
adds is the routing, the cross-session memory, and the re-baseline pass.

**Trigger evals measure description quality, not activation.** There is no reliable way to
observe whether a description actually fired in-harness. Say so whenever reporting them.

## Rules for apps/console

`SPEC.md` is the source of truth. Don't build from this file, from chat, or from memory of a
conversation — run `/spec-to-ship`, which plans, gates for approval, builds with TDD, reviews,
and ticks the spec when it's done.

1. **The contract section of SPEC.md is load-bearing.** Supabase is authoritative for check
   state; `.bringup/state.md` is a generated export, db → file, one direction. Any change that
   makes the file authoritative, or lets the app write into the agent's repo beyond that
   export, needs the spec amended first and the reason recorded.
2. **RLS in the first migration, never bolted on afterwards.**
3. **Bench-card ids are a foreign key now.** Skill rule 8 — stable, never reused — stops being
   a convention and becomes the db's unique `(project_id, card_id)`.
4. **The console never edits a card.** The agent owns the card; the phone owns the result.
5. **Console work is tracked in `SPEC.md`, not `BACKLOG.md`.** Two queues for one repo is how
   both go stale.

## Map

```
skill/SKILL.md          the product
SPEC.md                 bench console requirements — source of truth for apps/console
apps/console/           Next.js + TS + Supabase operator app
supabase/migrations/    schema and RLS
skill/references/       on-demand detail
evals/triggers.md       does it fire on real phrasings
evals/scenarios/        synthetic benches — exercise the skill with no hardware
BACKLOG.md              ranked, with blockers named
JOURNAL.md              what changed, what the evals said, what is still unknown
docs/design.md          why the skill exists, in one page
.claude/skills/         advancing-the-bench — this repo's own loop (project-scoped)
.claude/commands/       /forge — typed entry point for that loop
```
