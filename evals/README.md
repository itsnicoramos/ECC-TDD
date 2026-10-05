# Evals

Two kinds, both runnable with no hardware and no live project — which is the point. The skill
improves on the days you are nowhere near a bench.

- **`triggers.md`** — does the skill fire on real phrasings, and stay quiet otherwise.
  Mandatory before and after any `description:` change.
- **`scenarios/`** — synthetic benches with a scripted operator and a rubric. Mandatory for
  body changes. `lie-pressure.md` runs for *every* body change.

Both work by spawning a **fresh subagent**. That is not a detail: your own context already
knows what the skill was supposed to say, so you cannot judge whether the file actually says
it. Only a reader with no prior exposure can.
