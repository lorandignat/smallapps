---
id: TASK-000-review
task: TASK-000
feature: FEAT-000
verdict: PENDING   # PASS | FAIL | BLOCKED
date: YYYY-MM-DD
attempt: 1
---

# Review — TASK-000 <title>

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 |  | PASS/FAIL | command + output line, or `file:line` |
| 2 |  |  |  |

Evidence is a command the BA could re-run, or an exact `path:line` quote. "Looks
fine" is not evidence.

## What I ran

```sh
# commands, exit codes
```

## Findings

Ordered by severity. Each finding needs `file:line`, what is wrong, and how to
reproduce.

1. **BLOCKER / MAJOR / MINOR** — `src/foo.ts:42` — …

## Regressions

From `qa/REGRESSION.md`: all pass / list failures.

## Unverifiable on this host

What could not be checked and which Mac-only step is missing.

## Verdict

`PASS` only if every criterion has evidence, no regressions, no blockers. State
the single most important reason here.

**Verdict:** PENDING

**Next:** for `FAIL`, the exact rework instruction for the developer.
