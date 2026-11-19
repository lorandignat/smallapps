---
name: BA State Keeping
description: What to write in docs/PROJECT-STATE.md, docs/DECISIONS.md, docs/QUESTIONS.md and journal/<role>.md, and how to resume a fresh session from disk. Use at session start, after each task, and before stopping.
---

# State keeping

Context dies; files do not. Everything you need on waking is in three files:
`docs/PROJECT-STATE.md`, `backlog/BOARD.md`, `journal/<role>.md` (tail).

## `docs/PROJECT-STATE.md` — overwrite, keep short

Update after **every** task and at every phase change. Not a diary: aim for under
40 lines. Sections:

- `Phase` (0 intake / 1 breakdown / 2 build / 3 release)
- `Active product / feature / task`
- `Status` — 1-3 sentences a stranger could act on
- `Next action` — numbered, concrete, ≤ 3 items
- `Approved gates` — one row per gate you passed
- `Open questions`, `Blockers`
- `Last commits` — or rely on `git log`

## `docs/DECISIONS.md` — append

Write a `DEC-###` when: you chose a stack or dependency policy, you split a task,
you accepted a deviation from the spec, a task failed three times, or the human
overruled the process. Include what it costs, not just what you chose.

## `docs/QUESTIONS.md` — append, never block

One row: ID, date, question, what it blocks, and the default you will take if the
human does not answer. Then unblock yourself with the default where possible, or
mark the task `blocked` and continue with something independent.

## `journal/<role>.md` — append

One entry per unit of work: did / decided / dispatched / next. This is where the
narrative lives: why a task was re-cut, what the tester kept catching, what the
human actually meant. Future-you reads this to avoid re-litigating.

## Resuming

At the start of any session:

1. `docs/PROJECT-STATE.md` → phase, active task, next action.
2. `backlog/BOARD.md` → counts, anything in `in-progress` or `in-review`.
3. If something is `in-review`, check whether a report exists — a crash between
   qa and you leaves a verdict unrecorded.
4. `git status` and `git log --oneline -3` → is there uncommitted work?
5. If state and git disagree, **git and the files win**; fix the state file, note
   it in the journal, and tell the human in one line.

## Stopping

Before you go idle, whatever the reason: state file current, journal appended,
nothing staged but uncommitted. The next session must be able to start with a
single read and no questions.
