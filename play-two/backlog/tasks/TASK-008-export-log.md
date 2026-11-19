---
id: TASK-008
title: Export the diagnostic log to a file
feature: FEAT-001
status: blocked
attempts: 1
owner: null
depends_on: [TASK-007]
estimate: small
---

# TASK-008 — Export the diagnostic log to a file

## Goal

The owner taps one button and gets `airplay-receiver-log.txt` through the iOS
share sheet, containing the diagnostic log line for line — the evidence QA and
the human need when the Apple TV does not list the phone.

## Context for the developer

- Where it lives: `src/Diagnostics/EventLogExport.swift`, button in
  `src/ContentView.swift`
- Interfaces it may touch: `EventLog.entries` (TASK-007), `ReceiverStatus` texts
  (TASK-005)
- Files in scope (3): the source above, `src/ContentView.swift`, and
  `test/EventLogExportTests.swift`
- Write to `FileManager.default.temporaryDirectory`; share with SwiftUI
  `ShareLink` only if it is available on iOS 15.0 — otherwise a `UIActivity-
  ViewController` wrapper. No third-party share library.
- Explicitly **do not** touch: `project.yml`, `src/AirPlay/`, `src/Net/`,
  `src/AppState.swift`, `src/PlayTwoApp.swift`, `docs/`, `qa/`,
  `journal/`, `scripts/`, `.opencode/`.

## Acceptance criteria

1. [ ] Given two log entries, when `export()` runs, then a file named
       `airplay-receiver-log.txt` exists in the temporary directory whose
       contents are the two entry strings in the same order, joined by `\n` and
       terminated by one `\n`.
2. [ ] Given an empty log, when `export()` runs, then it still returns a file
       (0 bytes) and the screen's export control stays enabled.
3. [ ] Given the temporary directory cannot be written, when `export()` runs,
       then it returns `.failure` carrying the underlying message and the screen
       shows exactly `Export failed: <message>` with the status text unchanged.
4. [ ] Given the app is running in the simulator, when the export control is
       tapped, then the iOS share sheet opens with a file named
       `airplay-receiver-log.txt`.
5. [ ] `EventLogExportTests` passes: `Executed 3 tests, with 0 failures`.

## Verification commands

```sh
# on this host
ls play-two/src/Diagnostics/EventLogExport.swift
grep -n 'airplay-receiver-log.txt' play-two/src/Diagnostics/EventLogExport.swift

# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e' | tee /tmp/opencode/task-008-test.log
grep -E "Test Suite 'EventLogExportTests' (passed|failed)" /tmp/opencode/task-008-test.log

# after a manual run in the simulator: pull the exported file off the Mac
ls -l ~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/tmp/airplay-receiver-log.txt 2>/dev/null | tail -3
```

**Expected today:** `QQ-005` is resolved, so the build commands run;
criterion 4 needs a human at the simulator. Neither is a `FAIL` of this task.

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-008-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes
- [ ] One commit `play-two/TASK-008: export the diagnostic log to a file` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- The export is a pure function over `[String]` plus a directory URL, so criteria
  1-3 are unit tests. Only criterion 4 needs the simulator, and it is a described
  observation: share sheet visible, filename visible.
- Overwrite the file on every export. No history, no rotation; the session log is
  the record and 2000 lines is bounded (TASK-007).
- This closes the "log view exportable to a file" line of SPEC §4. It is in
  FEAT-001 because increment 1 is where a silent Apple TV has to be diagnosed;
  it is not a general logging framework.
