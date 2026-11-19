---
name: BA Gates
description: Approval checklists for the four BA gates - spec, features, task atomicity, and tester verdict - including how to reject and what to record. Use before approving any phase or marking a task done.
---

# Gates

A gate is a decision you record, not a vibe. Approve only after opening the
files. Every approval goes in `docs/PROJECT-STATE.md` (gates table) and, if it
involved a judgement call, into `docs/DECISIONS.md`.

## G1 — Spec (`product/SPEC.md`)

- [ ] One problem, one primary persona.
- [ ] Core flow is 3-7 numbered steps with no branches.
- [ ] Every in-scope item has a stated reason it is essential.
- [ ] ≥ 3 non-goals with reasons.
- [ ] ≥ 3 success criteria, each observable/testable.
- [ ] Platform and stack decided in `docs/PLATFORM.md`.
- [ ] No open question blocks the first feature.
- [ ] The human said yes.

## G2 — Features (`backlog/features/*.md`)

- [ ] Each feature is a vertical slice the human could be shown.
- [ ] Ordered so each feature's dependencies come first.
- [ ] Every feature traces to a spec section.
- [ ] No infrastructure-only feature ("set up CI", "refactor").
- [ ] Only the next feature has tasks.

## G3 — Tasks (`backlog/tasks/*.md`)

Apply to **every** task; one failure sends the whole batch back to PM once, with
the failing IDs and the reason.

- [ ] One behaviour. Title has no "and".
- [ ] ≤ 30 minutes of work, ≤ ~5 files, one commit.
- [ ] Every criterion is Given/When/Then and checkable.
- [ ] Exact verification commands are present.
- [ ] Files in scope named; "do not touch" named.
- [ ] No design decision left implicit.
- [ ] Depends-on IDs exist and are earlier in order.

## G4 — Verdict (per task)

- [ ] `qa/reports/TASK-0NN-review.md` exists and follows the template.
- [ ] Each criterion has evidence (command + result, or `file:line`), not a claim.
- [ ] Verdict is `PASS`, not `PARTIAL`.
- [ ] Regression list was run and is clean.
- [ ] `git diff` touches only allowed files; no unrelated edits, no deleted
      tests, no skipped tests.
- [ ] Any "unverifiable here" items are acceptable and recorded.
- [ ] Commit made, board and state updated.

## Rejecting

Write it as a fix instruction, not a complaint:

```text
G3 rejected: TASK-014, TASK-019
TASK-014 is two behaviours (save + validate). Split into save, then validate.
TASK-019 has no verification command, and "looks right" is not a criterion.
Everything else is approved.
```

Never approve with a caveat ("PASS for now", "we'll fix later"). A task either
meets the bar or goes back. If the bar is wrong, change the bar through
`DEC-###`, out loud.

## When the human pushes back on a gate

They own the product; you own the process. If they want to skip a step, say what
it costs in one line, record `DEC-### status: accepted` with their reasoning, and
proceed. Do not silently comply and do not lecture.
