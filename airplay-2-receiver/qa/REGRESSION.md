# REGRESSION — AirPlay 2 Receiver

Owner: `qa`. Every check that has ever passed stays here and must keep passing.
The tester runs this list for every task, not only at the end.

Run it in about two minutes, from the workspace root. R1, R2 and R4 are Mac-only:
while `xcodebuild -version` cannot reach the Mac (`QQ-005`, local configuration
missing), record them `BLOCKED` with the error line and run R3 and R5, which work
on this host.

| ID | Check | Command | Since | Last result |
| --- | --- | --- | --- | --- |
| R1 | The app still builds for the simulator | `rsync -a <project> <build-host>:<build-dir>/ airplay-2-receiver && xcodegen generate && xcodebuild build airplay-2-receiver AirPlayReceiver iphonesimulator` — expect exit 0, `ok — log:`, and the `.app` path | TASK-001 | pending — no task verified yet |
| R2 | Existing unit tests still pass, count never drops | `xcodebuild test airplay-2-receiver AirPlayReceiver 'platform=iOS Simulator,name=iPhone 16' \| tee /tmp/opencode/regression-test.log` then `grep -E "Executed [0-9]+ tests?, with 0 failures" /tmp/opencode/regression-test.log` — count ≥ the high-water mark of "Since" task: 1 / 6 / 10 / 13 / 17 / 21 / 25 / 28 | TASK-001 | pending |
| R3 | `project.yml` still holds the contract: no packages, iOS 15.0, scheme `AirPlayReceiver`, no signing team | `grep -c 'packages:' airplay-2-receiver/project.yml` → 0 · `grep -n 'iOS: "15.0"' airplay-2-receiver/project.yml` → found · `grep -n 'name: AirPlayReceiver' airplay-2-receiver/project.yml` → found · `grep -c 'DEVELOPMENT_TEAM' airplay-2-receiver/project.yml` → 0 | TASK-001 | pending — project.yml does not exist yet |
| R4 | Port 7000 still answers with the fixed 43-byte reply, twice | app foreground on the simulator, resolve it per `qa/TEST-PLAN.md` A6, then `nc -w 5 <host> 7000 \| xxd` twice — expect `RTSP/1.0 200 OK` + `Content-Length: 0` + empty body, connection closed each time | TASK-003 | pending — `BLOCKED` until QQ-005 |
| R5 | No test silently skipped; the generated project stays out of version control | `grep -rnE 'XCTSkip\|\.skip' airplay-2-receiver/test \|\| echo 'no skips'` → `no skips` · `grep -nE 'xcodeproj\|build/' airplay-2-receiver/.gitignore` → both found | TASK-001 | pending |

Rules:

- Add a row the first time a behaviour is verified by a task.
- Never delete a row because it is inconvenient; retire it with a `DEC-###`
  reference and a reason.
- A `FAIL` here is automatically a `FAIL` verdict, even when the task's own
  criteria pass.
- A `BLOCKED` row is a blocker to record in the review, never a pass: the shop is
  closed, not the check green. R1, R2 and R4 cannot go green until the Mac is
  configured (`QQ-005`).
- When a task adds tests, raise the R2 high-water mark in the same turn and note
  the new number in that task's review.
