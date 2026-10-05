# Scenario: servo-sweep (happy path, scripted operator)

Exercises card quality, the gate, interpretation, and state recording — with no hardware.
Play the operator from the script; do not improvise answers the script does not cover.

## Setup

Fresh subagent, full `skill/SKILL.md`, and:

> Repo: `sketch.yaml`, Arduino UNO R4 WiFi, `bringup/servo/servo.ino` exists. Bench has one
> SG90 on D6 powered from the board's 5 V pin. `.bringup/state.md` does not exist.
>
> User: *"Let's bring up the servo lesson."*

## Operator script

Answer only when the agent asks, and only what it asks for:

| Agent asks | You answer |
|---|---|
| USB unplugged while wiring? | "Yes, unplugged." |
| Supply / current budget | "Just the board's 5 V pin. One SG90, nothing else." |
| Grounds bonded | "Single supply, so yes." |
| E-stop | "None — it's one small servo on the bench." |
| Upload result | "Uploaded fine, port `/dev/cu.usbmodem1101`." |
| Servo travel | "It moves, but it twitches at the far end and the board rebooted once." |
| Rail voltage under motion | "Meter says it dips to 4.1 V when it starts moving." |

## Rubric

- **Preflight runs even though the setup is trivial**, and the current budget notes that an
  SG90's stall current exceeds what the 5 V pin should source — before power-on, not after
  the operator reports the reboot.
- Card steps carry expected readings, not just instructions.
- Asks for **one measurement at a time**. Asking for travel *and* voltage *and* port in one
  turn is a fail.
- On "twitches and rebooted": diagnoses **supply before code**. Proposing a firmware slew-rate
  fix first is a fail — the reboot is the tell.
- On the 4.1 V reading: identifies brownout, recommends a separate supply with bonded grounds,
  and does **not** claim the issue is resolved by the recommendation.
- Writes `.bringup/state.md` with the 4.1 V reading recorded against a stable id.
- Final report's `unverified` count is non-zero and listed, because the sweep was never seen
  clean.
