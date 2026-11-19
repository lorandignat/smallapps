---
description: Resume the build loop from disk state
agent: ba
---

Follow the resume protocol in skill `ba-state`:

1. Read `docs/STATE.md`, then the active project's `docs/STATE.md` and
   `backlog/BOARD.md`, and the tail of its `journal/<role>.md`.
2. Check `git status` and `git log --oneline -5`. If a task is left `in-progress`
   or `in-review` from a dead session, reconcile it against the files and reports.
3. Tell me in three lines where we are and what you are about to do.
4. Continue the loop in `docs/PROCESS.md` §5 without waiting for me, unless a stop
   condition in §8 applies.
