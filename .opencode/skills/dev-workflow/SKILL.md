---
name: Developer Workflow
description: The exact procedure for one developer invocation - read the task, implement, self-check, log, report, and what to do on rework or when blocked. Use at the start of every task.
---

# One task, start to finish

## 1. Read

- `backlog/tasks/TASK-###.md` — the contract. Read the criteria until you could
  recite them.
- The feature file (`backlog/features/FEAT-###.md`) — why it exists.
- The spec section it references — the intent behind the words.
- `qa/reports/TASK-###-review.md` if it exists — this is attempt ≥ 2.
- Tail of `journal/<role>.md` — what the last attempt learned.

## 2. Plan in three lines

Write, in your head or the journal: the files you will change, the test you will
add, the command that proves it. If the plan needs a fourth file the task did not
name, re-read the task before proceeding — you are probably expanding scope.

## 3. Implement

- Smallest correct change. Match the surrounding style, not your preference.
- Add or update the test **in the same change**. A behaviour without a test is
  not implemented, it is improvised.
- Handle the failure path the criteria name, and do not swallow errors.
- If the task requires a dependency: see skill `dev-tools`. Install it, log it.
- If the tree was already broken, say so in the report — do not quietly fix
  unrelated breakage as if it were part of the task.

## 4. Self-check (do not skip)

```sh
<build/typecheck>      # must pass
<test command>         # must pass, including the task's new test
<lint/format>          # must pass or be auto-fixed
git diff --stat        # only allowed files
```

Re-read each acceptance criterion and point at the thing that satisfies it. If one
criterion has no evidence, you are not done.

## 5. Log

Append to `journal/<role>.md`: files, approach, commands and results, surprises, and
what the tester should look at.

## 6. Report

Use the exact format in your instructions. Then stop.

## Rework (same task, attempt ≥ 2)

1. Read the findings in the review file. All of them, not just the first.
2. Reproduce each finding before fixing it.
3. Fix the smallest thing that resolves it; do not redesign under pressure.
4. Re-run the full check set, including the criteria that already passed.
5. Say in the report which findings are addressed and how. If you believe a
   finding is wrong, implement the reasonable version anyway and explain the
   disagreement under "For the BA" — do not argue by doing nothing.

## Blocked

Return `BLOCKED` when a criterion is ambiguous, the task needs a file it does not
authorise, or verification is impossible here. State: the exact question, the
options, and your recommendation. A blocked task is cheap; a guess is expensive.
