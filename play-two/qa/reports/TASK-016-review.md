# TASK-016 — Serve `GET /info` on port 7000, replacing the fixed reply — PASS

Tester run: 2026-11-22. Host: MacBook Pro 2015, macOS 12.7.6, Xcode 14.2
(14C18), x86_64; destination `platform=iOS Simulator,name=iPhone 14,OS=16.2`.
Attempt 1 (dev report: `play-two/journal/<role>.md` §2026-11-22 — TASK-016 attempt 1).
Evidence log: `/tmp/opencode/task-016-test.log` (mirror
`20261122T065939Z-test.log`).

The run was not re-executed on this host: it is Linux with no Swift or Xcode
(`play-two/docs/STACK.md` — "Nothing iOS runs on this host"), and the brief
allows the run to be read from the developer's log when it cannot be re-run.
Every quote below is from `/tmp/opencode/task-016-test.log` or the
source/test files.

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Given `GET /info HTTP/1.1` with `Content-Length: 0`, `HAPServer.parse` returns method GET, path `/info`, body 0 bytes | PASS | Log `/tmp/opencode/task-016-test.log:313` — `Test Case '-[PlayTwoTests.HAPServerTests testParseReturnsMethodPathAndBody]' passed (0.003 seconds).` Asserts `method == "GET"`, `path == "/info"`, `body.count == 0`, `body == Data()` (`play-two/test/HAPServerTests.swift:20-30`). Parser: `String(parts[0]).uppercased()` → `GET` (`play-two/src/HAP/HAPServer.swift:67`), `path = String(parts[1])` (`:68`), `body = data.subdata(in: bodyStart..<(bodyStart + contentLength))` with `contentLength` read from the `Content-Length` header (`:70-85`) — 0 for `Content-Length: 0`. Edge cases: `testParseReturnsNilOnMalformedInput` — empty input, request line without method/path, and a body shorter than `Content-Length` all parse to `nil` (`play-two/test/HAPServerTests.swift:43-50`; log `:305`). |
| 2 | `HAPServer().route(GET /info)` → status 200 and a body containing `"name": "PlayTwo"`, `"category": "speaker"`, `"paired": false` | PASS | Log `/tmp/opencode/task-016-test.log:307` — `Test Case '-[PlayTwoTests.HAPServerTests testRouteInfoReturns200WithNameCategoryAndPaired]' passed (0.002 seconds).` Asserts `response.status == 200` and `body.contains("\"name\": \"PlayTwo\"")`, `contains("\"category\": \"speaker\"")`, `contains("\"paired\": false")` (`play-two/test/HAPServerTests.swift:54-61`). Live wire proof: log `:299` — `Test Case '-[PlayTwoTests.HAPServerTests testLiveInfoExchangeAnswersOverAPort]' passed (0.185 seconds).`; the text received over the real socket contains `HTTP/1.1 200` and the three substrings (`play-two/test/HAPServerTests.swift:134-137`). Mechanism: `HAPServer.infoBody` (`play-two/src/HAP/HAPServer.swift:118-123`) builds the body by string interpolation of `AppInfo.displayName` = `"PlayTwo"` (`play-two/src/PlayTwoApp.swift:9`), `HAPServer.accessoryCategory` = `"speaker"` (`play-two/src/HAP/HAPServer.swift:19`) and `HAPServer.paired` = `false` (`:30`). It is not produced via `JSONSerialization`/`JSONEncoder`, but the emitted bytes are the required JSON; the criteria are containment asserts on the body and are met. |
| 3 | `GET /other`, `POST /info`, `POST /pair-setup` → 404 | PASS | Log `/tmp/opencode/task-016-test.log:309` — `Test Case '-[PlayTwoTests.HAPServerTests testRouteOtherPathReturns404]' passed (0.003 seconds).` (`GET /other` → 404; `play-two/test/HAPServerTests.swift:63-68`). Log `/tmp/opencode/task-016-test.log:311` — `Test Case '-[PlayTwoTests.HAPServerTests testRoutePostPairSetupReturns404]' passed (0.002 seconds).` (`POST /info` and `POST /pair-setup` → 404; `play-two/test/HAPServerTests.swift:70-80`). Routing is real: `HAPServer.route` returns 200 only when `request.method == "GET" && request.path == "/info"`; every other method or path returns `Response(status: 404, body: Data("Not Found".utf8))` (`play-two/src/HAP/HAPServer.swift:110-115`). |
| 4 | `HAPServerTests` passes: `Test Suite 'HAPServerTests' passed` and `Executed 7 tests, with 0 failures` — the seven cases | PASS | Log `/tmp/opencode/task-016-test.log:312-313` — `Test Suite 'HAPServerTests' passed at 2026-11-22 08:59:48.534.` + `Executed 7 tests, with 0 failures (0 unexpected) in 0.200 (0.218) seconds`. All seven cases `passed`: `:299` — `testLiveInfoExchangeAnswersOverAPort` (0.185 s), `:301` — `testParseReadsTheContentLengthBody` (0.003), `:303` — `testParseReturnsMethodPathAndBody` (0.003), `:305` — `testParseReturnsNilOnMalformedInput` (0.003), `:307` — `testRouteInfoReturns200WithNameCategoryAndPaired` (0.002), `:309` — `testRouteOtherPathReturns404` (0.003), `:311` — `testRoutePostPairSetupReturns404` (0.002). Whole-log greps: `grep -cE "with [1-9][0-9]* failure" /tmp/opencode/task-016-test.log` → `0`; `grep -c "Test Case.*failed" /tmp/opencode/task-016-test.log` → `0`. |
| 5 | `ReceiverListenerTests` passes with the new contract: `Executed 4 tests, with 0 failures` — `testDefaultPortIs7000`, `testTwoSequentialConnectionsAreDelegated`, `testStartReportsFailureWhenPortIsAlreadyBound`, `testConnectionIsRefusedWithinOneSecondAfterStop` | PASS | Log `/tmp/opencode/task-016-test.log:332-333` — `Test Suite 'ReceiverListenerTests' passed at 2026-11-22 08:59:48.657.` + `Executed 4 tests, with 0 failures (0 unexpected) in 0.113 (0.121) seconds`. All four cases `passed`: log `:319` — `testDefaultPortIs7000` (0.005 s); `:324` — `testStartReportsFailureWhenPortIsAlreadyBound` (0.016 s); `:331` — `testTwoSequentialConnectionsAreDelegated` (0.034 s); `:317` — `testConnectionIsRefusedWithinOneSecondAfterStop` (0.057 s). `testDefaultPortIs7000` asserts `listener.port.rawValue == 7000` without binding (`play-two/test/ReceiverListenerTests.swift:40-47`). |

## Gaming checks

- **Real JSON body?** The body is a JSON literal built by string interpolation in `HAPServer.infoBody` (`play-two/src/HAP/HAPServer.swift:118-123`) over three constants — `AppInfo.displayName` = `"PlayTwo"` (`play-two/src/PlayTwoApp.swift:9`), `HAPServer.accessoryCategory` = `"speaker"` (`:19`), `HAPServer.paired` = `false` (`:30`). It is not produced via `JSONSerialization`/`JSONEncoder`, but the emitted body contains `"name": "PlayTwo"`, `"category": "speaker"`, `"paired": false` and the live exchange asserts them on the wire (`play-two/test/HAPServerTests.swift:134-137`). Observation, not a finding.
- **Real 404s?** `HAPServer.route` (`play-two/src/HAP/HAPServer.swift:110-115`) returns `Response(status: 200, …)` only for `method == "GET" && path == "/info"`; `GET /other`, `POST /info`, `POST /pair-setup` all return `Response(status: 404, body: Data("Not Found".utf8))` — asserted by the three passing route tests (`play-two/test/HAPServerTests.swift:63-80`).
- **Production chain, not a test-local shortcut?** The app wires `ServiceAdvertiser.start()` → `let server = HAPServer()`; `listener.connectionHandler = server.handle` (`play-two/src/Net/ServiceAdvertiser.swift:121-125`); `ReceiverListener.answer` delegates to `connectionHandler` when set (`play-two/src/Net/ReceiverListener.swift:108-115`); `HAPServer.handle` reads via `Self.parse(received)` and serves via `route` (`play-two/src/HAP/HAPServer.swift:129-168`). The live test drives the same chain on a real listener (`play-two/test/HAPServerTests.swift:82-85`) and asserts the bytes on the wire (`:134-137`). The old fixed reply is gone: `grep -n 'static let response' play-two/src/Net/ReceiverListener.swift` → exit 1 (no match); `grep -rn 'ReceiverListener.response' play-two --include='*.swift'` → exit 1.
- **Free ephemeral port via `listener.port`?** `ReceiverListener(port: try freePort())` (`play-two/test/HAPServerTests.swift:84`); `freePort()` asks the kernel — `ipv4Wildcard(port: 0)` → `bindAndListen` → `boundPort(of:)` via `getsockname` (`:144-151, 189-199`) — and the client connects on `listener.port` (`:103`). `ReceiverListenerTests` uses the same helper through `startListener()` (`play-two/test/ReceiverListenerTests.swift:149-168`). Dev journal: "the port handed to the listener is the real one; no SDK difference to record".
- **The second call / edge inputs?** `testTwoSequentialConnectionsAreDelegated` asserts both sequential connections reach `connectionHandler` — `delegated.value.count == 2` (`play-two/test/ReceiverListenerTests.swift:51-83`); empty/malformed inputs are nil-parsed (`play-two/test/HAPServerTests.swift:43-50`); the short-body path of `parse` (`play-two/src/HAP/HAPServer.swift:80-85`) is exercised by `testParseReadsTheContentLengthBody` and `testParseReturnsNilOnMalformedInput`.

## Scope

`git status --short`: `M play-two/src/Net/ReceiverListener.swift`, `M play-two/src/Net/ServiceAdvertiser.swift`, `M play-two/test/ReceiverListenerTests.swift`, `?? play-two/src/HAP/HAPServer.swift`, `?? play-two/test/HAPServerTests.swift`, `M play-two/backlog/tasks/TASK-016-serve-get-info.md` (status flip `proposed → in-progress`, `attempts: 0 → 1`), `M play-two/journal/<role>.md` (the dev's entry). All five in-brief files are in scope; the task-file and dev-journal changes are the developer's, not this tester's. This turn wrote only `play-two/qa/reports/TASK-016-review.md`, the R2 row update in `play-two/qa/REGRESSION.md`, and the `play-two/journal/<role>.md` entry.

## What I ran

On the developer's Mac run (the log):

- `grep -E "Test Suite 'HAPServerTests' (passed|failed)" /tmp/opencode/task-016-test.log` → `Test Suite 'HAPServerTests' passed at 2026-11-22 08:59:48.534.`
- `grep -A1 "Test Suite 'HAPServerTests' passed" /tmp/opencode/task-016-test.log` → `Executed 7 tests, with 0 failures (0 unexpected) in 0.200 (0.218) seconds`
- `grep -E "Test Suite 'ReceiverListenerTests' (passed|failed)" /tmp/opencode/task-016-test.log` → `Test Suite 'ReceiverListenerTests' passed at 2026-11-22 08:59:48.657.`
- `grep -A1 "Test Suite 'ReceiverListenerTests' passed" /tmp/opencode/task-016-test.log` → `Executed 4 tests, with 0 failures (0 unexpected) in 0.113 (0.121) seconds`
- `grep -E "Test Case '-\[PlayTwoTests\.HAPServerTests .*' passed" /tmp/opencode/task-016-test.log` → the seven `passed` lines `:299`–`:311`.
- `grep -E "Test Case '-\[PlayTwoTests\.ReceiverListenerTests .*' passed" /tmp/opencode/task-016-test.log` → the four `passed` lines `:317`–`:331`.
- `grep -E "Executed .* with [0-9]+ failures" /tmp/opencode/task-016-test.log` → `Test Suite 'PlayTwoTests.xctest' passed at 2026-11-22 09:07:46.845.` + `Executed 62 tests, with 0 failures (0 unexpected) in 478.890 (478.967) seconds`; `Test Suite 'All tests' passed at 2026-11-22 09:07:46.845.` + `Executed 62 tests, with 0 failures (0 unexpected) in 478.890 (478.972) seconds`.
- `grep -cE "with [1-9][0-9]* failure" /tmp/opencode/task-016-test.log` → `0`; `grep -c "Test Case.*failed" /tmp/opencode/task-016-test.log` → `0`.
- `grep -n 'static let response' play-two/src/Net/ReceiverListener.swift` → exit 1 (no match); `grep -rn 'ReceiverListener.response' play-two --include='*.swift'` → exit 1.
- Source/test reads: `play-two/src/HAP/HAPServer.swift` (parse `:59-104`, route `:110-115`, infoBody `:118-123`, handle `:129-151`, sendResponse `:153-168`), `play-two/src/Net/ReceiverListener.swift` (answer `:108-115`), `play-two/src/Net/ServiceAdvertiser.swift` (start `:100-131`), `play-two/test/HAPServerTests.swift`, `play-two/test/ReceiverListenerTests.swift`.

## Findings

None. Observations:

- **R4 row stale, reword deferred (not a finding).** The R4 row in `qa/REGRESSION.md` still pins the increment-1 fixed reply (`static let response = "RTSP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n"`, `play-two/src/Net/ReceiverListener.swift:17`) — that literal is gone and `ReceiverListenerTests` is now 4 tests. The behavior it pinned is intentionally deleted (TASK-016 Goal: "The increment-1 fixed 38-byte reply is gone (`ReceiverListener.response` is deleted; BA note 2026-11-21, R4)"). Dev journal 2026-11-22: "The R4 row in `qa/REGRESSION.md` is retired/reworded by QA/BA at feature close; untouched here (qa-owned, out of scope)." The row needs a reword at `FEAT-003` close — the BA's call then.
- The `infoBody` mechanism is a hand-built JSON literal (criterion 2) — meets the criteria as written.

## Regressions

- **R2 — pass.** `Test Suite 'PlayTwoTests.xctest' passed at 2026-11-22 09:07:46.845.` + `Executed 62 tests, with 0 failures (0 unexpected) in 478.890 (478.967) seconds`; `Test Suite 'All tests' passed at 2026-11-22 09:07:46.845.`; `** TEST SUCCEEDED **` (`/tmp/opencode/task-016-test.log`). High-water raised **56 → 62** — the R2 row in `qa/REGRESSION.md` is updated this turn (TASK-016: +7 `HAPServerTests` tests, `ReceiverListenerTests` 5 → 4).
- Whole-log: `grep -cE "with [1-9][0-9]* failure" /tmp/opencode/task-016-test.log` → `0`; `grep -c "Test Case.*failed" /tmp/opencode/task-016-test.log` → `0`.

## Unverifiable here

None — everything this task needs is quoted from the developer's Mac run log. This host cannot re-run the suite (Linux; no Swift, no Xcode, `play-two/docs/STACK.md`), so the brief's alternative applies: the R2 count is read from the same log the dev used. No device/Apple TV behaviour is claimed by this task.

## Verdict

PASS — all five criteria have runtime evidence above; the regression list passes at the raised high-water mark; nothing important was left unverified (edge inputs parse to nil, the real 404 paths are asserted, the live exchange is on a real socket through the production chain).

```text
TASK-016 Serve `GET /info` on port 7000, replacing the fixed reply — PASS
Criteria: 5/5 verified · Regressions: pass (R2, 62 tests, high-water 62)
Findings: none
Unverifiable here: none
Report: qa/reports/TASK-016-review.md
```
