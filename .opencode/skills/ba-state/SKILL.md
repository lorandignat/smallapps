---
name: BA State Keeping
description: What to write in docs/STATE.md (workspace), <project>/docs/STATE.md, DECISIONS, QUESTIONS and journals, and how to resume a fresh session from disk. Use at session start, after each task, and before stopping.
---

# State keeping

Context dies; files do not. Two state files, two levels.

## Workspace — `docs/STATE.md`

Overwrite, keep under 40 lines:

- `Active project`, `Mode` (idle / build / blocked), shared toolchain one-liner.
- `Status` — 1-3 sentences covering all projects at once.
- `Next action` — numbered, ≤ 3.
- `Open questions`, `Blockers` (workspace-level only).
- `Recent` — one line per structural change, not per task.

Update it when: a project is created, archived, or changes phase; the active
project changes; a workspace question opens or closes; the process changes.

## Project — `<project>/docs/STATE.md`

Overwrite after **every** task:

- `Phase`, `Active feature`, `Active task`, `v1` status.
- `Status` — 1-3 sentences a stranger could act on.
- `Next action` — numbered, ≤ 3.
- `Approved gates` — one row per gate passed.
- `Open questions`, `Blockers`.

## Registry — `docs/PROJECTS.md`

One row per project. Update on creation, phase change, and when v1 status moves
(`not started`, `spec approved`, `n/m tasks`, `release candidate`,
`shipped <date>`). A stale registry makes the workspace unusable, so it is part of
the task that causes the drift.

## Decisions

Workspace decision → `docs/DECISIONS.md`. Project-scoped → the project's
`docs/DECISIONS.md`. Write one when you chose a stack or dependency policy, split
a task, accepted a deviation, hit three failures, or the human overruled the
process. Include the cost, not just the choice.

## Questions

Never block on a question. Log it with an ID, what it blocks, and the default you
will take if nobody answers. Then take the default, or mark the task `blocked`
and work something independent.

## Journals

`journal/<role>.md` per project: did / decided / dispatched / next. The narrative —
why a task was re-cut, what the tester kept catching, what the human actually
meant.

## Resuming

1. `docs/STATE.md` → active project and mode.
2. That project's `docs/STATE.md` → phase, active task, next action.
3. `backlog/BOARD.md` → counts, anything `in-progress` or `in-review`.
4. If something is `in-review`, look for the report — a crash between qa and you
   leaves a verdict unrecorded.
5. `git status` and `git log --oneline -5` → uncommitted work, recent commits.
6. If state and git disagree, **git and the files win**; fix the state files, note
   it in the journal, and tell the human in one line.

## Stopping

Whatever the reason: both state files current, journal appended, nothing staged
but uncommitted. The next session must start with two reads and no questions.
