---
id: TASK-016
title: Serve `GET /info` on port 7000, replacing the fixed reply
feature: FEAT-003
status: in-progress
attempts: 1
owner: null
depends_on: []
estimate: small
---

# TASK-016 — Serve `GET /info` on port 7000, replacing the fixed reply

## Goal

The port on 7000 answers HTTP requests. `GET /info` returns the HAP accessory
info — `name`, `category: speaker`, `pairing state` — as a JSON body; every
other method or path answers 404. The increment-1 fixed 38-byte reply is gone
(`ReceiverListener.response` is deleted; BA note 2026-11-21, R4).

## Context for the developer

- Where it lives: `src/HAP/HAPServer.swift` (new), `src/Net/ReceiverListener.swift`
  (modified), `src/Net/ServiceAdvertiser.swift` (modified).
- Interfaces it may touch: `ReceiverListener`'s connection answering,
  `ServiceAdvertiser.start()`, `HAPServer.route`, `HAPServer.parse`, `HAPServer.handle`.
- Files in scope (4): `src/HAP/HAPServer.swift` (new), `src/Net/ReceiverListener.swift`
  (modified), `src/Net/ServiceAdvertiser.swift` (modified),
  `test/HAPServerTests.swift` (new).
- Explicitly **do not** touch: `project.yml`, `src/PlayTwoApp.swift`,
  `src/ContentView.swift`, `src/AirPlay/`, `src/HAP/SRP.swift`, `src/HAP/TLV8.swift`,
  `src/HAP/AccessoryIdentity.swift`, `src/Diagnostics/`, `docs/`, `qa/`, journals
  other than `journal/<role>.md`, `scripts/`, `.opencode/`.

## Acceptance criteria

1. [ ] Given a request line `GET /info HTTP/1.1` with `Content-Length: 0`, when
       `HAPServer.parse` runs, then the method is `GET`, the path is `/info`, and
       the body is empty (0 bytes).
2. [ ] Given `HAPServer().route(GET /info)`, when the response is built, then the
       status is 200 and the body contains `"name": "PlayTwo"`,
       `"category": "speaker"` and `"paired": false`.
3. [ ] Given `GET /other`, `POST /info` or `POST /pair-setup`, when routed, then
       the status is 404 (TASK-018 makes `POST /pair-setup` answer 200).
4. [ ] `HAPServerTests` passes: `Test Suite 'HAPServerTests' passed` and
       `Executed 7 tests, with 0 failures` — the seven cases: `testParseReturnsMethodPathAndBody`,
       `testParseReadsTheContentLengthBody`, `testParseReturnsNilOnMalformedInput`,
       `testRouteInfoReturns200WithNameCategoryAndPaired`, `testRouteOtherPathReturns404`,
       `testRoutePostPairSetupReturns404`, `testLiveInfoExchangeAnswersOverAPort`
       (`listener.port` on an `.any` `NWListener`; if the SDK has no `NWListener.port`,
       read the port from the ready state instead and record the deviation in the
       journal).
5. [ ] `ReceiverListenerTests` passes with the new contract: `Executed 4 tests,
       with 0 failures` — `testDefaultPortIs7000`, `testTwoSequentialConnectionsAreDelegated`
       (both connections reach `connectionHandler`), `testStartReportsFailureWhenPortIsAlreadyBound`,
       `testConnectionIsRefusedWithinOneSecondAfterStop`.

## Verification commands

```sh
# on this host
ls play-two/src/HAP play-two/src/Net play-two/test
# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.2' | tee /tmp/opencode/task-016-test.log
grep -E "Test Suite '(HAPServerTests|ReceiverListenerTests)' (passed|failed)" /tmp/opencode/task-016-test.log
grep -c 'static let response' play-two/src/Net/ReceiverListener.swift  # expect 0 — the fixed reply is gone
```

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-016-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes: `R2` count ≥ 62 (expect ≈ 62 after the run; QA/BA update `qa/REGRESSION.md`)
- [ ] One commit `play-two/TASK-016: serve GET /info on port 7000, replacing the fixed reply` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- `HAPServer` owns the facts the accessory exposes: `accessoryName` (the Home
  app shows it), `accessoryCategory = "speaker"` and the fixed setup code
  `HAPServer.setupCode = "00102003"` (generated later, `FEAT-003`'s fixed-code
  note).
- `ReceiverListener` is now a socket/port owner: `answer` calls
  `connectionHandler?` instead of sending the fixed reply; `ServiceAdvertiser.start()`
  creates the `HAPServer` and sets `listener.connectionHandler = server.handle`.
- R4 is retired from the app here. `qa/REGRESSION.md` R4 (fixed 38-byte reply)
  is reworded by QA/BA at feature close — the BA note of 2026-11-21 says so.
  The old assertions in `ReceiverListenerTests` criteria 1–2 die with the
  replacement.
- The old two-connection live assertion moved to `testTwoSequentialConnectionsAreDelegated`;
  the real HTTP exchange is asserted by `HAPServerTests`.
- TASK-018 extends `HAPServer.route` with `POST /pair-setup`; criteria 3 and 4
  state the 404 contract until then.
