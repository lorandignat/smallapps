---
name: QA Regression
description: Maintain qa/REGRESSION.md and re-run it for every task so earlier work cannot silently break. Use before writing any verdict.
---

# Regression

A task that passes its own criteria while breaking yesterday's work is a failed
task. The regression list is how you catch that.

## Maintain

- Add a row the first time a behaviour is verified: ID, check, command, since
  (task ID), last result.
- Keep each row runnable in seconds. If a row needs a manual step, say so in the
  check column.
- Never delete a row because it now fails. A failing regression is a finding.
- Retire a row only with the BA's `DEC-###`; note it in the row.

## Run

For **every** task, before the verdict:

```sh
# the project's full test command, which should include the regression tests
```

Then spot-run any regression that the suite does not cover. Record the result in
the review file under `## Regressions`, with counts and failures.

## When a regression fails

- `FAIL`, with a BLOCKER finding that names the task where the row was born and
  the commit that likely broke it (`git log -S`, `git bisect` if it is quick).
- Do not accept "it was probably already broken". If it was, say since when, with
  evidence, and let the BA decide — never silently drop it.

## Scope checks belong here too

Two cheap rows worth keeping: the project builds from clean (`npm ci && npm test`
in a scratch copy, if quick), and no test is skipped (`--forbid-only` or grep for
`skip`). Skipped tests are how teams lie to themselves.
