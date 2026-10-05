# hardware-bringup

A Claude Code skill that stops coding agents from lying about hardware.

```
detect toolchain → classify → PREFLIGHT → build host-testable logic (TDD)
   → run host tests → emit bench card → [GATE: operator] → interpret → record → report
```

## The problem

Ask an agent to bring up a servo. It writes the firmware, the firmware compiles, and it tells
you:

> ✅ The servo now sweeps smoothly between its limits.

It has never seen the servo. There is no servo in its context. There is no sensor, no meter,
no rail voltage — only source code that parsed. The claim is invented, and it is invented in
the same confident tone as every true thing it said that session.

Wrong pin assignments are bugs. Floating inputs are bugs. **This is not a bug, it is a lie**,
and it is the single reason agents are untrustworthy on embedded work: you cannot tell which
half of the report was observed.

## What this does instead

The skill makes the agent treat you as its only instrument.

- **Three states, never two.** Nothing is "working." Every claim is `verified-host`
  (a test it ran), `verified-bench` (something you observed), or `unverified`. The count of
  each is the headline of every report, and `unverified` is never hidden or softened.
- **Splits the work honestly.** Parsing, state machines, limit clamping, slew rates, protocol
  framing — all host-testable, all tested for real before anything is flashed. Most firmware
  bugs live there, and every one caught on the host is a bench trip you don't spend.
- **Emits a bench card** for what's left: numbered steps, exact commands, the expected reading
  *and* what failure looks like. One measurement at a time, ordered by risk.
- **Preflights before first power.** Current budget against stall current, per-pin limits,
  grounds bonded, E-stop in series with the load rail rather than on a GPIO. A failed item is
  a stop, not a warning.
- **Remembers what you confirmed.** `.bringup/state.md` is committed to your repo, so a new
  session never re-interrogates you about a reading you gave it last week — and it tells you
  which change invalidated a check when one goes stale.

### A bench card step

```
B-03  Bond check: PCA9685 ground reference
  Setup     USB unplugged. Meter in continuity mode.
  Do        One probe on Arduino GND, one on PCA9685 GND.
  Expect    Beep / < 1 Ω.
  If not    Grounds are not bonded. Add a jumper between them. Do not power up.
  Why       Without a shared reference the PWM edges mean nothing to the servos.
```

Every step states what success looks like *and* what failure looks like. "Check the servo" is
not a check.

## Install

Personal, available in every project:

```bash
git clone https://github.com/YOUR-USERNAME/hardware-bringup.git /tmp/hb && cp -R /tmp/hb/skill ~/.claude/skills/hardware-bringup
```

Or scoped to one project, committed with the firmware:

```bash
git clone https://github.com/YOUR-USERNAME/hardware-bringup.git /tmp/hb && cp -R /tmp/hb/skill .claude/skills/hardware-bringup
```

Then just work. The skill activates on its own — "wire this up", "the board keeps resetting",
"nothing happens when I upload", or a bare "it's not working" with a board in the room.

## Toolchains

Detected from the repo, no configuration:

| Signal | Toolchain |
|---|---|
| `sketch.yaml`, `*.ino` | Arduino CLI |
| `platformio.ini` | PlatformIO |
| `CMakeLists.txt` + `sdkconfig*` | ESP-IDF |
| `west.yml`, `prj.conf` | Zephyr |
| `*.ioc`, `Core/Src/` | STM32Cube |
| `libgpiod`, `gpiozero`, `RPi.GPIO` | Linux SBC |

The hard rules — preflight, three states, one variable per flash — are physics. They do not
change between toolchains.

## What's in the box

```
skill/
  SKILL.md              the skill itself
  references/           loaded on demand, not held in context
    symptoms.md         differential diagnosis by symptom class
    host-harness.md     faking I2C/SPI/GPIO/time, per toolchain
    bench-cards.md      card templates by check class
evals/                  does it fire, and does it refuse to lie under pressure
docs/                   design notes
SPEC.md                 bench console requirements
apps/console/           the operator's phone app (Next.js + TypeScript + Supabase)
supabase/migrations/    schema and RLS
```

## The bench console

The skill prints a bench card into a terminal. The operator is across the room holding a
meter. The console closes that gap: the pending card appears on their phone, they tap a result
and type the reading, and the agent sees it land over realtime.

```
agent (terminal)  --write checks-->  Supabase  <--read/write results--  phone
                  <--read results--     |
                                        | realtime
                  .bringup/state.md  <--+   generated export, committed
```

One design decision carries the rest: **Supabase is authoritative for check state, and
`.bringup/state.md` is a generated export** — db to file, one direction, never read back as
truth. Two writers (an agent and a human) sharing one record is the whole problem; a single
direction of authority is the whole answer.

Requirements and slices live in [SPEC.md](SPEC.md). Neither half needs the other — the skill
works alone with a terminal and a human who answers in chat.

## Composing with spec-to-ship

If you run [`spec-to-ship`](https://github.com/YOUR-USERNAME/spec-to-ship), that skill owns the
plan → build → review loop and hands its hardware verification here. It produces the slice;
this produces the bench card and the verified/unverified counts its approval gate reports.
Neither needs the other installed.

## Status

Early, and honest about it. The core loop and preflight are written and in use on a 4-DOF
Arduino arm. The per-toolchain host harnesses and the symptom tables are being filled in as
they're earned on real benches — see [BACKLOG.md](BACKLOG.md) and [JOURNAL.md](JOURNAL.md).

**Contributions of symptom tables are the most valuable thing you can send.** Generic advice
("check your grounds") is worthless. What's wanted is the time a symptom pointed at the wrong
cause — the bug you chased in firmware that turned out to be a connector under strain. Open a
PR against `skill/references/symptoms.md` with the symptom, the thing it looked like, and the
thing it was.

## License

Not yet chosen. Until one is added, default copyright applies —
if you want to use or build on this, open an issue and ask.
