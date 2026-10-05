# Design notes — hardware bring-up skill

## The problem this skill exists to fix

An agent's default failure mode with hardware is **claiming success it cannot observe.**
It writes firmware, the firmware compiles, and it reports "the servo now sweeps smoothly."
It has never seen the servo. There is no servo in its context. The claim is invented.

Every other hardware annoyance (wrong pin, brownout, floating input) is a bug.
This one is a *lie*, and it is the thing that makes agents untrustworthy on embedded work.

## The spine

```
classify the work
  → split into: host-testable | board-observable | operator-only
  → actually test the host part (real failing output, real pass)
  → emit a BENCH CARD for the rest: numbered steps, expected reading, what failure looks like
  → STOP. Wait for the operator's observed result.
  → interpret that result against a differential (cheapest check first)
  → record the outcome so the next session doesn't re-ask
```

## Candidate hard rules (the "diff against default behaviour")

1. **Three states, never two.** Nothing is "working." It is `verified-on-host`,
   `verified-by-operator`, or `unverified`. The final report prints the count of each.
2. **Preflight before first power.** USB unplugged while wiring; grounds bonded;
   current budget computed against the supply; E-stop in series with the load rail,
   not on a GPIO.
3. **One new variable per flash.** If two things changed and the result moved,
   nothing was learned. Refuse to batch changes during diagnosis.
4. **Ask for one measurement at a time.** A diagnostic that asks for six readings
   gets zero back.
5. **Logic lives behind an interface.** Parsing, state machines, limits, math, protocol
   framing — all host-testable. If it can only be tested on the board, that is a design
   finding, not an excuse.
