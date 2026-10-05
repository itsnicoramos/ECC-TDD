# Backlog

Ranked. `/forge` takes the top unblocked item. Blockers are named, never guessed around.

| # | Item | Why it matters | State |
|---|---|---|---|
| F-01 | `references/symptoms.md` — real differential tables | The highest-value file in the repo and the one that cannot be generated. Needs scars: a symptom that pointed at the wrong cause. Seed from DUM-E's `bringup/README.md` troubleshooting table. | **BLOCKED** — needs the author's own bench history, not invented entries |
| F-09 | **First re-baseline pass.** Every rule in SKILL.md is unproven. Measure which ones a fresh agent already follows with no skill loaded, and delete those. | The skill is 193 lines of untested assertions. Some are certainly already default behaviour, and those are costing context while pretending to be the product. Highest-value unblocked item. | open |
| F-02 | `references/host-harness.md` — faking time, GPIO, I2C/SPI, ADC per toolchain | Rule "fake the hardware edge" currently has no worked example, so it will be followed inconsistently | open |
| F-03 | `references/bench-cards.md` — templates by check class (power, bus, actuator, sensor, comms) | Card quality is the whole operator experience; templates make it repeatable | open |
| F-04 | Per-board electrical limits table (per-pin mA, total I/O mA) for UNO R4, ESP32, Pi, STM32 | Preflight step 3 asks for a number the agent currently has to recall, and recalls wrong | open |
| F-05 | Trigger eval sweep for vague phrasings | "it's not working" is the real 1am prompt; untested | open |
| F-06 | Decide: should the skill ever *refuse* to continue on a failed preflight, or only stop? | Currently says "stop." Unclear if a hard refusal is better when a safety item fails | open — design question |
| F-07 | `install.sh` with personal/project scope flag | Copy-paste install in README works but is two commands and easy to get wrong | open |
| F-08 | Second synthetic scenario: I2C device not detected | Exercises the differential-diagnosis rules, which have no scenario yet | open |
