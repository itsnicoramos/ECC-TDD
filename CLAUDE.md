# Working on this repo

This repo's product is `skill/SKILL.md`. Everything else exists to keep that file honest.

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

Run `/forge` to advance the skill by one improvement. It reads BACKLOG.md and JOURNAL.md,
makes exactly one change, evaluates it, and logs the result — including negative results.

**One change per run.** Same reason as the skill's own "one new variable per flash": if the
description and a rule both moved and the evals shifted, nothing was learned.

## Map

```
skill/SKILL.md          the product
skill/references/       on-demand detail
evals/triggers.md       does it fire on real phrasings
evals/scenarios/        synthetic benches — exercise the skill with no hardware
BACKLOG.md              ranked, with blockers named
JOURNAL.md              what changed, what the evals said, what is still unknown
docs/design.md          why the skill exists, in one page
```
