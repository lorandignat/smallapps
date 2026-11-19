# REGRESSION — PlayTwo

Owner: `qa`. Every check that has ever passed stays here and must keep passing.
The tester runs this list for every task, not only at the end.

Run it in about three minutes, from the workspace root. The Mac half of R1, R2
and R3 and all of R6 need a Mac with Xcode 26.6 (iOS 26.5 SDK) and the
`iPhone 16e` simulator (`DEC-005`). A `BLOCKED` row means the Mac was
unreachable or Xcode rejected the destination: record the exact error line and
the log path. R4 stays pending until TASK-003 exists.

| ID | Check | Command | Since | Last result |
| --- | --- | --- | --- | --- |
| R1 | The app still builds for the simulator | `rsync -a <project> <build-host>:<build-dir>/ && xcodegen generate && xcodebuild build -scheme PlayTwo -sdk iphonesimulator` — expect exit 0, `** BUILD SUCCEEDED **`, and the `.app` path | TASK-001 | pass 2026-11-16 (TASK-010) — exit 0, `** BUILD SUCCEEDED **`, app at `build/Build/Products/Debug-iphonesimulator/PlayTwo.app`; also green from an empty derived-data dir (TASK-001) |
| R2 | Existing unit tests still pass, count never drops | `xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e' \| tee /tmp/opencode/regression-test.log` then `grep -E "Executed [0-9]+ tests?, with 0 failures" /tmp/opencode/regression-test.log` — count ≥ the high-water mark: **8** after TASK-002 (1 after TASK-001); each later task that adds tests raises it here | TASK-001 | pass 2026-11-16 (TASK-002 attempt 2) — exit 0, `Executed 8 tests, with 0 failures`: `AirPlayTXTRecordTests` 7 + `AppInfoTests` 1. High-water mark raised **6 → 8** by the attempt-2 rework, which added `testFullwidthDigitsProduceNoRecord` and `testFullwidthLettersProduceNoRecord` (attempt 1: 6, verdict `FAIL` on criterion 4 only). Log: `20261116T172410Z-test.log`, repeated at `…/20261116T172452Z-test.log` |
| R3 | `project.yml` still holds the contract: no packages, iOS 15.0, scheme `PlayTwo`, no signing team | static: `grep -c 'packages:' play-two/project.yml` → 0 · `grep -n 'iOS: "15.0"' play-two/project.yml` → found · `grep -A1 '^schemes:' play-two/project.yml` → `PlayTwo:` · `grep -c 'DEVELOPMENT_TEAM' play-two/project.yml` → 0. Mac: `xcodebuild -list -project PlayTwo.xcodeproj && grep -o "IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*;" PlayTwo.xcodeproj/project.pbxproj` → scheme `PlayTwo`, both targets, `= 15.0` | TASK-001 | pass 2026-11-16 (TASK-010) — static + generated project; scheme `PlayTwo`, targets `PlayTwo`/`PlayTwoTests`, `IPHONEOS_DEPLOYMENT_TARGET = 15.0` (×2) |
| R4 | Port 7000 still answers with the fixed 43-byte reply, twice | app foreground on the simulator, resolve it per `qa/TEST-PLAN.md` A6, then `nc -w 5 <host> 7000 \| xxd` twice — expect `RTSP/1.0 200 OK` + `Content-Length: 0` + empty body, connection closed each time | TASK-003 | pending — behaviour lands in TASK-003; Mac bridge green 2026-11-16 |
| R5 | No test silently skipped; the generated project stays out of version control | `grep -rnE 'XCTSkip\|\.skip' play-two/test \|\| echo 'no skips'` → `no skips` · `grep -nE 'xcodeproj\|build/' play-two/.gitignore` → both found | TASK-001 | pass 2026-11-16 (re-verified, also `git check-ignore` and no generated file tracked) |
| R6 | The scaffold test is not vacuous: changing `AppInfo.displayName` makes it fail | on the **Mac copy only**: edit `play-two/src/PlayTwoApp.swift` to a different name, `xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e'` → expect exit 1 and `XCTAssertEqual failed`; then `rsync -a <project> <build-host>:<build-dir>/` (and `xcodegen generate`) to restore — verify the file's sha256 equals the repo again | TASK-001 | pass 2026-11-16 (TASK-010) — mutant `"Mutant"` → exit 1, `XCTAssertEqual failed: ("Mutant") is not equal to ("PlayTwo")`, `Executed 1 test, with 1 failure`; restored by `sync` + `xcodegen generate` (sha256 `55cb0632…a666c5` = repo) and green again. Re-run 2026-11-16 (TASK-002): same mutant result, `AppInfoTests` failed, restored by `sync` + `xcodegen generate`, sha256 `55cb0632…a666c5` = repo; TASK-002's own mutation (features bit 38 cleared at `src/AirPlay/AirPlayTXTRecord.swift:23`) also failed the suite (`Executed 11 tests, with 3 failures`). Re-run again 2026-11-16 (TASK-002 attempt 2, after the validator rework and the build-tool change): mutant `"Mutant"` → exit 1, `XCTAssertEqual failed: ("Mutant") is not equal to ("PlayTwo")`, `Executed 8 tests, with 1 failure`; restored by `sync` + `xcodegen`, sha256 `55cb0632…a666c5` = repo, suite green (`20261116T172452Z-test.log`) |
| R7 | The rename is complete and pinned: no old product name, no prefix, no duplicated display name, generated plists ignored | static: `grep -rn 'AirPlayReceiver' play-two/project.yml play-two/src play-two/test` → no output, exit 1 · `grep -c 'bundleIdPrefix' play-two/project.yml` → 0 · `grep -c 'CFBundleDisplayName' play-two/project.yml` → 0 · `git check-ignore -v play-two/src/Info.plist play-two/test/Info.plist` → both attribute `play-two/.gitignore`, exit 0 | TASK-010 | pass 2026-11-16 (TASK-010) — all four green; built app `CFBundleName = PlayTwo`, `CFBundleIdentifier = com.lorand.playtwo`, no `CFBundleDisplayName`; test bundle `com.lorand.playtwo.tests` |
| R8 | The TASK-002 identity/TXT contract keeps its seven named tests and its constant | `xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e' \| tee /tmp/opencode/r8-test.log` then `grep -c "AirPlayTXTRecordTests .* passed (" /tmp/opencode/r8-test.log` → **7** · `grep -n 'static let features: UInt64 = 0x3C356BD04A7FCA00' play-two/src/AirPlay/AirPlayTXTRecord.swift` → found · `python3 -c 'print(bool(0x3C356BD04A7FCA00 & (1<<38)))'` → `True` | TASK-002 | pass 2026-11-16 (TASK-002 attempt 2) — `testCurrentIsStableAndStoredOnce`, `testIdentityIsReusedAcrossStoreInstances`, `testTXTRecordHasTheRequiredKeysAndValues`, `testTXTRecordRoundTripsThroughNWTXTRecord`, `testInvalidDeviceIDsProduceNoRecord`, `testFullwidthDigitsProduceNoRecord`, `testFullwidthLettersProduceNoRecord` all passed; constant present, bit 38 `True`. The fullwidth tests are load-bearing: restoring the attempt-1 `Character.isHexDigit` validator failed both with `accepted: "０A:…"` / `"ＡA:…"` (`20261116T172318Z-test.log`) |

Rules:

- Add a row the first time a behaviour is verified by a task.
- Never delete a row because it is inconvenient; retire it with a `DEC-###`
  reference and a reason.
- A `FAIL` here is automatically a `FAIL` verdict, even when the task's own
  criteria pass.
- A `BLOCKED` row is a blocker to record in the review, never a pass: the shop is
  closed, not the check green. R1, R2, R3, R5, R6, R7 and R8 are green on
  2026-11-16 (the first four once the Mac bridge was configured; R7 added by
  TASK-010's rename, R8 by TASK-002),
  and must stay green — a regression here is a `FAIL` even when the task's own
  criteria pass.
- R6 is a one-off mutation probe, not a per-task check: run it when the test or
  the display-name contract changes, and always on the Mac copy, never the repo.
- When a task adds tests, raise the R2 high-water mark in the same turn and note
  the new number in that task's review.
