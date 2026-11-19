# REGRESSION — AirPlay 2 Receiver

Owner: `qa`. Every check that has ever passed stays here and must keep passing.
The tester runs this list for every task, not only at the end.

Run it in about three minutes, from the workspace root. R1, R2, R3 (Mac half) and
R6 are Mac-only. The Mac bridge is configured and `check` is green since
2026-11-16 (macOS 26.6.2, Xcode 26.6, iOS 26.5 SDK, simulator `iPhone 16e`,
`DEC-005`); a `BLOCKED` row now means the bridge or the Mac broke again — record
the exact error line and the `*.log` path. R4 stays pending
until TASK-003 exists.

| ID | Check | Command | Since | Last result |
| --- | --- | --- | --- | --- |
| R1 | The app still builds for the simulator | `rsync -a <project> <build-host>:<build-dir>/ airplay-2-receiver && xcodegen generate && xcodebuild build airplay-2-receiver AirPlayReceiver iphonesimulator` — expect exit 0, `ok — log:`, and the `.app` path | TASK-001 | pass 2026-11-16 (TASK-001 round 2) — exit 0, `** BUILD SUCCEEDED **`, app at `build/Build/Products/Debug-iphonesimulator/AirPlayReceiver.app`; also green from an empty derived-data dir |
| R2 | Existing unit tests still pass, count never drops | `xcodebuild test airplay-2-receiver AirPlayReceiver 'platform=iOS Simulator,name=iPhone 16e' \| tee /tmp/opencode/regression-test.log` then `grep -E "Executed [0-9]+ tests?, with 0 failures" /tmp/opencode/regression-test.log` — count ≥ the high-water mark of "Since" task: 1 / 6 / 10 / 13 / 17 / 21 / 25 / 28 | TASK-001 | pass 2026-11-16 (TASK-001 round 2) — `Executed 1 test, with 0 failures`, exit 0; high-water mark is **1** |
| R3 | `project.yml` still holds the contract: no packages, iOS 15.0, scheme `AirPlayReceiver`, no signing team | static: `grep -c 'packages:' airplay-2-receiver/project.yml` → 0 · `grep -n 'iOS: "15.0"' airplay-2-receiver/project.yml` → found · `grep -A1 '^schemes:' airplay-2-receiver/project.yml` → `AirPlayReceiver:` · `grep -c 'DEVELOPMENT_TEAM' airplay-2-receiver/project.yml` → 0. Mac: `xcodebuild -list -project AirPlayReceiver.xcodeproj && grep -o "IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*;" AirPlayReceiver.xcodeproj/project.pbxproj` → scheme `AirPlayReceiver`, both targets, `= 15.0` | TASK-001 | pass 2026-11-16 (static + generated project) |
| R4 | Port 7000 still answers with the fixed 43-byte reply, twice | app foreground on the simulator, resolve it per `qa/TEST-PLAN.md` A6, then `nc -w 5 <host> 7000 \| xxd` twice — expect `RTSP/1.0 200 OK` + `Content-Length: 0` + empty body, connection closed each time | TASK-003 | pending — behaviour lands in TASK-003; Mac bridge green 2026-11-16 |
| R5 | No test silently skipped; the generated project stays out of version control | `grep -rnE 'XCTSkip\|\.skip' airplay-2-receiver/test \|\| echo 'no skips'` → `no skips` · `grep -nE 'xcodeproj\|build/' airplay-2-receiver/.gitignore` → both found | TASK-001 | pass 2026-11-16 (re-verified, also `git check-ignore` and no generated file tracked) |
| R6 | The scaffold test is not vacuous: changing `AppInfo.displayName` makes it fail | on the **Mac copy only**: edit `airplay-2-receiver/src/AirPlayReceiverApp.swift` to a different name, `xcodebuild test airplay-2-receiver AirPlayReceiver 'platform=iOS Simulator,name=iPhone 16e'` → expect exit 1 and `XCTAssertEqual failed`; then `rsync -a <project> <build-host>:<build-dir>/ airplay-2-receiver` (and `xcodegen generate`) to restore — verify the file's sha256 equals the repo again | TASK-001 | pass 2026-11-16 — mutated run exit 1 with `Executed 1 test, with 1 failure`, restored by sync (sha256 match) and green again |

Rules:

- Add a row the first time a behaviour is verified by a task.
- Never delete a row because it is inconvenient; retire it with a `DEC-###`
  reference and a reason.
- A `FAIL` here is automatically a `FAIL` verdict, even when the task's own
  criteria pass.
- A `BLOCKED` row is a blocker to record in the review, never a pass: the shop is
  closed, not the check green. R1, R2, R3 and R6 went green on 2026-11-16 when the
  Mac bridge was configured, and must stay green — a regression here is a `FAIL`
  even when the task's own criteria pass.
- R6 is a one-off mutation probe, not a per-task check: run it when the test or
  the display-name contract changes, and always on the Mac copy, never the repo.
- When a task adds tests, raise the R2 high-water mark in the same turn and note
  the new number in that task's review.
