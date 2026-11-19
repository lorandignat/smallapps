---
id: TASK-007
title: Record advertisement events in a diagnostic log
feature: FEAT-001
status: done
attempts: 1
owner: null
depends_on: [TASK-006]
estimate: small
---

# TASK-007 — Record advertisement events in a diagnostic log

## Goal

Anything that happens to the advertisement — start, stop, failure, a rejected
connection — leaves one timestamped line in an in-app log that survives for the
session, and every app launch starts that log with a `Restart` line, so a failed
demo has a written trace and FEAT-001's S5 can tell which launch it is reading.

## Context for the developer

- Where it lives: `src/Diagnostics/EventLog.swift`, wired in `src/AppState.swift`
- Interfaces it may touch: `AppState`'s start/stop/failure paths (TASK-006) and
  `AppState.init` for the launch marker
- Files in scope (3): the source above, `src/AppState.swift`, and
  `test/EventLogTests.swift`
- In memory only, bounded, thread-safe. No file writing here: export is TASK-008.
  No `os_log`/`Logger` as the store — the log must be readable in-process.
- The `Restart` marker is recorded where `AppState` comes into existence (its
  `init`); `src/PlayTwoApp.swift` already constructs it and is **not** in
  scope.
- Explicitly **do not** touch: `project.yml`, `src/AirPlay/`, `src/Net/`,
  `src/ContentView.swift`, `src/PlayTwoApp.swift`, `docs/`, `qa/`, `journal/`,
  `scripts/`, `.opencode/`.

## Acceptance criteria

1. [x] Given an empty log, when `record("Advertising as PlayTwo")` is
       called, then `entries.count` is 1 and the entry text is exactly that
       string, prefixed by a `yyyy-MM-dd HH:mm:ss.SSS` timestamp within 2 seconds
       of the test's own clock.
2. [x] Given capacity 2000 and 2005 records, then `entries.count` is 2000 and the
       oldest surviving entry is record number 6 — memory is bounded.
3. [x] Given the app is advertising and then backgrounds, then the log contains a
       line whose message starts `Advertising` and names the service, and later a
       line starting `Stopped`.
4. [x] Given a fresh app process, when the app has finished launching, then the
       log's **first** entry's message is exactly `Restart` (timestamp prefix
       only, nothing after it), and every later launch records `Restart` again as
       that session's first entry — same string on the first launch and on a
       relaunch, with nothing read from disk or from the previous session.
5. [x] Given 100 records issued concurrently from 4 threads, then the log holds
       exactly 100 entries and no crash occurs.
6. [x] `EventLogTests` passes: `Executed 5 tests, with 0 failures`.

## Verification commands

```sh
# on this host
ls play-two/src/Diagnostics/EventLog.swift
grep -n 'record(' play-two/src/AppState.swift
grep -n 'Restart' play-two/src/AppState.swift play-two/test/EventLogTests.swift

# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e' | tee /tmp/opencode/task-007-test.log
grep -E "Test Suite 'EventLogTests' (passed|failed)" /tmp/opencode/task-007-test.log
grep -E "Executed 5 tests, with 0 failures" /tmp/opencode/task-007-test.log
grep -E 'Test Case .*(testLaunchMarker|Restart).*passed' /tmp/opencode/task-007-test.log

# criterion 4 at file level: the exported log from TASK-008, first line is the marker
F=$(ls -t ~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/tmp/airplay-receiver-log.txt 2>/dev/null | head -1); echo "file=$F"; head -1 "$F"; grep -cE "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9:.]+ Restart$" "$F"
```

The last block needs TASK-008's export control: run it after an export, and expect
`head -1` to end in ` Restart` and the `grep -c` count to be at least 1. Until
TASK-008 exists, criterion 4 is proven by the `EventLogTests` launch-marker test
in the same block and the exported-file check is recorded as `BLOCKED (TASK-008)`
— never as a pass on the unit test alone when the file line is claimed.

**Expected today:** `QQ-005` is resolved, so `xcodebuild test` runs. The
`ls`/`grep` lines are existence evidence only.

## Definition of done

- [x] All criteria have evidence in `qa/reports/TASK-007-review.md`
- [x] `qa` verdict is `PASS`
- [x] Only files listed above changed
- [x] Regression list still passes
- [x] One commit `play-two/TASK-007: record advertisement events in a diagnostic log` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| 1 | 2026-11-19 | — | PASS (attempt 1), BA G4 2026-11-19 |

## Notes

- Criterion 3 is what stops the log being dead code: the wiring is part of this
  task, and a test asserts a real transition produces the line.
- Criterion 4 exists for FEAT-001 S5: the exported log must contain "the
  `Restart` line for that launch" (`qa/TEST-PLAN.md` O5, feature S5). The marker
  is the literal string `Restart` on **every** launch, not `Restart (2)` after
  the first: `DEC-004` and TASK-006 forbid persisting "was advertising" across
  launches, so nothing may be read from a previous session to decide which line
  to write. One launch, one `Restart` line, always.
- The marker belongs to the log, not to a new task: same file, same wiring, one
  behaviour ("record launch and advertisement events"). No UI, no export, no new
  file.
- `EventLogTests` grows from 4 tests to 5, so the running suite total after this
  task is one higher than `qa/TEST-PLAN.md` A3's `25` (and `29` after TASK-008
  instead of `28`). `qa` owns that table; the tester should update the marks, not
  fail this task over them.
- Timestamp format is fixed so TASK-008's export is diffable and so the human can
  line the log up against the Apple TV's clock. Use a `DateFormatter` built once,
  `en_US_POSIX`, `UTC` — not the device locale.
- Do not log the TXT record contents in full and never log the device id; the log
  gets exported and shared (TASK-008). Message plus outcome only.
