# Trigger evals

The description is the entire activation surface. Run this before and after any change to it.

**Method.** For each prompt, spawn a fresh subagent given *only* the `description:` text from
`skill/SKILL.md` and the prompt. Ask: "Would you load this skill? Yes or no, one line of why."
A fresh agent is required — your own context already knows the answer.

Negative cases matter as much as positive ones. A description tuned only on things that should
fire ends up firing on everything, which is the same as not firing at all.

| # | Prompt | Expect | Why this case exists |
|---|---|---|---|
| T-01 | "help me bring up the I2C bus on this board" | FIRE | the easy one; if this fails, something is badly wrong |
| T-02 | "the servo isn't moving" | FIRE | symptom-only, no method named |
| T-03 | "it's not working" *(in a repo with `platformio.ini`)* | FIRE | **the 1am case.** The real phrasing, almost no signal in the words |
| T-04 | "nothing happens when I upload" | FIRE | upload/flash vocabulary without the word hardware |
| T-05 | "the board keeps resetting" | FIRE | classic brownout symptom, reads like a software crash |
| T-06 | "add a temperature sensor to this" | FIRE | new-hardware work, no debugging framing |
| T-07 | "is this wiring right?" | FIRE | pure review, no code involved at all |
| T-08 | "write a python script to parse this CSV" | NO | plain software, must stay quiet |
| T-09 | "my docker build is failing" | NO | build-failure vocabulary that is not firmware |
| T-10 | "the server keeps resetting" | NO | near-miss on T-05; "server" not "board" |
| T-11 | "refactor this state machine" *(in a firmware repo)* | NO | firmware-adjacent but purely host-side; firing here is over-eager |
| T-12 | "explain how I2C works" | NO | a question, not work on a bench |

**Scoring.** All 12 correct = pass. Any T-03 or T-08..T-12 miss is a blocker; the first is
the case the skill exists for, the rest are over-firing, which trains users to ignore it.
