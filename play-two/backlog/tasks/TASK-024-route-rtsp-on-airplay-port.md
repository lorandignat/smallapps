---
id: TASK-024
title: Route RTSP requests on the AirPlay port
feature: FEAT-005
status: approved
attempts: 0
owner: null
depends_on: [TASK-023]
estimate: small
---

# TASK-024 — Route RTSP requests on the AirPlay port

## Goal

The AirPlay port accepts an RTSP `OPTIONS` request and returns the RTSP 200
response, while existing HAP `HTTP/1.1` requests still route to `HAPServer`
unchanged.

## Context for the developer

- Where it lives: `src/Net/ServiceAdvertiser.swift` (modified),
  `src/RTSP/RTSPRouter.swift` (new, or equivalent small router type),
  `test/RTSPRouteTests.swift` (new).
- Interfaces it may touch: `ReceiverListener.connectionHandler`,
  `HAPServer.handle`, `RTSPRequest.parse`, `RTSPResponse.options`.
- Files in scope (3): the three above. If the developer chooses to put the
  router inside an existing file, keep the diff within these files and record it
  in the journal; do not spread the change across unrelated files.
- Explicitly **do not** touch: `project.yml`, `src/PlayTwoApp.swift`,
  `src/ContentView.swift`, `src/HAP/HAPServer.swift` route table (it already
  owns HTTP routes; RTSP detection happens before/around it, not by changing its
  HTTP semantics), `src/HAP/SRP.swift`, `src/HAP/TLV8.swift`,
  `src/AirPlay/`, `src/Diagnostics/`, `docs/`, `qa/`, journals other than
  `journal/<role>.md`, `scripts/`, `.opencode/`.

## Acceptance criteria

1. [ ] Given a live connection on an ephemeral port with the router installed as
       the connection handler, when the client sends
       `OPTIONS * RTSP/1.0\r\nCSeq: 7\r\n\r\n`, then the response begins with
       `RTSP/1.0 200 OK\r\n` and contains `CSeq: 7\r\n`.
2. [ ] Given the same router/port, when the client sends
       `GET /info HTTP/1.1\r\nContent-Length: 0\r\n\r\n`, then the response is
       HTTP 200 with the existing HAP info JSON body containing
       `"category": "speaker"` (R4 behaviour preserved).
3. [ ] `RTSPRouteTests` passes: `Test Suite 'RTSPRouteTests' passed` and
       `Executed 2 tests, with 0 failures` — covering the two cases above.
4. [ ] Regression: `HAPServerTests` still passes with 10/10 and
       `ReceiverListenerTests` with 4/4 in the same full run.

## Verification commands

```sh
# on this host
ls play-two/src/RTSP play-two/src/Net play-two/test

# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.2' | tee /tmp/opencode/task-024-test.log
grep -E "Test Suite '(RTSPRouteTests|HAPServerTests|ReceiverListenerTests)' (passed|failed)" /tmp/opencode/task-024-test.log
grep -E "Executed [0-9]+ tests?, with 0 failures" /tmp/opencode/task-024-test.log | tail -1
```

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-024-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes: `R2` count ≥ 89 (expect ≈ 89 after the run; QA/BA update `qa/REGRESSION.md`); R4 HAPServerTests 10/10, ReceiverListenerTests 4/4
- [ ] One commit `play-two/TASK-024: route RTSP requests on the AirPlay port` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- The detection rule must be based on the request line/protocol token, not on
  guessing by port or by trying HTTP first and falling back silently. A request
  that is neither valid RTSP nor valid HTTP should fail closed (connection
  cancelled / no response), matching the existing HAPServer behaviour for
  unparsable input.
- This task wires OPTIONS only. SETUP routing is added when FEAT-005's SETUP
  handler exists; do not add speculative SETUP/ANNOUNCE routes here.
- Keep HAPServer's HTTP contract intact; DEC-018 retired the fixed reply, not
  the HTTP routes.
