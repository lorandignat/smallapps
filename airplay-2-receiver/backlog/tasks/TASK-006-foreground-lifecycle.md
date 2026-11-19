---
id: TASK-006
title: Keep the advertisement in step with the foreground state
feature: FEAT-001
status: proposed
attempts: 0
owner: null
depends_on: [TASK-005]
estimate: small
---

# TASK-006 — Keep the advertisement in step with the foreground state

## Goal

The Bonjour advertisement exists exactly while the app is in the foreground:
leaving the foreground withdraws it, returning publishes the same one again, and
a transient `.inactive` state does not flap the service.

## Context for the developer

- Where it lives: `src/AirPlayReceiverApp.swift` (`@main`, `scenePhase`),
  `src/AppState.swift` (state owner)
- Interfaces it may touch: `ServiceAdvertiser` start/stop (TASK-004),
  `ReceiverStatus` (TASK-005). Read them; do not change their strings or TXT.
- Files in scope (3): the two sources above plus `test/AppStateTests.swift`
- Inject the advertiser behind a tiny protocol so the test can use a spy — that
  is the only abstraction this task adds.
- Explicitly **do not** touch: `project.yml`, `src/AirPlay/`, `src/Net/`,
  `src/ContentView.swift`, `docs/`, `qa/`, `journal/`, `scripts/`,
  `.opencode/`.

## Acceptance criteria

1. [ ] Given status `.advertising`, when `scenePhase` becomes `.background`,
       then the advertiser's `stop()` is called exactly once and the status is
       `.stopped` within 1 second.
2. [ ] Given status `.stopped` after backgrounding, when `scenePhase` becomes
       `.active`, then `start()` is called once under the same service name and
       the status is `.advertising`.
3. [ ] Given status `.advertising`, when `scenePhase` becomes `.inactive`
       (Control Centre, a call banner), then `stop()` is **not** called and the
       status stays `.advertising`.
4. [ ] Given the advertiser's stop reports `NWError.posix(.EADDRINUSE)`, when
       the app backgrounds, then the status is `.failed` and `ReceiverStatus`
       renders `Error: …` with that message — no crash.
5. [ ] `AppStateTests` passes: `Executed 4 tests, with 0 failures`.

## Verification commands

```sh
# on this host
grep -n 'scenePhase' airplay-2-receiver/src/AirPlayReceiverApp.swift
grep -n 'func stop' airplay-2-receiver/src/AppState.swift

# on the Mac (expected BLOCKED until QQ-005 resolves)
rsync -a <project> <build-host>:<build-dir>/ airplay-2-receiver
xcodegen generate
xcodebuild test airplay-2-receiver AirPlayReceiver 'platform=iOS Simulator,name=iPhone 16' | tee /tmp/opencode/task-006-test.log
grep -E "Test Suite 'AppStateTests' (passed|failed)" /tmp/opencode/task-006-test.log

# on the Mac, while the app runs in the simulator: criterion 1 then 2, by hand
dns-sd -B _airplay._tcp . > /tmp/ap2-browse.txt & BP=$!; sleep 5; kill $BP; cat /tmp/ap2-browse.txt
```

**Expected today:** everything above `xcodebuild -version` is `BLOCKED` until the
Mac is configured (`QQ-005`). Record the block, do not mark the criteria met.

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-006-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes
- [ ] One commit `airplay-2-receiver/TASK-006: keep the advertisement in step with the foreground state` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- S1's "disappears within 30 seconds of the app being killed" is not fully in the
  app's control: no code runs after a kill, and Bonjour cache expiry is set by
  the OS and the Apple TV. This task guarantees the graceful withdrawal when the
  app leaves the foreground. The kill path is the human observation S1c and is
  recorded as open question `QQ-007`; the tester must not `FAIL` the task for a
  cache that outlives the process.
- `.inactive` is excluded on purpose: treating it as background makes the service
  flap whenever a notification shade is pulled down, which shows up on the Apple
  TV as a disappearing speaker.
- Do not persist "was advertising" across launches. S5 wants a clean advertise on
  the next launch, and a persisted flag is exactly the stale-entry bug.
