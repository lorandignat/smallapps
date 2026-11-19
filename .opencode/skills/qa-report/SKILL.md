---
name: QA Reports
description: Write qa/reports/TASK-###-review.md with per-criterion evidence, ordered findings and a defensible verdict. Use at the end of every verification.
---

# Review reports

The BA makes a release decision from this file alone. Write it so a stranger
could re-run your verification.

## File

`qa/reports/TASK-###-review.md`, from `qa/reports/TASK-000-review-template.md`.
Overwrite the attempt number and keep every heading. One file per task; add
`## Attempt 2` sections rather than creating `-2` files.

## Required content

1. **Criteria table** — every criterion, its verdict, and the evidence.
2. **What I ran** — commands and exit codes, pasted, not summarised. For a long
   log, cite the path and paste only the lines that carry the result.
3. **Findings** — ordered BLOCKER → MAJOR → MINOR, each with `file:line`, what is
   wrong, how to reproduce, and the smallest acceptable fix.
4. **Regressions** — the regression list result.
5. **Unverifiable here** — what you could not check and why.
6. **Verdict** — one word, then one sentence of reasoning, then what happens next.

## Severity

- **BLOCKER** — a criterion is unmet, data can be lost, or the app does not run.
  Always `FAIL`.
- **MAJOR** — a criterion is met only on the happy path, or scope was violated.
  Always `FAIL`.
- **MINOR** — cosmetic, or a quality issue outside the criteria. Record it; do
  not fail the task for it unless it repeats.

## Writing findings

```md
1. **BLOCKER** — `src/save.ts:57` — saving an empty draft writes an empty record.
   Repro: tap Save with the field empty, reopen; the list shows a blank row.
   Expected per criterion 1: button disabled, message "Nothing to save".
   Fix: guard in `saveDraft` and return early; add a test for the empty case.
```

Not: "save needs work".

## Verdict discipline

- `PASS` + a MINOR finding is fine; say so explicitly.
- `FAIL` needs at least one finding that maps to a criterion or a regression.
- Never use `PARTIAL`. If most criteria pass and one does not, it is `FAIL`.
- If the same finding appears for the second time, say "second occurrence" and
  name it as a recurring pattern in `journal/<role>.md` — the BA needs that signal.

## After writing

Update `qa/REGRESSION.md` with anything newly proven, append to `journal/<role>.md`,
and reply with the short verdict format. Never edit source.
