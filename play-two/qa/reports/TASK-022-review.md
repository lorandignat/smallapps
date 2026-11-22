---
id: TASK-022-review
task: TASK-022
feature: FEAT-005
verdict: PASS
date: 2026-11-22
attempt: 1
---

# Review — TASK-022 Parse an RTSP request line and headers

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Given bytes for `OPTIONS * RTSP/1.0\r\nCSeq: 1\r\n\r\n`, when `RTSPRequest.parse(_:)` runs, then it returns a request with `method == "OPTIONS"`, `target == "*"`, and `cseq == 1`. | PASS | `play-two/test/RTSPRequestTests.swift:6-15` builds the exact bytes and asserts `method == "OPTIONS"`, `target == "*"`, `cseq == 1`. `play-two/src/RTSP/RTSPRequest.swift:50-58,15-18` parses the 3-token request line, requires `RTSP/1.0`, and exposes `cseq` from the `CSeq` header. Mac log `/tmp/opencode/task-022-test.log:450-451` (`20261122T155814Z-test.log` mirror): `Test Case '-[PlayTwoTests.RTSPRequestTests testParsesOptionsRequestLineAndCSeq]' passed (0.001 seconds).` |
| 2 | Given a request with a `Content-Length: N` body, when parsed, then the returned `body` contains exactly those `N` bytes and no trailing bytes. | PASS | `play-two/test/RTSPRequestTests.swift:17-27` sets `Content-Length: 4`, appends 4 body bytes plus 2 trailing bytes (`0x99,0xAA`), and asserts `body == [0x01,0x02,0x03,0x04]` and `count == 4`. `play-two/src/RTSP/RTSPRequest.swift:72-80` reads `Content-Length`, rejects truncated/invalid lengths, and returns `Data(remainingBody.prefix(contentLength))`. Log `/tmp/opencode/task-022-test.log:448-449`: `Test Case '-[PlayTwoTests.RTSPRequestTests testParsesBodyExactlyToContentLength]' passed (0.001 seconds).` |
| 3 | Given malformed input (missing request line, unknown protocol token, or truncated body shorter than `Content-Length`), when parsed, then it returns `nil` (or throws a typed parse error) and does not crash. | PASS | `play-two/test/RTSPRequestTests.swift:29-37` covers missing/empty request line (`"\r\nCSeq: 1\r\n\r\n"`), unknown protocol token (`HTTP/1.1`), and truncated body (`Content-Length: 5` with only 3 bytes) — all `XCTAssertNil`. `play-two/src/RTSP/RTSPRequest.swift:31-34,46-48,56-58,74-79` returns nil for missing separator, empty/missing request line, bad version, invalid/truncated Content-Length. Log `/tmp/opencode/task-022-test.log:452-453`: `Test Case '-[PlayTwoTests.RTSPRequestTests testReturnsNilForMalformedRequests]' passed (0.001 seconds).` No crash; suite completed. |
| 4 | `RTSPRequestTests` passes: `Test Suite 'RTSPRequestTests' passed` and `Executed 3 tests, with 0 failures` — covering the three cases above. | PASS | `/tmp/opencode/task-022-test.log:454-456`: `Test Suite 'RTSPRequestTests' passed at 2026-11-22 18:04:34.898.` and `Executed 3 tests, with 0 failures (0 unexpected) in 0.004 (0.005) seconds`. Full bundle also green: `Test Suite 'PlayTwoTests.xctest' passed at 2026-11-22 18:11:44.748.` / `Executed 84 tests, with 0 failures (0 unexpected) in 801.329 (801.386) seconds` (`20261122T155814Z-test.log:546,549`). |

## What I ran

```sh
# Scope / diff
$ git diff --stat
 play-two/backlog/BOARD.md                          |  4 +-
 .../backlog/tasks/TASK-022-parse-rtsp-request.md   |  2 +-
 play-two/journal/<role>.md                            | 68 ++++++++++++++++++++++
 3 files changed, 71 insertions(+), 3 deletions(-)

$ git status --short
 M play-two/backlog/BOARD.md
 M play-two/backlog/tasks/TASK-022-parse-rtsp-request.md
 M play-two/journal/<role>.md
?? play-two/src/RTSP/
?? play-two/test/RTSPRequestTests.swift

# Evidence from developer-run Mac test log (reviewed, not re-run; log present and consistent)
$ grep -n "Test Case.*RTSPRequestTests" /tmp/opencode/task-022-test.log | head -10
448:Test Case '-[PlayTwoTests.RTSPRequestTests testParsesBodyExactlyToContentLength]' started.
449:Test Case '-[PlayTwoTests.RTSPRequestTests testParsesBodyExactlyToContentLength]' passed (0.001 seconds).
450:Test Case '-[PlayTwoTests.RTSPRequestTests testParsesOptionsRequestLineAndCSeq]' started.
451:Test Case '-[PlayTwoTests.RTSPRequestTests testParsesOptionsRequestLineAndCSeq]' passed (0.001 seconds).
452:Test Case '-[PlayTwoTests.RTSPRequestTests testReturnsNilForMalformedRequests]' started.
453:Test Case '-[PlayTwoTests.RTSPRequestTests testReturnsNilForMalformedRequests]' passed (0.001 seconds).

$ grep -E "Test Suite 'RTSPRequestTests' passed|Executed 3 tests, with 0 failures|Test Suite 'PlayTwoTests.xctest' passed|Executed 84 tests, with 0 failures" /tmp/opencode/task-022-test.log | tail -5
Test Suite 'RTSPRequestTests' passed at 2026-11-22 18:04:34.898.
	 Executed 3 tests, with 0 failures (0 unexpected) in 0.004 (0.005) seconds
Test Suite 'PlayTwoTests.xctest' passed at 2026-11-22 18:11:44.748.
	 Executed 84 tests, with 0 failures (0 unexpected) in 801.329 (801.383) seconds
	 Executed 84 tests, with 0 failures (0 unexpected) in 801.329 (801.386) seconds

# Regression spot checks (same log)
$ grep -B1 -A2 "Test Suite 'HAPServerTests' passed" /tmp/opencode/task-022-test.log | head -3
Test Case '-[PlayTwoTests.HAPServerTests testRoutePostPairVerifyReturnsTheAccessoryKey]' passed (0.007 seconds).
Test Suite 'HAPServerTests' passed at 2026-11-22 18:04:34.892.
	 Executed 10 tests, with 0 failures (0 unexpected) in 49.027 (49.031) seconds

$ grep -B1 -A2 "Test Suite 'ReceiverListenerTests' passed" /tmp/opencode/task-022-test.log | head -3
Test Case '-[PlayTwoTests.ReceiverListenerTests testTwoSequentialConnectionsAreDelegated]' passed (0.010 seconds).
Test Suite 'ReceiverListenerTests' passed at 2026-11-22 18:04:34.923.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.022 (0.024) seconds

# R5 no skips
$ grep -rnE 'XCTSkip|\.skip' play-two/test || echo 'no skips'
no skips

# Log mirror present
$ ls -la /tmp/opencode/task-022-test.log 20261122T155814Z-test.log
-rw-r--r-- 1 agent agent 291690 Nov 22 16:11 20261122T155814Z-test.log
-rw-r--r-- 1 agent users 291664 Nov 22 16:11 /tmp/opencode/task-022-test.log
```

## Findings

1. **MINOR** — `play-two/backlog/BOARD.md`, `play-two/backlog/tasks/TASK-022-parse-rtsp-request.md` — tracked workflow files moved to `in-review` in the same worktree, outside TASK-022's declared file scope (`src/RTSP/RTSPRequest.swift`, `test/RTSPRequestTests.swift`; `journal/<role>.md` allowed as evidence). Behaviour is correct and status change is expected for review, but dev-owned task changes should be limited to declared scope; BA/PM own board/task state. No code impact; not a criterion failure.

## Regressions

From `play-two/qa/REGRESSION.md`: R2 passes with high-water mark raised **81 → 84** — `Executed 84 tests, with 0 failures`, `Test Suite 'PlayTwoTests.xctest' passed` (`20261122T155814Z-test.log:546,549`, mirror `/tmp/opencode/task-022-test.log`). R4 spot check green in same bundle: `HAPServerTests` 10/0 and `ReceiverListenerTests` 4/0. R5 no skips (`grep -rnE 'XCTSkip|\.skip' play-two/test` → `no skips`). R1/R3/R6 not re-run by QA in this turn; R1 is supported by the successful Mac test bundle and prior green state, R3 static contract unchanged by this diff. No regression failures observed.

## Unverifiable on this host

Mac execution cannot be independently performed on this Linux host; I relied on the developer-cited Mac log at `/tmp/opencode/task-022-test.log` and mirror `20261122T155814Z-test.log`, whose contents are internally consistent (RTSPRequestTests 3/0, full bundle 84/0, TEST SUCCEEDED). Not a blocker because log evidence is present and quoted.

## Verdict

**Verdict:** PASS

All four acceptance criteria have direct code and Mac test-log evidence; RTSPRequestTests is 3/0 and the full bundle is 84/0 with no skips. The only finding is a MINOR scope/process note for workflow file status changes. Next: BA may record G4 PASS, commit `play-two/TASK-022: parse an RTSP request line and headers` including the in-scope files and QA-owned regression/report updates as appropriate, and move to TASK-023.
