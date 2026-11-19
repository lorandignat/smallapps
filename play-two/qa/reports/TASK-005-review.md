---
id: TASK-005-review
task: TASK-005
feature: FEAT-001
verdict: PASS
date: 2026-11-19
attempt: 1
---

# Review — TASK-005 Show the receiver state on the main screen

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Given status `.idle`, screen status text is exactly `Idle` | **PASS** | `src/AppState.swift:12-13` returns `"Idle"` for `.idle`; `test/ReceiverStatusTests.swift:5-9` asserts `ReceiverStatus.idle.statusText(name: AppInfo.displayName) == "Idle"` and passed. |
| 2 | Given status `.advertising`, status text is exactly `Advertising as PlayTwo` (name from `AppInfo.displayName`) | **PASS** | `src/AppState.swift:14-15` returns `"Advertising as \(name)"`; view calls `status.statusText(name: AppInfo.displayName)` (`src/ContentView.swift:10`). Test `testAdvertising` passed. Mutation probe: changing `AppInfo.displayName` to `Mutant` on the Mac copy made `testAdvertising` fail with `"Advertising as Mutant" != "Advertising as PlayTwo"` (log `/tmp/opencode/task-005-mutant.log`), proving the mapping reads the name rather than hard-coding it. |
| 3 | Given status `.failed("port 7000 in use")`, status text is exactly `Error: port 7000 in use` | **PASS** | `src/AppState.swift:16-17` returns `"Error: \(message)"`; `testFailed` passed with the verbatim message. |
| 4 | Given status `.stopped`, status text is exactly `Stopped` and the screen has no error text | **PASS** | `src/AppState.swift:18-19` returns `"Stopped"`; `testStopped` passed. `src/ContentView.swift` renders only the display name and one status `Text`; there is no separate error view, so a stopped state shows no error text. |
| 5 | `ReceiverStatusTests` passes: 4 tests, 0 failures | **PASS** | Mac run: `Test Suite 'ReceiverStatusTests' passed … Executed 4 tests, with 0 failures` (log `20261119T183240Z-test.log`). Whole run `Executed 21 tests, with 0 failures`, `** TEST SUCCEEDED **`. |

## What I ran

```sh
# static (host)
ls play-two/src/AppState.swift play-two/src/ContentView.swift            # both present, exit 0
grep -n 'Advertising as' play-two/src/AppState.swift                     # line 15
grep -c 'packages:' play-two/project.yml                                # 0
grep -rnE 'XCTSkip|\.skip' play-two/test || echo 'no skips'             # no skips
git status --short                                                      # only ContentView.swift modified + 2 new files in src/test

# Mac bridge
rsync -a <project> <build-host>:<build-dir>/                                    # ok
xcodegen generate # ok
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.5' \
  | tee /tmp/opencode/task-005-test.log                                 # exit 0
xcodebuild build -scheme PlayTwo -sdk iphonesimulator            # exit 0, ** BUILD SUCCEEDED **

# mutation probe (Mac copy only, restored afterwards)
# edited src/PlayTwoApp.swift displayName "PlayTwo" -> "Mutant" on Mac copy
xcodebuild test ...                                          # 3 failures incl. ReceiverStatusTests.testAdvertising
# restored via sync + xcodegen; sha256 src/PlayTwoApp.swift = df64fd2d…5af5add = repo
```

Key quoted lines (full log `20261119T183240Z-test.log`):

```
Test Suite 'ReceiverStatusTests' passed at 2026-11-19 20:33:21.233.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.003 (0.004) seconds
Test Suite 'PlayTwoTests.xctest' passed at 2026-11-19 20:33:21.286.
	 Executed 21 tests, with 0 failures (0 unexpected) in 0.112 (0.121) seconds
** TEST SUCCEEDED **
```

Mutation probe quoted lines (`/tmp/opencode/task-005-mutant.log`):

```
test/ReceiverStatusTests.swift:13: error: … XCTAssertEqual failed: ("Advertising as Mutant") is not equal to ("Advertising as PlayTwo")
Test Suite 'ReceiverStatusTests' failed … Executed 4 tests, with 1 failure
	 Executed 21 tests, with 3 failures …
```

## Findings

None. No BLOCKER or MAJOR. No MINOR findings: the view reads the single mapping
(`status.statusText(name: AppInfo.displayName)`), builds no status strings inline,
and adds no buttons or advertiser wiring (deferred to TASK-006).

## Regressions

R1–R8 re-run and green:

- R1 build: `** BUILD SUCCEEDED **` (log `20261119T183326Z-build.log`).
- R2 unit tests: `Executed 21 tests, with 0 failures` (high-water mark 17 → 21; `ReceiverStatusTests` 4 added). Counts: `ReceiverListenerTests` 5, `AirPlayTXTRecordTests` 7, `AppInfoTests` 1, `ServiceAdvertiserTests` 4, `ReceiverStatusTests` 4.
- R3 static: `packages:` 0, `iOS: "15.0"` at line 13, scheme `PlayTwo:`, `DEVELOPMENT_TEAM` 0.
- R5: no `XCTSkip`/`.skip`; `.gitignore` contains `*.xcodeproj/` and `build/`.
- R7: no `AirPlayReceiver`, `bundleIdPrefix` 0, `CFBundleDisplayName` 0, both plists gitignored.
- R8: 7 `AirPlayTXTRecordTests` passed; features constant at line 23; bit 38 `True`.
- R9 added for the new behaviour (status text mapping, 4 tests).

## Unverifiable on this host

- Actual on-screen rendering / visual confirmation of "no error text" for `.stopped`
  (no UI test; covered by code inspection of `ContentView` and the unit mapping).
  The task marks this as the simulator visual part.
- Device observations O1–O6 and the Apple TV speaker-list checks remain human-only
  per `qa/TEST-PLAN.md`; unchanged by this task.

## Verdict

PASS — all five criteria have evidence, the regression list is green (21/21
tests), scope is respected (only `src/AppState.swift`, `src/ContentView.swift`,
`test/ReceiverStatusTests.swift` added/changed among source/test files), and the
mutation probe confirms the advertised name flows through the mapping.

**Next:** BA gate G4, then commit `play-two/TASK-005: show the receiver state on the main screen`. TASK-006 may proceed (it will wire `AppState`/`scenePhase` to the advertiser).