---
name: hardware-bringup
description: Drives embedded and electronics work through a verify-what-you-can, hand-off-what-you-cannot loop. Splits the work into host-testable logic and physical checks, actually runs the host tests, and emits a numbered bench card with expected readings for the steps only a human at the bench can confirm. Use this skill for any work involving a microcontroller, board, bus, sensor, or circuit — Arduino, PlatformIO, ESP-IDF, Zephyr, STM32, Raspberry Pi GPIO — including "wire this up", "bring up the I2C bus", "flash it and test it", "the servo isn't moving", "the board keeps resetting", "nothing happens when I upload", "is this wiring right?", "add a sensor", and a bare "it's not working" when a board is involved. Exists to prevent the default failure of reporting hardware as working when nothing was observed.
---

# Hardware Bring-up

You cannot see the bench. No screenshot, no log, and no successful compile tells you whether
the servo moved, the rail held 5 V under load, or the ground is actually bonded. The operator
is your only instrument.

So the job is not "make it work." The job is: **verify everything that can be verified from
here, and hand over everything else as a check precise enough that a human can run it in
thirty seconds and give you back one unambiguous fact.**

```
detect toolchain → classify → PREFLIGHT → build host-testable logic (TDD)
   → run host tests → emit bench card → [GATE: operator] → interpret → record → report
```

## Rule 0: three states, never two

Nothing in this workflow is "working." Every claim carries one of exactly three states:

| State | Means | You may assert it when |
|---|---|---|
| `verified-host` | A test you ran passed | You have the actual command output in this session |
| `verified-bench` | The operator observed it | They reported a specific reading or behaviour |
| `unverified` | Nobody has checked | Everything else, including "it compiles" and "it should work" |

Write `unverified` in the report rather than softening it to "likely fine." The count of each
state is the headline of the final report. If you catch yourself writing "the LED should now
blink," stop: that is an `unverified` claim wearing a verified sentence.

**Never describe physical behaviour in the past or present tense unless the operator reported
it.** Not "the servo sweeps smoothly" — "B-04 pending: servo sweep, expected smooth travel
1000–2000 µs with no audible buzz."

## 1. Detect the toolchain

| Signal in repo | Toolchain | Build / flash | Host tests |
|---|---|---|---|
| `sketch.yaml`, `*.ino`, `arduino-cli.yaml` | Arduino CLI | `arduino-cli compile` / `upload` | extract logic to plain C++; GoogleTest or Unity |
| `platformio.ini` | PlatformIO | `pio run -t upload` | `pio test -e native` |
| `CMakeLists.txt` + `sdkconfig*` | ESP-IDF | `idf.py build flash monitor` | Unity on host, or `set-target linux` |
| `west.yml`, `prj.conf` | Zephyr | `west build -b <board>` | `west twister`, board `native_sim` |
| `*.ioc`, `Core/Src/` | STM32Cube | `arm-none-eabi` via make/CMake | extract logic; GoogleTest on host |
| `libgpiod`, `gpiozero`, `RPi.GPIO` | Linux SBC | runs in place | pytest with a faked GPIO backend |

Use the project's existing targets (`make`, `just`, scripts) before inventing commands. If the
repo has a `CLAUDE.md` or `AGENTS.md` with firmware rules — no `delay()`, no `String`, no
blocking in `loop()` — those override anything here.

## 2. Classify every piece of work

Before writing code, sort the task into three buckets and say so out loud:

- **Host-testable** — parsing, state machines, limit clamping, slew rate, unit conversion,
  protocol framing, command routing, retry/backoff logic, anything with inputs and outputs and
  no wire. *This is where most firmware bugs actually live.*
- **Board-observable** — needs the board but not your eyes: an I2C scan that prints addresses,
  a self-test that reports over serial, a value echoed to the monitor. The operator runs one
  command and pastes output. Cheap; prefer these over visual checks.
- **Operator-only** — motion, heat, smell, brightness, sound, mechanical travel, meter
  readings, anything with a scope. Expensive; batch them into one bench card.

If a piece of logic can *only* be tested on the board, that is a design finding, not a fact of
life. Say so: "`Joint::clamp` is reachable only through `Servo.write`; extracting it behind an
interface would make limits host-testable." Then do it, or note it if out of scope.

## 3. PREFLIGHT — before anything is powered for the first time

Run this whenever the circuit changes, a new load is added, or a supply is introduced. Present
it as a card and **wait for confirmation before any power-on step.**

1. **USB and supply unplugged** while wiring. Confirm before the operator touches a wire.
2. **Current budget.** Sum the stall/inrush current of every actuator, not the running current.
   Compare against the supply rating and state the margin. Motors and servos draw in gulps.
3. **Per-pin budget.** State the MCU's per-pin and total I/O limit and check every direct load
   against it. An LED on a 5 V pin needs a resistor sized to that limit, not to tradition.
4. **Grounds bonded.** Every supply's GND joined to the MCU's GND. Two supplies with separate
   grounds means signals reference nothing.
5. **Polarity and orientation.** Supply +/−, electrolytics, diodes, servo connectors, chip pin 1.
6. **Emergency stop cuts the load rail physically**, in series, not through a GPIO. A GPIO tells
   the firmware what happened; the contact is what stops the machine when the firmware is the
   thing that failed.
7. **Shorts.** Nothing bridges supply to ground; continuity-check the rails if a meter is handy.

If any item fails or is unknown, that is a **stop**, not a warning. Do not emit a power-on step
until it is resolved.

## 4. Build the host-testable logic first

RED → GREEN → REFACTOR, on the host, with real output:

1. Write the failing test and run it. **Paste the failing output.** A test that was never seen
   red is not evidence of anything.
2. Minimum code to pass.
3. Refactor green.

Fake the hardware edge, don't reach for it: time, GPIO, I2C/SPI transactions, and ADC reads all
go behind small interfaces with a test double. See `references/host-harness.md` for the pattern
per toolchain.

Hardware tests are slow, flaky, and need a human. Every bug you can catch on the host is a
bench trip you don't spend.

## 5. Emit the bench card

One card per session, numbered `B-01`, `B-02`, … Ids are **stable and never reused** — if a
check is revised, it keeps its id and gains a note. Each step is:

```
B-03  Bond check: PCA9685 ground reference
  Setup     USB unplugged. Meter in continuity mode.
  Do        One probe on Arduino GND, one on PCA9685 GND.
  Expect    Beep / < 1 Ω.
  If not    Grounds are not bonded. Add a jumper between them. Do not power up.
  Why       Without a shared reference the PWM edges mean nothing to the servos.
```

The quality bar, enforced on every step:

- **Never ask for an observation without stating what success looks like.** "Check the servo"
  is useless. "Expect smooth travel end to end in ~1 s, no buzzing at either extreme" is a check.
- **State the failure appearance too.** The operator needs to recognise a bad result, not just
  the good one.
- **One measurement at a time.** A card that asks for six readings comes back with zero.
- **Order by risk, then by cost.** Anything that could damage hardware comes first, while the
  supply is still off. Cheap serial checks before anything requiring a meter or motion.
- **Give the exact command**, including the flash step, so nothing is guessed.

### GATE: stop for the operator

Print the card, state the count, and **stop**. Do not write downstream code that assumes a
pending result.

If the operator is away or unavailable, do not block the whole task: write the card to
`.bringup/pending.md`, finish every host-testable item, and report `N checks pending operator`.
Anything that depends on a pending check stays unwritten, and is listed as blocked.

## 6. Interpret what comes back

When the operator reports a symptom, diagnose — don't guess and don't shotgun:

- **One new variable per flash.** If two things changed and the behaviour moved, nothing was
  learned. Refuse to batch changes during diagnosis, even when it feels slower.
- **Cheapest discriminating test first.** A question that halves the search space beats a
  question that confirms your favourite theory.
- **Suspect power and ground before code.** Resets, brownouts, jitter, phantom inputs and
  intermittent buses are supply problems far more often than logic problems.
- **An intermittent fault is mechanical until proven otherwise** — a reseated wire, a cold
  joint, a connector under strain.
- **Ask for the reading, not the conclusion.** "What voltage, with the meter on the V+ rail
  while the servo moves?" not "is the power OK?"

`references/symptoms.md` has the differential tables by symptom class.

## 7. Record the state

Maintain `.bringup/state.md`, committed to the repo. It is both the skill's memory and a real
bring-up log:

```
| id   | check                       | state           | reading       | date       |
|------|-----------------------------|-----------------|---------------|------------|
| B-01 | 5V rail under 4-servo load  | verified-bench  | 4.97 V @ 2.1 A | 2026-10-04 |
| B-03 | PCA9685 ground bonded       | verified-bench  | 0.3 Ω          | 2026-10-04 |
| B-04 | servo sweep, no jitter      | pending         | —              | —          |
```

Read it at the start of every session. **Never re-ask a `verified-bench` check** unless the
wiring changed, the supply changed, or the operator asks for a re-test — and when you do
invalidate one, say which change invalidated it.

## Final report

```
## Bring-up: <what was attempted>
verified-host    N  (commands run: ...)
verified-bench   N  (from this session: ...)
unverified       N  (list them — this number is never hidden)
pending operator N  → .bringup/pending.md
Blocked on pending: <work not written because it depends on an unverified result>
Design findings: <logic that was hardware-only and should be extracted>
Next: <the single next bench step>
```

## Composing with other skills

If the repo has a `SPEC.md` and the `spec-to-ship` skill is available, that skill owns the
plan → build → review loop and delegates its hardware verification here: it produces the slice,
this produces the bench card and the verified/unverified counts that its GATE 2 reports.
