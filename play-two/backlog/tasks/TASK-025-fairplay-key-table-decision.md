---
id: TASK-025
title: Decide how FairPlay key tables enter the app
feature: FEAT-005
status: done
attempts: 1
owner: ba
depends_on: [TASK-024]
estimate: small
---

# TASK-025 — Decide how FairPlay key tables enter the app

## Goal

The BA records a decision that settles how the FairPlay v3 key tables required
by SPEC §4 increment 3 enter the app, in what format, from where, and how they
stay out of version control, so TASK-027 and TASK-028 can implement against a
defined boundary without guessing or adding a dependency.

## Context for the developer

- This is a **decision task owned by the BA**, not a code implementation task.
  It produces a `DEC-###` in `play-two/docs/DECISIONS.md` (BA-owned file) and a
  short resolution note in `play-two/docs/QUESTIONS.md` for `QQ-010`.
- Inputs the BA must read before deciding: `play-two/product/SPEC.md` §4
  (increment 3), §7 (FairPlay personal-use/sideload-only, never distributed),
  `play-two/docs/STACK.md` (no dependency without DEC + human approval),
  `play-two/docs/DECISIONS.md` DEC-001, `play-two/docs/SPIKE-001-airplay2.md`,
  and the openairplay/airplay2-receiver reference named by SPIKE-001.
- Files in scope for the BA: `play-two/docs/DECISIONS.md`,
  `play-two/docs/QUESTIONS.md`, `play-two/docs/STATE.md` (if needed to record
  the block), and this task's status in board/file frontmatter.
- Explicitly **do not** touch: `src/`, `test/`, `project.yml`, `scripts/`,
  `qa/`, journals other than `journal/<role>.md`, `.opencode/`. Do not commit or
  copy any real FairPlay key table into the repository.

## Acceptance criteria

1. [x] Given TASK-025 is complete, when a reviewer reads
       `play-two/docs/DECISIONS.md`, then a `DEC-###` entry exists with status
       `accepted` or `proposed` (if human approval is pending), recording: the
       source/format of the key table, the runtime injection boundary (how code
       receives it without hardcoding a repo path to real DRM material), how it
       is kept out of git, and the personal-use/sideload-only constraint.
       Evidence: `play-two/docs/DECISIONS.md` DEC-015 (proposed, 2026-11-22).
2. [x] Given TASK-025 is complete, when a reviewer reads
       `play-two/docs/QUESTIONS.md`, then a `QQ-010` row (or equivalent) exists
       that names the DEC and states whether it blocks TASK-027/TASK-028.
       Evidence: `play-two/docs/QUESTIONS.md` QQ-010 names DEC-015 and blocks
       TASK-027/TASK-028 until human approval.
3. [x] Given TASK-025 is complete, when a reviewer reads the DEC, then it states
       explicitly that no real Apple DRM key table is committed, bundled in a
       distributable artifact, or uploaded, and that tests use only a
       synthetic/injected fixture.
       Evidence: DEC-015 "Git/distribution exclusion" and "Tests" sections.
4. [x] Given TASK-025 is complete and the decision requires a new dependency,
       SDK, tool, or package not in `docs/STACK.md`, when a reviewer reads the
       DEC and backlog task statuses, then the DEC marks it as needing human
       approval before TASK-027 starts and TASK-027/TASK-028 remain `proposed`
       until that approval is recorded.
       Evidence: DEC-015 states no new dependency/SDK/tool/package; FairPlay v3
       is in-project Swift using Foundation/CryptoKit per STACK.md. DEC is
       proposed pending human approval (DRM boundary, PROCESS §8); TASK-027/028
       remain approved but gated — must not start until human approves DEC-015.

## Verification commands

```sh
# on this host (BA/human-verifiable)
grep -n "FairPlay key table" play-two/docs/DECISIONS.md
grep -n "QQ-010" play-two/docs/QUESTIONS.md
# Confirm no key-table blob was committed:
git -C /homedir/agent/opencode/apps ls-files | grep -i fairplay | grep -v DECISIONS | grep -v TASK-025 | grep -v FEAT-005 || echo "no fairplay files tracked"
```

## Definition of done

- [x] All criteria have evidence recorded by the BA (journal or DEC reference)
- [x] BA verdict recorded; this task is not a developer/QA code PASS — BA PASS 2026-11-22, DEC-015 proposed, human approval required before 027/028
- [x] Only BA-owned files changed (DECISIONS/QUESTIONS/STATE/BOARD/task/journal)
- [x] TASK-027 and TASK-028 remain gated (approved in backlog, must not start) until human approves DEC-015

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- This task exists because SPEC §7 names the key tables as personal-use
  sideload-only material but does not define the supply/injection boundary.
  PM cannot invent that boundary; adding a dependency or bundling DRM material
  would violate `docs/STACK.md` and `DEC-001`.
- Until this DEC is resolved, TASK-027/TASK-028 may be written and reviewed as
  task definitions, but must not be moved to `in-progress`.
- The human's involvement is expected: DRM material and a credential-equivalent
  asset are outside agent autonomy (PROCESS §8).
