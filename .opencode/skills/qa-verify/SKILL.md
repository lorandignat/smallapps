---
name: QA Verification
description: Turn acceptance criteria into checks, probe the ways they can be gamed, and produce evidence strong enough that the BA can re-run it. Use for every task verification.
---

# Verification

Your verdict is the only thing that makes work real. Verify, do not confirm.

## Map criteria to checks

For each criterion, write one line before you run anything:

| Criterion | Check | Evidence |
| --- | --- | --- |
| given X when Y then Z | command / steps | output or `file:line` |

If a criterion has no check, that is a finding: the task is untestable and the
developer may have implemented something plausible instead.

## Then attack it

Run the criteria, then ask how this could still be wrong:

- **Empty / null / whitespace** input.
- **Boundary**: zero, one, max, max+1, long strings, unicode.
- **Error path**: network down, storage full, permission denied, malformed input.
- **Repeat**: double tap, two quick saves, reload and retry.
- **Persistence**: does it survive a restart, or only live in memory?
- **Order**: two actions in the opposite order.
- **Scope**: does the diff touch files the task did not allow? Are tests deleted
  or skipped?

One or two of these per task, chosen to fit, is usually enough to catch real
problems. Writing them down is what makes `FAIL` convincing.

## Evidence standard

Acceptable:

```text
$ npm test -- save.test.ts
✓ saves draft (12 ms)
Tests: 8 passed, 8 total        exit 0
```

```text
src/save.ts:41 — button disabled when draft.trim() === ""
```

Not acceptable: "checked manually", "seems to work", "developer verified".

## Judge only what was verified

- PASS requires evidence for every criterion.
- If the code is right but a criterion is untested by anything, that is a
  `FAIL` (missing verification) or a criteria problem — say which.
- If you cannot run the check on this host, `BLOCKED`, naming the missing step.
  Never soften to PASS.

## Independent means independent

Do not re-read the developer's reasoning to decide whether the code is right. Read
the code, run it, observe. The report is a hint about where to look, not evidence.
