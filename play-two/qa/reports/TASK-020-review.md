---
id: TASK-020-review
task: TASK-020
feature: FEAT-003
verdict: PASS
date: 2026-11-22
attempt: 1
---

# Review — TASK-020 Advertise the paired status in the AirPlay TXT record

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Unpaired: `ServiceAdvertiser.start()` builds the record, `AirPlayTXTRecord(deviceID: "0A:1B:2C:3D:4E:5F", paired: false).dictionary["sf"] == "0"`, `AirPlayTXTRecordTests.testPairedStatusAppearsInTheSFFlag` passes; the record dictionary always has the key `"sf"` | PASS | Log `/tmp/opencode/task-020-test.log:489` (`testStartPublishesTheAirPlayServiceForAValidDeviceID` passed, 0.004 s); `play-two/test/ServiceAdvertiserTests.swift:60-70` asserts the dictionary equals the six-key set including `"sf": "0"` (`:66`); `play-two/src/AirPlay/AirPlayTXTRecord.swift:71-80` — the `"sf"` entry is in the dictionary literal, so the key is always present |
| 2 | Paired: `dictionary["sf"] == "1"` and `statusFlags & AirPlayTXTRecord.statusFlagPaired != 0`; default unpaired `dictionary["sf"] == "0"` | PASS | Log `/tmp/opencode/task-020-test.log:316`; `play-two/test/AirPlayTXTRecordTests.swift:88-98` — unpaired `"0"` (`:89`), default `"0"` (`:94`), paired `"1"` (`:97`), bit check `XCTAssertNotEqual(paired.statusFlags & AirPlayTXTRecord.statusFlagPaired, 0)` (`:98`); source `play-two/src/AirPlay/AirPlayTXTRecord.swift:38,59-67` |
| 3 | `AirPlayTXTRecordTests` passes: `Executed 8 tests, with 0 failures` — the seven from TASK-019 plus `testPairedStatusAppearsInTheSFFlag`; `Set(dictionary.keys) == ["deviceid", "features", "model", "srcvers", "sf", "vv"]` in `testTXTRecordHasTheRequiredKeysAndValues` | PASS | Log `/tmp/opencode/task-020-test.log:321-322` — `Test Suite 'AirPlayTXTRecordTests' passed at 2026-11-22 14:58:15.457.` + `Executed 8 tests, with 0 failures (0 unexpected) in 0.018 (0.021) seconds`; per-case, `testPairedStatusAppearsInTheSFFlag` passed (`:316`); `play-two/test/AirPlayTXTRecordTests.swift:54-57` asserts the six-key set |
| 4 | `ServiceAdvertiserTests` passes: `Executed 4 tests, with 0 failures` — `testStartPublishesTheAirPlayServiceForAValidDeviceID` asserts the dictionary with the extra `"sf": "0"` entry | PASS | Log `/tmp/opencode/task-020-test.log:493-494` — `Test Suite 'ServiceAdvertiserTests' passed at 2026-11-22 15:11:23.608.` + `Executed 4 tests, with 0 failures`; per-case `Test Case '-[PlayTwoTests.ServiceAdvertiserTests testStartPublishesTheAirPlayServiceForAValidDeviceID]' passed (0.004 seconds).` (`:489`); `play-two/test/ServiceAdvertiserTests.swift:66` asserts `"sf": "0"` |
| 5 | Regression: R2 count ≥ 79 | PASS | Log `/tmp/opencode/task-020-test.log:509,511` — `Executed 79 tests, with 0 failures (0 unexpected) in 788.177 (788.221) seconds`; `qa/REGRESSION.md` R2 high-water raised **78 → 79** |

## What I ran

```sh
grep -nE "Test Suite '(PlayTwoTests\.xctest|AirPlayTXTRecordTests|ServiceAdvertiserTests)' (passed|failed)" /tmp/opencode/task-020-test.log
grep -nE "Test Case '(.*(testPairedStatusAppearsInTheSFFlag|testStartPublishesTheAirPlayServiceForAValidDeviceID).*)' (passed|failed)" /tmp/opencode/task-020-test.log
grep -E "Executed [0-9]+ tests?, with [0-9]+ failures" /tmp/opencode/task-020-test.log
git -C play-two status --porcelain
```

Observed (all in `/tmp/opencode/task-020-test.log`): suites `AirPlayTXTRecordTests` (`:321-322`), `ServiceAdvertiserTests` (`:493-494`), `PlayTwoTests.xctest` (`:508-511`) all passed; `** TEST SUCCEEDED **` (`:519`); 0 failed cases overall.

## Findings

1. **LOW** — `play-two/backlog/tasks/TASK-020-txt-sf.md:53-56` — the task file still says `ServiceAdvertiserTests` runs `Executed 9 tests` ("the other eight unchanged"), while the repo and the log both show **4** (`Test Suite 'ServiceAdvertiserTests' passed`, `/tmp/opencode/task-020-test.log:493`). The brief's own Verify criterion (SA = 4) and the developer's journal agree on 4; the dev flagged the 9/83 deviation to the BA. If the "9" is authoritative this needs a spec amendment and added tests; otherwise the number should be corrected to 4. Not a behaviour defect — every criterion as verified in the brief passes.

## Regressions

- R2: pass — `Test Suite 'PlayTwoTests.xctest' passed at 2026-11-22 15:11:23.617.` + `Executed 79 tests, with 0 failures (0 unexpected) in 788.177 (788.221) seconds` (`/tmp/opencode/task-020-test.log:508-511`), `** TEST SUCCEEDED **` (`:519`). High-water raised to **79** in `qa/REGRESSION.md`.

## Unverifiable on this host

None. The suite ran on the Mac (`/tmp/opencode/task-020-test.log`; suites passed at 14:58–15:11); this host is Linux without Swift/Xcode. The task file's expected SA = 9 is not achievable against the repo (live SA = 4) — Finding 1.

## Verdict

PASS — 5/5 criteria verified against the log and source; R2 = 79; no regressions; scope respected (`qa/**` + `journal/<role>.md` only; the dev diff is the 4 in-scope files + `journal/<role>.md`).

**Verdict: PASS**
