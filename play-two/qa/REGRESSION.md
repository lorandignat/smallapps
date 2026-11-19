# REGRESSION — PlayTwo

Owner: `qa`. Every check that has ever passed stays here and must keep passing.
The tester runs this list for every task, not only at the end.

Run it in about three minutes, from the workspace root. R1, R2, R3 (Mac half) and
R6 are Mac-only. The Mac bridge is configured and `check` is green since
2026-11-16 (macOS 26.6.2, Xcode 26.6, iOS 26.5 SDK, simulator `iPhone 16e`,
`DEC-005`); a `BLOCKED` row now means the bridge or the Mac broke again — record
the exact error line and the `*.log` path. R4 covers the
listener's reply and failure paths on a free port since TASK-003; its app-level
port-7000 half waits for TASK-004 (`DEC-011`).

| ID | Check | Command | Since | Last result |
| --- | --- | --- | --- | --- |
| R1 | The app still builds for the simulator | `rsync -a <project> <build-host>:<build-dir>/ && xcodegen generate && xcodebuild build -scheme PlayTwo -sdk iphonesimulator` — expect exit 0, `** BUILD SUCCEEDED **`, and the `.app` path | TASK-001 | pass 2026-11-16 (TASK-010) — exit 0, `** BUILD SUCCEEDED **`, app at `build/Build/Products/Debug-iphonesimulator/PlayTwo.app`; also green from an empty derived-data dir (TASK-001) |
| R2 | Existing unit tests still pass, count never drops | `xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e' \| tee /tmp/opencode/regression-test.log` then `grep -E "Executed [0-9]+ tests?, with 0 failures" /tmp/opencode/regression-test.log` — count ≥ the high-water mark: **21** after TASK-005 (17 after TASK-004, 13 after TASK-003, 8 after TASK-002, 1 after TASK-001); each later task that adds tests raises it here | TASK-001 | pass 2026-11-19 (TASK-005 attempt 1) — exit 0, `Executed 21 tests, with 0 failures`: `ReceiverListenerTests` 5 + `AirPlayTXTRecordTests` 7 + `AppInfoTests` 1 + `ServiceAdvertiserTests` 4 + `ReceiverStatusTests` 4; log `20261119T183240Z-test.log`. High-water mark raised **17 → 21** by TASK-005's four status tests. |
| R3 | `project.yml` still holds the contract: no packages, iOS 15.0, scheme `PlayTwo`, no signing team | static: `grep -c 'packages:' play-two/project.yml` → 0 · `grep -n 'iOS: "15.0"' play-two/project.yml` → found · `grep -A1 '^schemes:' play-two/project.yml` → `PlayTwo:` · `grep -c 'DEVELOPMENT_TEAM' play-two/project.yml` → 0. Mac: `xcodebuild -list -project PlayTwo.xcodeproj && grep -o "IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*;" PlayTwo.xcodeproj/project.pbxproj` → scheme `PlayTwo`, both targets, `= 15.0` | TASK-001 | pass 2026-11-16 (TASK-010) — static + generated project; scheme `PlayTwo`, targets `PlayTwo`/`PlayTwoTests`, `IPHONEOS_DEPLOYMENT_TARGET = 15.0` (×2) |
| R4 | The listener still answers with the fixed 38-byte reply, answers a second connection, reports a taken port and refuses after `stop()` — all on a free port | unit: `xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e' \| tee /tmp/opencode/r4-test.log`, then `grep -E "Test Suite 'ReceiverListenerTests' passed" /tmp/opencode/r4-test.log` and `grep -c "ReceiverListenerTests .* passed (" /tmp/opencode/r4-test.log` → **5** (reply + `isComplete`, two sequential connections, `.failed` with `EADDRINUSE`, refusal within 1 s, default port 7000) · literal pinned independently of the test: `grep -n 'static let response = "RTSP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n"' play-two/src/Net/ReceiverListener.swift` → line 17 | TASK-003 | pass 2026-11-18 (TASK-003 attempt 3) — `ReceiverListenerTests` 5/5, whole run 13/13 (`…/20261118T161156Z-test.log`); received bytes captured at runtime as `"RTSP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n"`, 38 bytes, `isComplete: true` (probe, `…/20261118T160856Z-test.log`). App-level port 7000 is the deferred half below |
| R5 | No test silently skipped; the generated project stays out of version control | `grep -rnE 'XCTSkip\|\.skip' play-two/test \|\| echo 'no skips'` → `no skips` · `grep -nE 'xcodeproj\|build/' play-two/.gitignore` → both found | TASK-001 | pass 2026-11-16 (re-verified, also `git check-ignore` and no generated file tracked) |
| R6 | The scaffold test is not vacuous: changing `AppInfo.displayName` makes it fail | on the **Mac copy only**: edit `play-two/src/PlayTwoApp.swift` to a different name, `xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e'` → expect exit 1 and `XCTAssertEqual failed`; then `rsync -a <project> <build-host>:<build-dir>/` (and `xcodegen generate`) to restore — verify the file's sha256 equals the repo again | TASK-001 | pass 2026-11-16 (TASK-010) — mutant `"Mutant"` → exit 1, `XCTAssertEqual failed: ("Mutant") is not equal to ("PlayTwo")`, `Executed 1 test, with 1 failure`; restored by `sync` + `xcodegen generate` (sha256 `55cb0632…a666c5` = repo) and green again. Re-run 2026-11-16 (TASK-002): same mutant result, `AppInfoTests` failed, restored by `sync` + `xcodegen generate`, sha256 `55cb0632…a666c5` = repo; TASK-002's own mutation (features bit 38 cleared at `src/AirPlay/AirPlayTXTRecord.swift:23`) also failed the suite (`Executed 11 tests, with 3 failures`). Re-run again 2026-11-16 (TASK-002 attempt 2, after the validator rework and the build-tool change): mutant `"Mutant"` → exit 1, `XCTAssertEqual failed: ("Mutant") is not equal to ("PlayTwo")`, `Executed 8 tests, with 1 failure`; restored by `sync` + `xcodegen`, sha256 `55cb0632…a666c5` = repo, suite green (`20261116T172452Z-test.log`) |
| R7 | The rename is complete and pinned: no old product name, no prefix, no duplicated display name, generated plists ignored | static: `grep -rn 'AirPlayReceiver' play-two/project.yml play-two/src play-two/test` → no output, exit 1 · `grep -c 'bundleIdPrefix' play-two/project.yml` → 0 · `grep -c 'CFBundleDisplayName' play-two/project.yml` → 0 · `git check-ignore -v play-two/src/Info.plist play-two/test/Info.plist` → both attribute `play-two/.gitignore`, exit 0 | TASK-010 | pass 2026-11-16 (TASK-010) — all four green; built app `CFBundleName = PlayTwo`, `CFBundleIdentifier = com.lorand.playtwo`, no `CFBundleDisplayName`; test bundle `com.lorand.playtwo.tests` |
| R8 | The TASK-002 identity/TXT contract keeps its seven named tests and its constant | `xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e' \| tee /tmp/opencode/r8-test.log` then `grep -c "AirPlayTXTRecordTests .* passed (" /tmp/opencode/r8-test.log` → **7** · `grep -n 'static let features: UInt64 = 0x3C356BD04A7FCA00' play-two/src/AirPlay/AirPlayTXTRecord.swift` → found · `python3 -c 'print(bool(0x3C356BD04A7FCA00 & (1<<38)))'` → `True` | TASK-002 | pass 2026-11-18 (TASK-003, re-run in the 13-test suite) — `testCurrentIsStableAndStoredOnce`, `testIdentityIsReusedAcrossStoreInstances`, `testTXTRecordHasTheRequiredKeysAndValues`, `testTXTRecordRoundTripsThroughNWTXTRecord`, `testInvalidDeviceIDsProduceNoRecord`, `testFullwidthDigitsProduceNoRecord`, `testFullwidthLettersProduceNoRecord` all passed; constant at line 23, bit 38 `True`. The fullwidth tests are load-bearing: restoring the attempt-1 `Character.isHexDigit` validator failed both with `accepted: "０A:…"` / `"ＡA:…"` (`20261116T172318Z-test.log`) |
| R9 | Receiver status text maps each state to its exact string and uses the advertised name | `xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e' \| tee /tmp/opencode/r9-test.log` then `grep -c "ReceiverStatusTests .* passed (" /tmp/opencode/r9-test.log` → **4** · static: `grep -n 'status.statusText(name: AppInfo.displayName)' play-two/src/ContentView.swift` → found; `grep -n 'Advertising as \\\\(name)' play-two/src/AppState.swift` → found; `grep -n 'Error: \\\\(message)' play-two/src/AppState.swift` → found | TASK-005 | pass 2026-11-19 (TASK-005 attempt 1) — `testIdle`, `testAdvertising`, `testFailed`, `testStopped` all passed; mutation probe changing `AppInfo.displayName` to `Mutant` failed `testAdvertising` (`"Advertising as Mutant" != "Advertising as PlayTwo"`), proving the mapping reads the name rather than hard-coding it; restored by sync + xcodegen (sha256 `df64fd2d…5af5add` = repo). Log `20261119T183240Z-test.log`. |

**R4's app-level half — deferred to TASK-004, `DEC-011`.** The unit suite binds
a free ephemeral port: the same code path, but not the AirPlay port. Once
TASK-004 constructs `ReceiverListener()` and publishes the service, run
`qa/TEST-PLAN.md` A7 — `nc -w 5 <host> 7000 | xxd` twice against the host A6
resolved — and record it in TASK-004's review and at feature close. Nothing in
the unit suite binds 7000, so the Mac's ControlCenter holding it
(`lsof -nP -iTCP:7000 -sTCP:LISTEN`) is not a blocker; a test that tried would
fail with `bind … [48: Address already in use]` instead of passing.

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
