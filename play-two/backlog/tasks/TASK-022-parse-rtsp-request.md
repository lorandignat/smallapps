---
id: TASK-022
title: Parse an RTSP request line and headers
feature: FEAT-005
status: in-progress
attempts: 1
owner: null
depends_on: []
estimate: small
---

# TASK-022 — Parse an RTSP request line and headers

## Goal

A pure Swift parser turns raw RTSP/1.0 request bytes into a method, target,
CSeq and header map, so RTSP handlers can answer real Apple TV requests without
guessing at wire format.

## Context for the developer

- Where it lives: `src/RTSP/RTSPRequest.swift` (new), `test/RTSPRequestTests.swift` (new).
- Interfaces it may touch: `Foundation` only; no existing HAP/Net types required.
- Files in scope (2): the two above.
- Explicitly **do not** touch: `project.yml`, `src/PlayTwoApp.swift`,
  `src/ContentView.swift`, `src/Net/`, `src/HAP/`, `src/AirPlay/`,
  `src/Diagnostics/`, `docs/`, `qa/`, journals other than `journal/<role>.md`,
  `scripts/`, `.opencode/`.
- RTSP request shape: `METHOD SP target SP RTSP/1.0\r\n`, header lines
  `Name: value\r\n`, blank line terminator. `CSeq` is an integer header used by
  the response; parsing should preserve it as a header value (and may also expose
  a convenience accessor).

## Acceptance criteria

1. [ ] Given bytes for `OPTIONS * RTSP/1.0\r\nCSeq: 1\r\n\r\n`, when
       `RTSPRequest.parse(_:)` runs, then it returns a request with
       `method == "OPTIONS"`, `target == "*"`, and `cseq == 1`.
2. [ ] Given a request with a `Content-Length: N` body, when parsed, then the
       returned `body` contains exactly those `N` bytes and no trailing bytes.
3. [ ] Given malformed input (missing request line, unknown protocol token, or
       truncated body shorter than `Content-Length`), when parsed, then it
       returns `nil` (or throws a typed parse error) and does not crash.
4. [ ] `RTSPRequestTests` passes: `Test Suite 'RTSPRequestTests' passed` and
       `Executed 3 tests, with 0 failures` — covering the three cases above.

## Verification commands

```sh
# on this host
ls play-two/src/RTSP play-two/test

# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.2' | tee /tmp/opencode/task-022-test.log
grep -E "Test Suite 'RTSPRequestTests' (passed|failed)" /tmp/opencode/task-022-test.log
grep -E "Executed [0-9]+ tests?, with 0 failures" /tmp/opencode/task-022-test.log | tail -1
```

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-022-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes: `R2` count ≥ 84 (expect ≈ 84 after the run; QA/BA update `qa/REGRESSION.md`)
- [ ] One commit `play-two/TASK-022: parse an RTSP request line and headers` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- Pure value type; no I/O, no socket, no state. Simulator-unit-testable.
- Do not invent Apple TV-specific headers; only parse what the bytes contain.
  The fixture bytes in tests should be minimal valid RTSP, not copied from a
  proprietary capture.
- TASK-023 uses this type to build the OPTIONS response; TASK-024 wires parsing
  into the live port.
