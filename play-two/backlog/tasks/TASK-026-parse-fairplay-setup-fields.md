---
id: TASK-026
title: Parse the FairPlay fields of a SETUP request
feature: FEAT-005
status: in-progress
attempts: 2
owner: null
depends_on: [TASK-024]
estimate: small
---

# TASK-026 — Parse the FairPlay fields of a SETUP request

## Goal

A parser extracts the FairPlay-relevant fields from an RTSP `SETUP` request
body/headers into a typed model, so the handshake and key-decryption tasks can
operate on named fields instead of raw bytes.

## Context for the developer

- Where it lives: `src/RTSP/FairPlaySetup.swift` (new),
  `test/FairPlayFieldTests.swift` (new).
- Interfaces it may touch: `RTSPRequest` from TASK-022; `Foundation`.
- Files in scope (2): the two above.
- Explicitly **do not** touch: `project.yml`, `src/Net/`, `src/HAP/`,
  `src/AirPlay/`, `src/Diagnostics/`, `src/PlayTwoApp.swift`,
  `src/ContentView.swift`, `docs/`, `qa/`, journals other than `journal/<role>.md`,
  `scripts/`, `.opencode/`.
- The SETUP request carries FairPlay material in RTSP headers/body as defined by
  the AirPlay 2 receiver reference behaviour (SPIKE-001 references). The exact
  wire field names and encoding used by the Apple TV must be taken from a
  recorded fixture or the reference implementation, not invented.

## Acceptance criteria

1. [ ] Given a recorded SETUP-request fixture (bytes committed in the test as a
       static fixture, sourced from reference behaviour or a device capture
       described in the test comment), when `FairPlaySetup.parse(from:)` runs,
       then it returns a model containing the non-empty `Apple-Challenge` bytes
       and the non-empty encrypted stream-key material bytes expected by that
       fixture.
2. [ ] Given a SETUP request missing the challenge field, when parsed, then it
       returns `nil`/throws and no partial model is produced.
3. [ ] Given a SETUP request with an empty or malformed encrypted-key field,
       when parsed, then it returns `nil`/throws with no crash.
4. [ ] `FairPlayFieldTests` passes: `Test Suite 'FairPlayFieldTests' passed`
       and `Executed 3 tests, with 0 failures` — covering the three cases above.

## Verification commands

```sh
# on this host
ls play-two/src/RTSP play-two/test

# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.2' | tee /tmp/opencode/task-026-test.log
grep -E "Test Suite 'FairPlayFieldTests' (passed|failed)" /tmp/opencode/task-026-test.log
grep -E "Executed [0-9]+ tests?, with 0 failures" /tmp/opencode/task-026-test.log | tail -1
```

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-026-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes: `R2` count ≥ 92 (expect ≈ 92 after the run; QA/BA update `qa/REGRESSION.md`)
- [ ] One commit `play-two/TASK-026: parse the FairPlay fields of a SETUP request` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| 1 | 2026-11-22 | MAJOR: criterion 1 fixture not a traceable recorded static fixture with named source/date (programmatically synthesized). MAJOR (BA-process, not dev defect): BA-owned board/task status edits present in worktree; dev must not revert them. MINOR: 4 tests vs 3 stated. | rework → attempt 2 |

## Notes

- The fixture must be traceable: the test comment names where the bytes came
  from (reference implementation file/version, or "recorded from Apple TV on
  iPhone 6s, date"). Do not synthesize a fixture that merely matches the parser
  you wrote.
- This task does not perform the FairPlay handshake or decryption; it only
  parses. It can proceed in parallel with TASK-025 because it does not need the
  real key table — only wire-field shape.
- If the Apple TV sends the material in a binary plist/body form that is larger
  than expected, keep the parser narrow to the fields TASK-027/028 need; do not
  build a general RTSP/AFP parser.
