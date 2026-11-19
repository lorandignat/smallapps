---
id: TASK-006-review
task: TASK-006
feature: FEAT-001
verdict: PASS
date: 2026-11-19
attempt: 2
---

# Review — TASK-006 Keep the advertisement in step with the foreground state

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Given status `.advertising`, `scenePhase` → `.background`: `stop()` called exactly once and status `.stopped` within 1 s | **PASS** | Unit: `Test Case '-[PlayTwoTests.AppStateTests testBackgroundStopsAdvertiser]' passed` (`/tmp/opencode/task-006-test.log` lines 94-95); `Test Suite 'AppStateTests' passed`, `Executed 4 tests, with 0 failures` (line 101). Real path: `AppState.handleScenePhase(.background)` calls `advertiser.stop()` when `status == .advertising \|\| advertiser.state == .advertising` (`play-two/src/AppState.swift:72-75`); `ServiceAdvertiser.stop()` → `ReceiverListener.stop()` → `cancel()` → `.cancelled` → `listenerChanged(.cancelled)` → `report(.stopped)` (`play-two/src/Net/ReceiverListener.swift:97-101,130-131`; `play-two/src/Net/ServiceAdvertiser.swift:132-134,163-165`). A second `.background` no-ops (status `.stopped`, guard false). "Within 1 s" not measurable on this host (static). |
| 2 | Given status `.stopped` after backgrounding, `scenePhase` → `.active`: `start()` called once under the same service name and status `.advertising` | **PASS** | Unit: `Test Case '-[PlayTwoTests.AppStateTests testActiveRestartsAdvertiser]' passed` (`/tmp/opencode/task-006-test.log` lines 92-93); suite `Executed 4 tests, with 0 failures` (line 101). Real-app fix path (the key new evidence): `AppState.handleScenePhase(.active)` → `advertiser.start()` (`play-two/src/AppState.swift:77-79`) → `ServiceAdvertiser.start()`'s `guard listener == nil` (`play-two/src/Net/ServiceAdvertiser.swift:99`) now passes — the rework clears `self.listener = nil` in `listenerChanged(.cancelled)` before `report(.stopped)`, the new line `play-two/src/Net/ServiceAdvertiser.swift:164` (working tree; `git diff HEAD -- play-two/src/Net/ServiceAdvertiser.swift`; before it, `start()` no-opped and status stuck at `.stopped` — attempt-1 finding #1). `start()` then creates a new `ReceiverListener` (`ServiceAdvertiser.swift:119,124`); `.ready` → `.listening` → `report(.advertising)` (`play-two/src/Net/ReceiverListener.swift:126-127`; `play-two/src/Net/ServiceAdvertiser.swift:160`) → AppState maps to `.advertising` (`play-two/src/AppState.swift:98-99`). Name: `ServiceAdvertiser.name` = `AppInfo.displayName` = "PlayTwo" (`play-two/src/Net/ServiceAdvertiser.swift:82`; `play-two/src/PlayTwoApp.swift:9`). `allowLocalEndpointReuse = true` covers the rebind (`play-two/src/Net/ReceiverListener.swift:67-71`). |
| 3 | Given status `.advertising`, `scenePhase` → `.inactive`: `stop()` not called and status stays `.advertising` | **PASS** | Unit: `Test Case '-[PlayTwoTests.AppStateTests testInactiveDoesNotStopAdvertiser]' passed` (`/tmp/opencode/task-006-test.log` lines 96-97); static: `case .inactive: break` (`play-two/src/AppState.swift:80-81`). |
| 4 | Given the advertiser's stop reports `NWError.posix(.EADDRINUSE)`, when the app backgrounds: status `.failed` and `ReceiverStatus` renders `Error: …`, no crash | **PASS** | Unit: `Test Case '-[PlayTwoTests.AppStateTests testStopFailureReportsFailed]' passed` (`/tmp/opencode/task-006-test.log` lines 98-99); mapping: spy → `ServiceAdvertiser.failure(for:)` → `.failed(String)` (`play-two/src/Net/ServiceAdvertiser.swift:170-178`) → `AppState.map` → `ReceiverStatus.failed` → `"Error: \(message)"` (`play-two/src/AppState.swift:16-17,95-106`). Note: in the real app `ServiceAdvertiser.stop()` never reports an `NWError` — EADDRINUSE arrives via `ReceiverListener.start()` `.failed` → `listenerChanged(.failed)` (`play-two/src/Net/ReceiverListener.swift:86-87,129`); the criterion is exercised through the spy, so it verifies `AppState`'s mapping, not a reachable runtime path (same as attempt-1 observation #2). |
| 5 | `AppStateTests` passes: `Executed 4 tests, with 0 failures` | **PASS** | `/tmp/opencode/task-006-test.log`: `Test Suite 'AppStateTests' passed at 2026-11-19 21:16:10.641.` · `Executed 4 tests, with 0 failures (0 unexpected) in 0.002 (0.004) seconds` · whole run `Executed 25 tests, with 0 failures` · `** TEST SUCCEEDED **`. |

## What I ran

```sh
# host (static; no Swift on this host)
grep -n 'scenePhase' play-two/src/PlayTwoApp.swift                                  # 15, 35
grep -n 'func stop' play-two/src/AppState.swift                                     # 39 (protocol)
grep -n 'self.listener = nil' play-two/src/Net/ServiceAdvertiser.swift               # 164 (rework, working tree)
git diff HEAD -- play-two/src/Net/ServiceAdvertiser.swift                           # one added line
grep -c 'XCTSkip\|\.skip' play-two/test/                                            # 0

# Mac bridge (developer evidence; exit 0)
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.5' | tee /tmp/opencode/task-006-test.log
```

Key log quotes (`/tmp/opencode/task-006-test.log`):

```
Test Case '-[PlayTwoTests.AppStateTests testActiveRestartsAdvertiser]' passed (0.001 seconds).
Test Case '-[PlayTwoTests.AppStateTests testBackgroundStopsAdvertiser]' passed (0.001 seconds).
Test Case '-[PlayTwoTests.AppStateTests testInactiveDoesNotStopAdvertiser]' passed (0.001 seconds).
Test Case '-[PlayTwoTests.AppStateTests testStopFailureReportsFailed]' passed (0.001 seconds).
Test Suite 'AppStateTests' passed at 2026-11-19 21:16:10.641.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.002 (0.004) seconds
...
	 Executed 25 tests, with 0 failures (0 unexpected) in 0.100 (0.110) seconds
** TEST SUCCEEDED **
```

Build: `** BUILD SUCCEEDED **` (developer evidence, `journal/<role>.md`).

## Findings

1. MINOR — criterion 2 real-app edge (not a criterion violation): `AppState.handleScenePhase(.active)` fires while the user returns to foreground before the `.cancelled` delivery arrives: `status == .advertising` and `advertiser.state == .advertising`, so `start()` no-ops (guard `listener != nil`); then `listenerChanged(.cancelled)` reports `.stopped` — the app sits foregrounded with status `.stopped` until the next phase change. The criterion is conditioned on status `.stopped` at `.active`, so the normal path (background → cancelled → foreground) is fixed by the rework.
2. OBSERVATION — scope: the rework touches `src/Net/ServiceAdvertiser.swift`, which TASK-006 lists as out of scope. Developer log records the BA-approved scope expansion (`journal/<role>.md`, "the BA-approved scope expansion").
3. OBSERVATION — criterion 4 is spy-modeled (see criterion 4 evidence); the real `ServiceAdvertiser.stop()` never reports `NWError`.

## Regressions

- R2: pass — whole run `Executed 25 tests, with 0 failures` (count 25 ≥ high-water 25). Per-suite split: `ReceiverListenerTests` 5 + `AirPlayTXTRecordTests` 7 + `AppInfoTests` 1 + `ServiceAdvertiserTests` 4 + `ReceiverStatusTests` 4 + `AppStateTests` 4. No `XCTSkip`/`.skip` in `play-two/test/`.
- R10: updated — the real-app active-restart half is now unblocked by the rework (`ServiceAdvertiser.swift:164`); unit suite green. Live confirmation pending (device/simulator).
- R1: build green (developer evidence).

## Unverifiable on this host

- Live republish round trip for criterion 2: static trace + rework line instead (no Swift, no simulator; `play-two/docs/STACK.md` — unit tests need the Mac).
- "Within 1 second" timing for criterion 1: not measurable here (NWListener cancel delivery is prompt; static).
- Device observations O1–O6 and the A8/P2/P3 live checks: human-only per `play-two/qa/TEST-PLAN.md`.

## Verdict

PASS — all five criteria are verified at unit level on the Mac run (`/tmp/opencode/task-006-test.log`); criterion 2's real-app republish is verified statically: the rework clears `self.listener = nil` on `.cancelled` (`play-two/src/Net/ServiceAdvertiser.swift:164`), so `ServiceAdvertiser.start()`'s `listener == nil` guard (`:99`) passes and the listener is recreated — `.ready` → `.listening` → `report(.advertising)` (`play-two/src/Net/ReceiverListener.swift:126-127`, `play-two/src/Net/ServiceAdvertiser.swift:160`) → AppState status `.advertising` (`play-two/src/AppState.swift:98-99`). Two observations (criterion-2 race window; rework scope; criterion-4 modeling) are non-blocking and recorded above. Next: BA gate G4 — read this report and the diff, then commit `play-two/TASK-006: keep the advertisement in step with the foreground state` after PASS.
