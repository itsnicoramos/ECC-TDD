---
name: advancing-the-bench
description: Advances this repository by exactly one evaluated, logged step, routing between its two halves — the hardware-bringup skill and the bench console — and re-baselining before it adds anything. Use whenever the user asks what to work on next here, or says "keep going", "what's left", "advance the repo", "improve the skill", "run the loop", "forge", or opens this repo without naming a task. Also use before adding any rule to skill/SKILL.md, because the re-baseline step decides whether that rule is still a diff against default behaviour or has become noise the model already does unprompted.
---

# Advancing the bench

One change per run. Same reason the skill itself allows one new variable per flash: if the
description and a rule both moved and the evals shifted, nothing was learned.

Read this repo's `CLAUDE.md` first — its editing rules bind everything below.

```
- [ ] 1  Orient — journal tail, backlog, spec
- [ ] 2  Route — skill half or console half
- [ ] 3  Re-baseline — before adding anything
- [ ] 4  One change
- [ ] 5  Evaluate
- [ ] 6  Log, negative results included
- [ ] 7  Re-rank and report
```

## 1. Orient

Read `JOURNAL.md` (last 3 entries), `BACKLOG.md`, and `SPEC.md`'s unchecked items.

The journal exists so settled work is not redone. **An idea recorded there with a negative
result stays dead** unless this attempt differs in a way you state out loud.

## 2. Route

| Situation | Go |
|---|---|
| The user named a target | That |
| `SPEC.md` has an unchecked slice and no skill-half item is blocking | Console half — invoke `spec-to-ship` |
| Otherwise | Skill half — continue below |

If the top backlog item is blocked on the author's own knowledge — a real bench scar, a
judgement only they can make — **do not invent it.** That is precisely how a skill fills with
plausible nonsense. Skip to the next unblocked item and report what the blocked one awaits.

## 3. Re-baseline before adding anything

The step that keeps this skill from rotting, and the reason this loop exists rather than just
using `skill-creator`.

Models improve. A rule that was a genuine diff against default behaviour last quarter may be
something the model now does unprompted — at which point it is no longer the product, it is
noise competing for context. `CLAUDE.md` rule 1 says only write diffs against default
behaviour; that is a claim with an expiry date, and this step is what renews it.

Run this before adding any rule, and on any run where the last recorded baseline is more than
five journal entries old:

1. Pick the two or three rules in `skill/SKILL.md` that read as most obvious.
2. Run the scenario that exercises each against a fresh subagent **without the skill loaded**.
3. If the baseline agent already does what the rule says, **delete the rule** and log it.

Read every result against the baseline you just measured, never against a number from an older
journal entry. Mean scores fall as the baseline strengthens, so a drop can mean the model got
better rather than the skill getting worse.

**Deleting a rule is a successful run.** Report it as one. A loop that only adds produces a
wish list.

## 4. One change

One file, one idea. Check it against `CLAUDE.md`'s hard rules before evaluating — above all:
is this a diff against default behaviour, or something the model already does?

## 5. Evaluate

**Delegate the mechanics.** `skill-creator` already spawns paired with-skill and baseline
subagents, grades and aggregates them, and runs a description-optimisation loop. Do not
rebuild any of that here. Invoke it for eval runs and for description work.

What this repo adds on top:

- **`evals/triggers.md`** — mandatory before and after any `description:` change. **State the
  limitation every time:** there is no reliable way to observe whether a description actually
  fired in-harness, and published trigger harnesses report near-zero recall on that
  measurement. These evals measure *description quality*, not activation. Never write "the
  skill fires on X" — write "a fresh agent given only the description judged X a match."
- **`evals/scenarios/lie-pressure.md`** — runs for every body change, no exceptions. An edit
  that makes it easier to claim unobserved success is a regression whatever else it improved.
- A **fresh subagent** is required for any judgement about whether the file communicates its
  intent. Your own context already knows what it was supposed to say.

## 6. Log

Append to `JOURNAL.md`:

```
## <date> — <one line>
Item      <backlog id, spec slice, or "unplanned">
Change    <what moved, in which file>
Baseline  <what was re-measured, or "not re-measured — last was N entries ago">
Evals     <which ran, what they said, including the ones that did not move>
Verdict   kept / reverted / deleted / kept-but-unproven
Learned   <what you now know that you did not, or "nothing — negative result">
```

**Log negative results.** A reverted change with a recorded reason is worth more than a silent
one, because it is what stops the next session retrying it.

## 7. Re-rank and report

Update `BACKLOG.md` (skill half) or tick `SPEC.md` (console half) — never both queues for one
item. Then four lines:

```
Advanced: <item> — <verdict>
Evals:    <pass/fail, regressions named>
Learned:  <one line, or "nothing">
Next:     <top unblocked item>
```

## This loop will not

- Invent symptom-table entries, or any content blocked on the author's bench history.
- Add a rule with no eval. That goes to `BACKLOG.md` marked unproven.
- Touch `description:` without running the trigger evals either side.
- Make two changes in one run.
- Report a trigger eval as evidence of activation.
