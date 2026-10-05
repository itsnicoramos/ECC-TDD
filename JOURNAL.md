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
