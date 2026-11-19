---
id: TASK-003
title: Answer TCP connections on port 7000
feature: FEAT-001
status: done
attempts: 3
owner: developer
depends_on: [TASK-001]
estimate: small
---

# TASK-003 — Answer TCP connections on port 7000

## Goal

The receiver accepts a TCP connection on its listener port — 7000 unless a
caller passes another — and replies with one fixed RTSP-shaped response, then
closes that connection. An accepted connection is never left silent or
half-open.

## Context for the developer

- Where it lives: `src/Net/ReceiverListener.swift`
- Interfaces it may touch: none from other tasks; it is used by TASK-004
- Files in scope (2): the source above plus `test/ReceiverListenerTests.swift`
- Contract (`DEC-011`): `init(port: NWEndpoint.Port = .init(rawValue: 7000)!)`
  and the value kept in a read-only `let port: NWEndpoint.Port` the tests can
  read. Every app call site passes no port, so the shipped port stays 7000; the
  tests construct the listener on a free port and assert the default separately.
- `Network.framework` `NWListener` with `NWProtocolTCP`; no third-party code
  (`docs/STACK.md`).
- The reply is one constant, exactly
  `RTSP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n` (38 bytes) and the connection
  is then cancelled. No request parsing in this task.
- Explicitly **do not** touch: `project.yml`, `src/AirPlay/`,
  `src/PlayTwoApp.swift`, `src/ContentView.swift`, `docs/`, `qa/`,
  `journal/`, `scripts/`, `.opencode/`.

## Acceptance criteria

1. [x] Given a listener constructed on a free port, when a client connects to
       `127.0.0.1` on the listener's port, then it receives exactly
       `RTSP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n` and the receive completes
       (`isComplete == true`) within 5 seconds.
2. [x] Given two client connections made one after the other, then both receive
       the full response — the listener is not single-use.
3. [x] Given the listener's port is already bound by another socket, when the
       listener starts, then it reports `.failed` with the underlying `NWError`
       and the process does not crash.
4. [x] Given a running listener on a free port, when `stop()` is called, then a
       new connection to `127.0.0.1` on the listener's port is refused within
       1 second.
5. [x] Given no port argument, when `ReceiverListener()` is constructed, then
       the port it reports is 7000 — the default is asserted, not assumed.
6. [x] `ReceiverListenerTests` passes: `Executed 5 tests, with 0 failures`.

## Verification commands

```sh
# on this host — the files exist, the reply and the default port are in source
ls play-two/src/Net
grep -n 'RTSP/1.0 200 OK' play-two/src/Net/ReceiverListener.swift
grep -n 'rawValue: 7000' play-two/src/Net/ReceiverListener.swift

# on the Mac — the simulator suite binds only free ports, so the Mac's
# ControlCenter holding 7000 does not matter (`DEC-011`)
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e' | tee /tmp/opencode/task-003-test.log
grep -E "Test Suite 'ReceiverListenerTests' (passed|failed)" /tmp/opencode/task-003-test.log
grep -E "Executed 5 tests, with 0 failures" /tmp/opencode/task-003-test.log
```

**Expected today:** `QQ-005` is resolved (the Mac builds and tests), so the
`xcodebuild test` line runs and must be green on the simulator. No device, no
signing and no network check is part of this task (`DEC-011`): no test binds
7000, so the Mac's AirPlay Receiver cannot make the suite red. The `ls`/`grep`
lines are not a substitute for a `PASS`.

## Definition of done

- [x] All criteria have evidence in `qa/reports/TASK-003-review.md`
- [x] `qa` verdict is `PASS`
- [x] Only files listed above changed
- [x] Regression list still passes
- [x] One commit `play-two/TASK-003: answer TCP connections on port 7000` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| 1 | 2026-11-17 | BLOCKED. Simulator: `NWListener` cannot bind 7000 — macOS ControlCenter holds it (`bind … [48: Address already in use]`). All four behaviours passed on a free port (7100 probe), but the task required 7000. No code change. | Re-cut under `DEC-010`: device destination. |
| 2 | 2026-11-17 | BLOCKED. Xcode 26.6 cannot plan unit tests on the physical device (`Logic Testing Unavailable`), so the `DEC-010` device path cannot run; nothing calls the listener until TASK-004, so the phone `nc` check could not pass in this task either. No code change. | Re-cut under `DEC-011`, attempt 3: injectable port, simulator suite. |
| 3 | 2026-11-18 | PASS, 6/6 criteria, 2 MINOR findings (reply assertion derives its expectation from the constant under test; the simulator host fails to launch the app about twice in twelve runs). Regressions green; R2 high-water raised to 13 and R4 rewritten for the free-port path. | `done`; committed as `play-two/TASK-003: answer TCP connections on port 7000`. FEAT-001 S1d stays open until TASK-004. |

## Notes

- Tests use `XCTestExpectation` with a 5 second timeout, never `sleep`. The
  default port is 7000 by the AirPlay 2 service definition, and no test binds
  it: each test asks for a free port by binding a temporary socket to port 0,
  reading the assigned number with `getsockname`, closing it, and passing that
  number to `ReceiverListener(port:)`. Port 0 is not an assertion value — the
  tests connect to and occupy the real number they were given. Every test stops
  its listener and waits for `.cancelled` in `tearDown` so the next test does
  not inherit a bound port.
- Unit behaviour is proven on a free port, which is the same code path; the real
  7000 is an app-level observation on the phone at TASK-004 wiring and feature
  close, not here (`DEC-011`).
- Port-in-use and connection-refused are the two failure paths for this task.
  Do not add retry loops or reconnection logic here.
