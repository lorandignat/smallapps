---
id: TASK-007
title: Record advertisement events in a diagnostic log
feature: FEAT-001
status: proposed
attempts: 0
owner: null
depends_on: [TASK-006]
estimate: small
---

# TASK-007 — Record advertisement events in a diagnostic log

## Goal

Anything that happens to the advertisement — start, stop, failure, a rejected
connection — leaves one timestamped line in an in-app log that survives for the
session, so a failed demo has a written trace.

## Context for the developer

- Where it lives: `src/Diagnostics/EventLog.swift`, wired in `src/AppState.swift`
- Interfaces it may touch: `AppState`'s start/stop/failure paths (TASK-006)
- Files in scope (3): the source above, `src/AppState.swift`, and
  `test/EventLogTests.swift`
- In memory only, bounded, thread-safe. No file writing here: export is TASK-008.
  No `os_log`/`Logger` as the store — the log must be readable in-process.
- Explicitly **do not** touch: `project.yml`, `src/AirPlay/`, `src/Net/`,
  `src/ContentView.swift`, `src/AirPlayReceiverApp.swift`, `docs/`, `qa/`,
  `journal/`, `scripts/`, `.opencode/`.

## Acceptance criteria

1. [ ] Given an empty log, when `record("Advertising as AirPlay Receiver")` is
       called, then `entries.count` is 1 and the entry text is exactly that
       string, prefixed by a `yyyy-MM-dd HH:mm:ss.SSS` timestamp within 2 seconds
       of the test's own clock.
2. [ ] Given capacity 2000 and 2005 records, then `entries.count` is 2000 and the
       oldest surviving entry is record number 6 — memory is bounded.
3. [ ] Given the app is advertising and then backgrounds, then the log contains a
       line whose message starts `Advertising` and names the service, and later a
       line starting `Stopped`.
4. [ ] Given 100 records issued concurrently from 4 threads, then the log holds
       exactly 100 entries and no crash occurs.
5. [ ] `EventLogTests` passes: `Executed 4 tests, with 0 failures`.

## Verification commands

```sh
# on this host
ls airplay-2-receiver/src/Diagnostics/EventLog.swift
grep -n 'record(' airplay-2-receiver/src/AppState.swift

# on the Mac (expected BLOCKED until QQ-005 resolves)
rsync -a <project> <build-host>:<build-dir>/ airplay-2-receiver
xcodegen generate
xcodebuild test airplay-2-receiver AirPlayReceiver 'platform=iOS Simulator,name=iPhone 16' | tee /tmp/opencode/task-007-test.log
grep -E "Test Suite 'EventLogTests' (passed|failed)" /tmp/opencode/task-007-test.log
grep -E "Executed 4 tests, with 0 failures" /tmp/opencode/task-007-test.log
```

**Expected today:** `xcodebuild test` is `BLOCKED` until the Mac is configured
(`QQ-005`). The `ls`/`grep` lines are existence evidence only.

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-007-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes
- [ ] One commit `airplay-2-receiver/TASK-007: record advertisement events in a diagnostic log` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- Criterion 3 is what stops the log being dead code: the wiring is part of this
  task, and a test asserts a real transition produces the line.
- Timestamp format is fixed so TASK-008's export is diffable and so the human can
  line the log up against the Apple TV's clock. Use a `DateFormatter` built once,
  `en_US_POSIX`, `UTC` — not the device locale.
- Do not log the TXT record contents in full and never log the device id; the log
  gets exported and shared (TASK-008). Message plus outcome only.
