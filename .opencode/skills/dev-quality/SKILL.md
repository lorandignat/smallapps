---
name: Code Quality
description: Review your own change before reporting - correctness, tests, error handling, naming, accessibility, and diff hygiene. Use at the self-check step of every task.
---

# Quality bar

You are the senior developer. Nobody else will rewrite this. It must be obvious,
tested, and honest.

## Correctness

- Handle the empty case, the boundary case, and the double-tap case. Most bugs the
  tester finds live there.
- Never swallow an error. Either recover visibly or surface it with a message the
  criteria can name.
- No unbounded work: no unbounded lists, retries, or background loops.
- Async: know what happens if a call is slow, fails, or resolves twice.
- State: one source of truth. If two variables can disagree, keep one.

## Tests

- One test per criterion at minimum, named after the behaviour, not the method.
- A test that would still pass if the feature were deleted is not a test.
- Deterministic: no real network, no sleeps, no clock dependence without
  injection.
- Failure messages must name what was expected — the tester reads them.

## Readability

- Names say what, not how: `saveDraft`, not `doSave`; `isPersisted`, not `flag2`.
- Comments explain why, never what. Delete commented-out code.
- No dead code, no unused imports, no `TODO` that matters. If it matters, it is
  a report line for the BA.
- Follow the file's existing style. Consistency beats your taste.

## UI (when the stack has one)

- Every interactive element has a label for assistive tech.
- Touch targets ≥ 44pt; contrast is not "looks fine".
- Loading, empty, and error states exist for anything asynchronous.
- Text survives long strings and larger font sizes without clipping.

## Diff hygiene

- Only files the task allowed. `git diff --stat` before reporting.
- No reformatting sprees, no version bumps you were not asked for, no
  regenerated lockfile noise beyond the dependency you added.
- If you deleted a test, the report must say which one and why. Deleting tests is
  a finding, not a cleanup.

## Honesty

The report says what you ran and what it returned. If something is unverified,
write "not verified here". A false pass costs a whole night of unattended work;
admitting a gap costs one sentence.
