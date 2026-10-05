# Journal

Newest last. Negative results are logged — that is most of the value.

## 2026-10-04 — skill created
Item      initial
Change    `skill/SKILL.md` written (193 lines): Rule 0 three-state vocabulary, toolchain
          detection, work classification, preflight gate, host-first TDD, bench card format,
          operator gate with `.bringup/pending.md` escape, differential diagnosis rules,
          `.bringup/state.md` memory, final report. Repo scaffolded: README, CLAUDE.md,
          `/forge`, evals, backlog.
Evals     None run yet. The whole file is therefore **unproven** — see CLAUDE.md rule 7.
          First `/forge` run should start by running the evals against what exists, not by
          adding anything.
Verdict   kept-but-unproven
Learned   Design decisions worth not relitigating: three states beat two because "probably
          fine" is where the lie hides; the operator gate needs the `pending.md` escape or it
          gets routed around; bench-card ids must be stable because users' state files
          reference them.

## 2026-10-04 — bench console added; S1 (schema + RLS) shipped
Item      SPEC.md S1, via spec-to-ship
Change    `SPEC.md` (bench console, 6 slices), `supabase/` (config, one migration grown across
          three RED/GREEN cycles, 5 pgTAP test files, generated types). CLAUDE.md and README
          now describe two halves. The skill itself was not touched.
Evals     Not the skill's evals — this slice is console work. Verified instead with
          `supabase db reset` (clean from zero) + `supabase test db`: **63/63 across 5 files**,
          and `tsc --noEmit --strict` on the generated types. Every cycle was seen red first.
Verdict   kept
Learned   Two things worth not rediscovering.
          1. **Supabase grants ALL on new public tables to anon, TRUNCATE included, and
             TRUNCATE is exempt from RLS and fires no row-level triggers.** An anonymous
             client wiped the append-only log straight through both guards; demonstrated
             (1 -> 0 rows) before being fixed with a revoke plus a statement-level trigger.
             RLS alone is not a data-retention guarantee.
          2. **A Postgres view without `security_invoker = true` runs with its owner's rights
             and silently returns rows RLS would hide.** Nothing in the policy definitions
             reveals it. Any view over an RLS table needs the option and an assertion.
          Also: the `authenticated` role tests passed on first run — they closed a coverage
          gap, not a defect. Worth stating plainly rather than counting as a fix.

## 2026-10-04 — the loop became a skill
Item      unplanned (user request)
Change    New project-scoped skill `.claude/skills/advancing-the-bench/SKILL.md` (124 lines).
          `/forge` shrank to a thin shim pointing at it, so there is one copy of the method.
          CLAUDE.md and README updated. No change to `skill/SKILL.md`.
Baseline  Not re-measured — the loop that does so was only just written. F-09 opened for the
          first real pass.
Evals     None. The loop skill has no evals of its own yet, which by CLAUDE.md rule 7 makes it
          unproven like everything else here.
Verdict   kept-but-unproven
Learned   From researching current practice, three things worth not rediscovering.
          1. **`skill-creator` already does generic skill evaluation** — paired with-skill and
             baseline subagents, grading, description optimisation, variance analysis. Building
             that here would have been duplication. The loop delegates to it.
          2. **Nobody can reliably measure whether a description actually fired.** Published
             trigger harnesses report near-zero recall on that measurement. `evals/triggers.md`
             measures description *quality*; claiming it measures activation would be the same
             species of overstatement the skill exists to prevent.
          3. **Eval results must be read against a freshly measured no-skill baseline**, and
             mean scores fall as the baseline strengthens. So "only write diffs against default
             behaviour" has an expiry date, and a loop that never deletes is how a skill rots.
             Re-baselining and deletion are now steps 3 and a valid verdict, respectively.
