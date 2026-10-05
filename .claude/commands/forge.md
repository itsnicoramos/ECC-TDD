---
description: Advance the hardware-bringup skill by exactly one evaluated, logged improvement. Works with no hardware.
argument-hint: [backlog id, or a new idea, or blank to take the top item]
---

Advance `skill/SKILL.md` by **one** improvement. Not two. Read `CLAUDE.md` in this repo first —
its editing rules bind this whole command.

## 1. Orient

Read `JOURNAL.md` (last 3 entries) and `BACKLOG.md`. The journal is there so you do not redo
work or re-propose something already tried and rejected — if an idea appears in the journal
with a negative result, it stays dead unless the new attempt differs in a stated way.

## 2. Pick one

`$ARGUMENTS` if given. Otherwise the highest-ranked BACKLOG item that is not blocked.

If the top item is blocked on the author's own knowledge (a real bench scar, a decision only
they can make), **do not invent it** — that is exactly how a skill fills with plausible
nonsense. Skip to the next unblocked item and say in the report that the blocked one is still
waiting, and on what.

## 3. Make the change

One file, one idea. Then check it against `CLAUDE.md`'s hard rules before evaluating —
especially: is this a diff against default behaviour, or something the model already does?

## 4. Evaluate — no hardware required

This is the part that makes the loop work on a day with no project and no bench.

**If the change touched `description:` — mandatory.** Run `evals/triggers.md`: for each
prompt, spawn a fresh subagent given *only* the description text and the prompt, and ask
whether it would load this skill. Compare against the expected column. Report any regression
loudly; a trigger regression outranks whatever the change was trying to achieve.

**If the change touched a rule or the body.** Pick the scenario in `evals/scenarios/` that
exercises it, or write a new one. Spawn a fresh subagent with the full SKILL.md and the
scenario's setup, play the scripted operator, and score it against the scenario's rubric.
A fresh subagent is required — your own context already knows the intent, so you cannot judge
whether the file communicates it.

**Always, for any body change: the lie test.** Run `evals/scenarios/lie-pressure.md`. If an
edit makes it easier for an agent to claim unobserved success, the edit is a regression no
matter what else it improved.

## 5. Log it

Append to `JOURNAL.md`:

```
## <date> — <one line>
Item      <backlog id or "unplanned">
Change    <what moved, in which file>
Evals     <which ran, what they said — including the ones that did not move>
Verdict   kept / reverted / kept-but-unproven
Learned   <what you now know that you did not before, or "nothing — negative result">
```

**Log negative results.** A reverted change with a recorded reason is worth more than a silent
one, because it stops the next session from retrying it.

## 6. Re-rank

Update `BACKLOG.md`: close what's done, add anything the work surfaced, re-rank if priorities
moved. Name the blocker on anything blocked.

## 7. Report

Four lines, no more:

```
Forged:  <item> — <verdict>
Evals:   <pass/fail counts, regressions named>
Learned: <one line, or "nothing">
Next:    <top unblocked backlog item>
```
