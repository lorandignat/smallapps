---
id: TASK-011-review
task: TASK-011
feature: FEAT-002
verdict: PASS
date: 2026-11-20
attempt: 1
---

# Review — TASK-011 TLV8 codec (encode and decode)

Scope: `git diff HEAD -- play-two/src play-two/test` → empty; the only new files
are `play-two/src/HAP/TLV8.swift` and `play-two/test/TLV8Tests.swift`, the two
files the task lists. The other modified files in the tree
(`play-two/backlog/BOARD.md`, `play-two/backlog/tasks/TASK-011-tlv8-codec.md`,
`play-two/docs/STATE.md`, `play-two/journal/<role>.md`, `play-two/journal/<role>.md`)
are BA/PM/dev process artifacts, not task files.

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Given pairs with values ≤ 255 bytes, `TLV8.encode(_:)` + `TLV8.decode(_:)` returns an equal list | PASS | `Test Suite 'TLV8Tests' passed at 2026-11-20 21:55:15.903.` — `Test Case '-[PlayTwoTests.TLV8Tests testRoundTripsEntriesWithValuesUpTo255Bytes]' passed`; round-trips `[(1,∅),(2,"A"),(3,"hello"),(3,"B"×255),(2,"world")]`. Python mirror `/tmp/opencode/tlv8_model2.py`: `ok:   crit1 swift entries`, `FAILURES: 0`. |
| 2 | A 300-byte value encodes as fragments 255 + 45 plus a same-type zero-length terminator and round-trips | PASS | `Test Case '-[PlayTwoTests.TLV8Tests testEncodes300ByteValueWithContinuationForm]' passed` — asserts `wire.count == 306`, `wire[0] == 9`, `wire[1] == 255`, `wire[257] == 9`, `wire[258] == 45`, `wire[304] == 9`, `wire[305] == 0`, then `assertDecodes(wire, to: [TLV8Entry(type: 9, value: value)])` with `value = Data(repeating: 0x42, count: 300)`. Python mirror: `ok:   crit2 layout`, `ok:   crit2 round trip`. |
| 3 | Truncated bytes decode to `nil` | PASS | `Test Case '-[PlayTwoTests.TLV8Tests testDecodeReturnsNilWhenTruncated]' passed` — `XCTAssertNil(TLV8.decode(data(1, 2, 65)))` (mid-entry), `data(1, 2)` (header without a value), `data(1)` (header cut), `data(9, 255, 65)` (fragmented entry, value cut); `grep -c "Test Suite 'TLV8Tests' failed"` → 0. Python mirror: `ok:   crit3 nil a` … `ok:   crit3 nil d`. |
| 4 | Two same-type entries stay two separate entries | PASS | `Test Case '-[PlayTwoTests.TLV8Tests testTwoEntriesWithSameTypeStaySeparate]' passed` — `[(5,"alpha"),(5,"beta")]` round-trips as two separate entries. Python mirror: `ok:   crit4 swift`. Boundary: `testRoundTripsValuesJustPast255Bytes` passed (256, 511, 512). |
| 5 | `TLV8Tests` passes: `Executed N tests, with 0 failures` including at least the four cases | PASS | `Test Suite 'TLV8Tests' passed at 2026-11-20 21:55:15.903.` — `Executed 5 tests, with 0 failures (0 unexpected) in 0.002 (0.006) seconds` (all five cases passed); whole run `Executed 38 tests, with 0 failures`; `** TEST SUCCEEDED **`, exit 0. |

## What I ran

```sh
$ ls play-two/src/HAP play-two/test
play-two/src/HAP:
TLV8.swift
play-two/test:
AirPlayTXTRecordTests.swift
AppInfoTests.swift
AppStateTests.swift
EventLogExportTests.swift
EventLogTests.swift
ReceiverListenerTests.swift
ReceiverStatusTests.swift
ServiceAdvertiserTests.swift
TLV8Tests.swift

$ xcodebuild -version                                    # exit 0
<user>@<build-host>, macOS 27.2.1 arm64, Xcode 27.2 (27B52)
log: 20261120T195202Z-check.log

$ rsync -a <project> <build-host>:<build-dir>/                            # exit 0
ok — log: 20261120T195333Z-sync.log

$ xcodegen generate   # exit 0
⚙️  Generating project...
Created project at <workspace>play-two/PlayTwo.xcodeproj

$ xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.5' | tee /tmp/opencode/task-011-test.log
# exit 0 — "ok — log: 20261120T195411Z-test.log"
$ grep -E "Test Suite 'TLV8Tests' (passed|failed)" /tmp/opencode/task-011-test.log
Test Suite 'TLV8Tests' passed at 2026-11-20 21:55:15.903.
$ grep -E "Executed [0-9]+ tests, with 0 failures" /tmp/opencode/task-011-test.log | tail -3
	 Executed 5 tests, with 0 failures (0 unexpected) in 0.002 (0.006) seconds
	 Executed 38 tests, with 0 failures (0 unexpected) in 0.135 (0.166) seconds
	 Executed 38 tests, with 0 failures (0 unexpected) in 0.135 (0.167) seconds
$ grep -E "Executed [0-9]+ tests, with [1-9][0-9]* failures" /tmp/opencode/task-011-test.log
(no output, exit 1)
$ grep -cE "Test Suite 'TLV8Tests' failed" /tmp/opencode/task-011-test.log
0

$ python3 /tmp/opencode/tlv8_model2.py                             # exit 0
ok:   crit1 swift entries
ok:   crit4 swift
FAILURES: 0

# R2 — full suite again
$ xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.5' | tee /tmp/opencode/regression-test.log
# exit 0; grep -E "Test Suite '(TLV8Tests|All tests|PlayTwoTests.xctest)' (passed|failed)" → three
#   "passed" lines at 2026-11-20 21:59:37.820
$ grep -E "Executed [0-9]+ tests, with 0 failures" /tmp/opencode/regression-test.log
# 11 lines, every one "Executed N tests, with 0 failures";
#   grep for "Executed [0-9]+ tests, with [1-9][0-9]* failures" finds nothing (exit 1)

# R5 — static
$ grep -rnE 'XCTSkip\|\.skip' play-two/test || echo 'no skips'
no skips
$ grep -nE 'xcodeproj|build/' play-two/.gitignore
2:*.xcodeproj/
5:build/

# R1 — build
$ xcodebuild build -scheme PlayTwo -sdk iphonesimulator
# ** BUILD SUCCEEDED **, exit 0 — log 20261120T195621Z-build.log
```

## Findings

1. **MINOR — `qa/REGRESSION.md` R5 row wording.** The row's literal grep
   `grep -nE 'xcodeproj\|build/' play-two/.gitignore` matches nothing (exit 1:
   `\|` is a literal pipe in ERE), while the row claims "both found". The intent
   was verified with the corrected alternation `grep -nE 'xcodeproj|build/'
   play-two/.gitignore` → `2:*.xcodeproj/`, `5:build/` — both entries present.
   Reword the row or re-test its literal pattern.

## Regressions

- R1 pass — build green (`** BUILD SUCCEEDED **`, exit 0; log
  `20261120T195621Z-build.log`).
- R2 pass — full suite, exit 0, `Executed 38 tests, with 0 failures` (log
  `/tmp/opencode/regression-test.log`); count 38 ≥ high-water mark.
  **High-water mark raised 33 → 38 by this task** — the suite grew because
  TASK-011 added the five `TLV8Tests`; the raise is recorded in the row itself
  (user said "so R2 stays" — flagged).
- R5 pass — `no skips`; `.gitignore` has `*.xcodeproj/` (line 2) and `build/`
  (line 5); see the MINOR finding on the row's literal pattern.

## Unverifiable on this host

None — sync, `xcodegen generate`, the simulator suite, the log greps, R1, R2 and
R5 all executed here (Mac bridge `check` exit 0; destination `iPhone 16e` on
`OS=26.5` per DEC-005). No iOS executes on this Linux host; everything the task
needs is on the Mac.

## Verdict

PASS — all five criteria have quoted evidence; the suite is green (`Executed 38
tests, with 0 failures`); regressions R1/R2/R5 pass; scope is clean.

**Verdict: PASS**

**Next:** BA reads the report; commit `play-two/TASK-011: TLV8 codec (encode and decode)`.
