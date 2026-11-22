---
id: TASK-023
title: Answer an RTSP OPTIONS request with 200 OK
feature: FEAT-005
status: proposed
attempts: 0
owner: null
depends_on: [TASK-022]
estimate: small
---

# TASK-023 — Answer an RTSP OPTIONS request with 200 OK

## Goal

A `RTSPResponse` builder produces a valid `RTSP/1.0 200 OK` for an `OPTIONS`
request, echoing the request `CSeq`, so an Apple TV receives the response shape
it expects before setup.

## Context for the developer

- Where it lives: `src/RTSP/RTSPResponse.swift` (new), `test/RTSPResponseTests.swift` (new).
- Interfaces it may touch: `RTSPRequest` from TASK-022; `Foundation`.
- Files in scope (2): the two above.
- Explicitly **do not** touch: `project.yml`, `src/Net/`, `src/HAP/`,
  `src/AirPlay/`, `src/Diagnostics/`, `src/PlayTwoApp.swift`,
  `src/ContentView.swift`, `docs/`, `qa/`, journals other than `journal/<role>.md`,
  `scripts/`, `.opencode/`.

## Acceptance criteria

1. [ ] Given an `RTSPRequest` parsed from `OPTIONS * RTSP/1.0\r\nCSeq: 2\r\n\r\n`,
       when `RTSPResponse.options(for:)` (or equivalent builder) is called, then
       the serialized bytes begin with `RTSP/1.0 200 OK\r\n`, contain
       `CSeq: 2\r\n`, and end with `\r\n\r\n`.
2. [ ] Given an OPTIONS request with a different `CSeq`, when the response is
       built, then the response `CSeq` equals that request's `CSeq` (echo, not a
       constant).
3. [ ] `RTSPResponseTests` passes: `Test Suite 'RTSPResponseTests' passed` and
       `Executed 3 tests, with 0 failures` — the two cases above plus a case that
       the `Public`/method-advertising header required by the task's pinned
       fixture is present (the exact header name/value is pinned in the test;
       if device evidence later requires a different value, re-cut this task,
       do not silently change the fixture).

## Verification commands

```sh
# on this host
ls play-two/src/RTSP play-two/test

# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.2' | tee /tmp/opencode/task-023-test.log
grep -E "Test Suite 'RTSPResponseTests' (passed|failed)" /tmp/opencode/task-023-test.log
grep -E "Executed [0-9]+ tests?, with 0 failures" /tmp/opencode/task-023-test.log | tail -1
```

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-023-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes: `R2` count ≥ 87 (expect ≈ 87 after the run; QA/BA update `qa/REGRESSION.md`)
- [ ] One commit `play-two/TASK-023: answer an RTSP OPTIONS request with 200 OK` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- Keep the builder pure: input request, output `Data`/bytes. No socket write in
  this task; TASK-024 routes live requests.
- Criterion 3's "required header" must be justified by a reference in the test
  comment (RAOP/AirPlay RTSP reference or a recorded fixture). Do not invent a
  header value; if uncertain, pick the minimal header set the reference shows
  and pin it in the test so a device-driven change is a visible re-cut.
- This task does not answer SETUP/ANNOUNCE/RECORD; those arrive in later tasks
  or features.
