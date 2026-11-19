---
id: TASK-007-review
task: TASK-007
feature: FEAT-001
verdict: PASS
date: 2026-11-19
attempt: 1
---

# Review — TASK-007 Record advertisement events in a diagnostic log

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Empty log, `record("Advertising as PlayTwo")`: `entries.count == 1`; entry text is the string prefixed by a `yyyy-MM-dd HH:mm:ss.SSS` timestamp within 2 s of the test's clock | **PASS** | `testRecordAppendsTimestampedLine` (`play-two/test/EventLogTests.swift:18-40`): `entries.count == 1` (:24), `entry.message == "Advertising as PlayTwo"` (:28), `entry.text == entry.timestamp + "Advertising as PlayTwo"` (:29), timestamp parses with `utcTimestampFormatter()` and `abs(parsed.timeIntervalSinceNow) <= 2` (:31-39). Code: `record(_:)` appends `Entry(timestamp: Self.formatter.string(from: Date()), message: message)` (`play-two/src/Diagnostics/EventLog.swift:62`); `timestampFormat = "yyyy-MM-dd HH:mm:ss.SSS"` (`:34`); formatter `en_US_POSIX` + `UTC` (`:39-45`). Log: `Test Case '-[PlayTwoTests.EventLogTests testRecordAppendsTimestampedLine]' passed (0.002 seconds).` (`/tmp/opencode/task-007-test.log:364`); suite passed (`:367`); `Executed 5 tests, with 0 failures` (`:368`). |
| 2 | Capacity 2000, 2005 records: `entries.count == 2000`; oldest surviving entry is record 6 (newest is record 2005) | **PASS** | `testCapacityIsBoundedAndOldestSurvivingIsRecordSix` (`play-two/test/EventLogTests.swift:44-53`): records 1...2005, `entries.count == 2000` (:50), `entries.first?.message == "record 6"` (:51), `entries.last?.message == "record 2005"` (:52). Code: `capacity = 2000` (`play-two/src/Diagnostics/EventLog.swift:28`); append then `if storage.count > Self.capacity { storage.removeFirst(storage.count - Self.capacity) }` (`:62-65`) — after record 2005 the storage holds records 6…2005. Log: `Test Case '-[PlayTwoTests.EventLogTests testCapacityIsBoundedAndOldestSurvivingIsRecordSix]' passed (0.005 seconds).` (`/tmp/opencode/task-007-test.log:360`). |
| 3 | Advertising then backgrounding: log holds a line starting `Advertising` naming the service (`PlayTwo`), and later a line starting `Stopped` | **PASS** | `testAdvertisingThenBackgroundingLeavesAdvertisingThenStopped` (`play-two/test/EventLogTests.swift:57-75`): messages are `["Restart", "Advertising as PlayTwo", "Stopped"]`; `messages.firstIndex { $0.hasPrefix("Advertising") && $0.contains("PlayTwo") }` (:67); `messages.firstIndex { $0.hasPrefix("Stopped") }` (:69); `advertising < stopped` (:74). Code: `AppState.handleAdvertiserState` records `eventLog.record("Advertising as \(advertiser.name)")` on `.advertising` (`play-two/src/AppState.swift:80`) and `eventLog.record("Stopped")` on `.stopped` (`:82`); `SpyAdvertiser` default `name == "PlayTwo"` (`play-two/test/AppStateTests.swift:14`). Log: `Test Case '-[PlayTwoTests.EventLogTests testAdvertisingThenBackgroundingLeavesAdvertisingThenStopped]' passed (0.002 seconds).` (`/tmp/opencode/task-007-test.log:358`). |
| 4 | First entry of every launch is exactly `Restart` (timestamp prefix only, nothing after); a relaunch records the same marker; nothing read from disk or the previous session | **PASS** | `testRestartMarkerIsTheFirstEntryOfEveryLaunch` (`play-two/test/EventLogTests.swift:79-89`): `entries.first?.message == "Restart"` (:81), `entry.text == entry.timestamp + "Restart"` (:85); relaunch: `relaunch.eventLog.entries.first?.message == "Restart"` (:88). Code: `AppState.init` → `eventLog.record("Restart")` (`play-two/src/AppState.swift:66`); `eventLog` is an instance `let` (`:62`); `EventLog` storage starts empty and is memory-only (`play-two/src/Diagnostics/EventLog.swift:9,48-52,54`). Log: `Test Case '-[PlayTwoTests.EventLogTests testRestartMarkerIsTheFirstEntryOfEveryLaunch]' passed (0.001 seconds).` (`/tmp/opencode/task-007-test.log:366`). |
| 5 | 100 records from 4 threads: exactly 100 entries, no crash | **PASS** | `testConcurrentRecordsProduceExactlyOneHundredEntries` (`play-two/test/EventLogTests.swift:93-108`): 4 threads × 25 records, `entries.count == 100` (:107). Code: `record()` appends under `NSLock` (`play-two/src/Diagnostics/EventLog.swift:59-66`); `entries` returns a copy under the lock (`:48-52`). Log: `Test Case '-[PlayTwoTests.EventLogTests testConcurrentRecordsProduceExactlyOneHundredEntries]' passed (0.001 seconds).` (`/tmp/opencode/task-007-test.log:362`). |
| 6 | `EventLogTests` passes: `Executed 5 tests, with 0 failures` | **PASS** | Log: `Test Suite 'EventLogTests' passed at 2026-11-19 22:05:21.495.` (`/tmp/opencode/task-007-test.log:367`) and `Executed 5 tests, with 0 failures (0 unexpected) in 0.011 (0.016) seconds` (`:368`); the five `Test Case '-[PlayTwoTests.EventLogTests …]' passed` lines are at `:357-366`. Whole run: `Executed 30 tests, with 0 failures` (`:413, :415`), `** TEST SUCCEEDED **` (`:423`). Build: `** BUILD SUCCEEDED **` (developer evidence, `journal/<role>.md` line 756). |

## Scope

- Wip commit stat (`git show --stat 55ca41b`): `play-two/src/AppState.swift` (40), `play-two/src/Diagnostics/EventLog.swift` (67, new), `play-two/test/EventLogTests.swift` (109, new) — the three in-scope files, nothing else.
- `git diff --stat HEAD` in `play-two`: `play-two/backlog/tasks/TASK-007-diagnostic-log.md | 4 ++--` and `play-two/journal/<role>.md | 22 +++` — pre-existing process files, not source/test files. No changes under `src/`, `test/` or manifests beyond the commit's three files.

## What I ran (static, this host)

```sh
grep -c 'packages:' play-two/project.yml                      # 0
grep -n 'iOS: "15.0"' play-two/project.yml                    # line 13
grep -A1 '^schemes:' play-two/project.yml                     # "PlayTwo:"
grep -c 'DEVELOPMENT_TEAM' play-two/project.yml               # 0
grep -rnE 'XCTSkip|\.skip' play-two/test                      # no skips
grep -nE 'xcodeproj|build/' play-two/.gitignore               # :2 and :5
grep -rn 'AirPlayReceiver' play-two/project.yml play-two/src play-two/test   # none
grep -c 'bundleIdPrefix' play-two/project.yml                 # 0
grep -c 'CFBundleDisplayName' play-two/project.yml            # 0
grep -n 'static let features: UInt64 = 0x3C356BD04A7FCA00' play-two/src/AirPlay/AirPlayTXTRecord.swift  # :23; bit 38 → True
grep -n 'status.statusText(name: AppInfo.displayName)' play-two/src/ContentView.swift                  # :10
grep -nF 'Advertising as \(name)' play-two/src/AppState.swift                                             # :15
grep -nF 'Error: \(message)' play-two/src/AppState.swift                                                  # :17
grep -n 'case .inactive' play-two/src/AppState.swift           # :108
grep -n 'handleScenePhase' play-two/src/PlayTwoApp.swift       # :36
```

Key log quotes (`/tmp/opencode/task-007-test.log`):

```
Test Case '-[PlayTwoTests.EventLogTests testAdvertisingThenBackgroundingLeavesAdvertisingThenStopped]' passed (0.002 seconds).
Test Case '-[PlayTwoTests.EventLogTests testCapacityIsBoundedAndOldestSurvivingIsRecordSix]' passed (0.005 seconds).
Test Case '-[PlayTwoTests.EventLogTests testConcurrentRecordsProduceExactlyOneHundredEntries]' passed (0.001 seconds).
Test Case '-[PlayTwoTests.EventLogTests testRecordAppendsTimestampedLine]' passed (0.002 seconds).
Test Case '-[PlayTwoTests.EventLogTests testRestartMarkerIsTheFirstEntryOfEveryLaunch]' passed (0.001 seconds).
Test Suite 'EventLogTests' passed at 2026-11-19 22:05:21.495.
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.011 (0.016) seconds
	 Executed 30 tests, with 0 failures (0 unexpected) in 0.190 (0.207) seconds
** TEST SUCCEEDED **
```

## Findings

1. MINOR — process: R2's high-water mark in `qa/REGRESSION.md` is 25; the suite now runs 30 tests (EventLogTests +5, plus the pre-existing 25). The mark should be raised 25 → 30 by qa (the task note says the tester should update the marks). Not modified here — the user brief says no state-file edits.

## Regressions (from `qa/REGRESSION.md`)

- R2: pass — `Executed 30 tests, with 0 failures` (`/tmp/opencode/task-007-test.log:413,415`) ≥ 30; suite split: AirPlayTXTRecordTests 7 + AppInfoTests 1 + AppStateTests 4 + EventLogTests 5 + ReceiverListenerTests 5 + ReceiverStatusTests 4 + ServiceAdvertiserTests 4.
- R10: unit half pass — `AppStateTests` passed, `Executed 4 tests, with 0 failures` (`/tmp/opencode/task-007-test.log:354-355`); static pass (`case .inactive` at `play-two/src/AppState.swift:108`, `handleScenePhase` at `play-two/src/PlayTwoApp.swift:36`). The real-app active-restart half is the pre-existing R10 caveat (TASK-006 review; unblocked by the TASK-006 rework, not by TASK-007).
- R1: build green — `** BUILD SUCCEEDED **` (developer evidence, `journal/<role>.md` line 756).
- R3: static pass (greps above); Mac half (`xcodebuild -list` scheme/target check) quoted green by developer evidence.
- R4: unit half pass — ReceiverListenerTests passed, 5 tests (`/tmp/opencode/task-007-test.log:386-387`); app-level port-7000 half is deferred to TASK-004 per REGRESSION.md.
- R5: pass — no skips; `.gitignore` has `*.xcodeproj/` and `build/`.
- R6: not applicable — display-name contract unchanged by TASK-007 (REGRESSION.md row: pass since TASK-010).
- R7: pass — no `AirPlayReceiver`, `bundleIdPrefix` 0, `CFBundleDisplayName` 0.
- R8: pass — constant at `play-two/src/AirPlay/AirPlayTXTRecord.swift:23`, bit 38 → `True`.
- R9: static pass — `status.statusText(name: AppInfo.displayName)` (`play-two/src/ContentView.swift:10`), `"Advertising as \(name)"` (`play-two/src/AppState.swift:15`), `"Error: \(message)"` (`play-two/src/AppState.swift:17`).

## Unverifiable on this host

- Mac-side runs of `xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.5'` and `xcodebuild build -scheme PlayTwo -sdk iphoneos` — evidence is the quoted output in `/tmp/opencode/task-007-test.log` and the developer report (`** TEST SUCCEEDED **`, `** BUILD SUCCEEDED **`). Per `play-two/docs/STACK.md`: "The tester may claim a PASS only from quoted build output or the human's observation of the Apple TV." That quoted output is present in the log.
- R3's Mac half (`xcodebuild -list` scheme/targets check) — same basis.
- R6 mutation probe — not applicable (contract unchanged).

## Verdict

**Verdict: PASS**
