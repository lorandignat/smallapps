---
id: TASK-003
title: Answer TCP connections on port 7000
feature: FEAT-001
status: proposed
attempts: 0
owner: null
depends_on: [TASK-001]
estimate: small
---

# TASK-003 — Answer TCP connections on port 7000

## Goal

The receiver accepts a TCP connection on port 7000 and replies with one fixed
RTSP-shaped response, then closes that connection. Nothing on port 7000 is left
silent or half-open.

## Context for the developer

- Where it lives: `src/Net/ReceiverListener.swift`
- Interfaces it may touch: none from other tasks; it is used by TASK-004
- Files in scope (2): the source above plus `test/ReceiverListenerTests.swift`
- `Network.framework` `NWListener` with `NWProtocolTCP`; no third-party code
  (`docs/STACK.md`).
- The reply is one constant, exactly
  `RTSP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n` (43 bytes) and the connection
  is then cancelled. No request parsing in this task.
- Explicitly **do not** touch: `project.yml`, `src/AirPlay/`,
  `src/PlayTwoApp.swift`, `src/ContentView.swift`, `docs/`, `qa/`,
  `journal/`, `scripts/`, `.opencode/`.

## Acceptance criteria

1. [ ] Given a listener on port 7000, when a client connects to
       `127.0.0.1:7000`, then it receives exactly
       `RTSP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n` and the receive completes
       (`isComplete == true`) within 5 seconds.
2. [ ] Given two client connections made one after the other, then both receive
       the full response — the listener is not single-use.
3. [ ] Given port 7000 is already bound by another socket, when the listener
       starts, then it reports `.failed` with the underlying `NWError` and the
       process does not crash.
4. [ ] Given a running listener, when `stop()` is called, then a new connection
       to `127.0.0.1:7000` is refused within 1 second.
5. [ ] `ReceiverListenerTests` passes: `Executed 4 tests, with 0 failures`.

## Verification commands

```sh
# on this host
ls play-two/src/Net
grep -n 'RTSP/1.0 200 OK' play-two/src/Net/ReceiverListener.swift

# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e' | tee /tmp/opencode/task-003-test.log
grep -E "Test Suite 'ReceiverListenerTests' (passed|failed)" /tmp/opencode/task-003-test.log
grep -E "Executed 4 tests, with 0 failures" /tmp/opencode/task-003-test.log

# on the Mac, once the app runs on the simulator and prints its address
nc -vz 127.0.0.1 7000
```

**Expected today:** `QQ-005` is resolved, so the build steps run and must
be green. The loopback `nc` check only means something while the app is running on
the simulator, which the tester may not assume.

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-003-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes
- [ ] One commit `play-two/TASK-003: answer TCP connections on port 7000` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- Tests use `XCTestExpectation` with a 5 second timeout, never `sleep`. Port
  7000 is fixed by the AirPlay 2 service definition, so the tests must free it
  in `tearDown` or the next test fails on criterion 3's error path.
- `NWListener` on the simulator binds the Mac's loopback; that is sufficient
  evidence for "listens and answers". Whether the Apple TV can reach it is the
  human's S1 observation on the phone, never a simulator claim.
- Port-in-use and connection-refused are the two failure paths for this task.
  Do not add retry loops or reconnection logic here.
