---
id: TASK-024-review
task: TASK-024
feature: FEAT-005
verdict: PASS
date: 2026-11-22
attempt: 1
---

# Review — TASK-024 Route RTSP requests on the AirPlay port

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Live connection on ephemeral port with router installed as connection handler; `OPTIONS * RTSP/1.0\r\nCSeq: 7\r\n\r\n` → response begins with `RTSP/1.0 200 OK\r\n` and contains `CSeq: 7\r\n`. | PASS | `play-two/test/RTSPRouteTests.swift:16-34` `testOptionsRequestGetsRTSP200WithCSeq` starts router on `freePort()` (`:63-86`, `listener.connectionHandler = router.handle` at `:66`), sends the exact request, asserts `text.hasPrefix("RTSP/1.0 200 OK\r\n")` and `text.contains("CSeq: 7\r\n")`. `RTSPRouter.handle` detects protocol by request-line token (`play-two/src/RTSP/RTSPRouter.swift:38-67`, `version == "RTSP/1.0"` at `:59`), parses with `RTSPRequest.parse` (`:78,96`), and responds only for `OPTIONS` via `RTSPResponse.options(for:)` (`:108-121`). Suite: `Test Suite 'RTSPRouteTests' passed` / `Executed 2 tests, with 0 failures` (`/tmp/opencode/task-024-test.log:570-571`, `20261122T165829Z-test.log:570-571`). |
| 2 | Same router/port; `GET /info HTTP/1.1\r\nContent-Length: 0\r\n\r\n` → HTTP 200 with existing HAP info JSON body containing `"category": "speaker"` (R4 preserved). | PASS | `play-two/test/RTSPRouteTests.swift:38-56` `testHTTPInfoRequestStillReachesHAPServer` sends the exact HTTP request and asserts `HTTP/1.1 200` and `"category": "speaker"`. Router HTTP branch uses request-line token `HTTP/1.1` (`RTSPRouter.swift:61-62`), parses with `HAPServer.parse` and routes with `server.route` (`:130-131,147-149,160-162`), preserving HAP semantics. HAPServer unchanged; `/info` body still contains `category` speaker (`play-two/src/HAP/HAPServer.swift:134-137,220-227`). Same passing suite/log as criterion 1. |
| 3 | `RTSPRouteTests` passes: `Test Suite 'RTSPRouteTests' passed` and `Executed 2 tests, with 0 failures`. | PASS | `/tmp/opencode/task-024-test.log:570` `Test Suite 'RTSPRouteTests' passed at 2026-11-22 19:04:34.627.`; `:571` `Executed 2 tests, with 0 failures (0 unexpected) in 0.020 (0.021) seconds`. Mirror `20261122T165829Z-test.log` same lines. |
| 4 | Regression: `HAPServerTests` still passes with 10/10 and `ReceiverListenerTests` with 4/4 in the same full run. | PASS | Same full run `/tmp/opencode/task-024-test.log`: `Test Suite 'HAPServerTests' passed` `:543`, `Executed 10 tests, with 0 failures` `:544`; `Test Suite 'ReceiverListenerTests' passed` `:590`, `Executed 4 tests, with 0 failures` `:591`; bundle `Executed 89 tests, with 0 failures` `:663,665`, `** TEST SUCCEEDED **`. |

## What I ran

I did not re-run the Mac simulator suite myself; I verified the developer's quoted Mac log/mirror and inspected the diff/code on this host.

```sh
# Scope / diff
git status --short -- play-two
git diff --name-only -- play-two | sort
git diff --stat -- play-two
git diff --unified=3 -- play-two/src/Net/ServiceAdvertiser.swift play-two/src/RTSP/RTSPRouter.swift play-two/test/RTSPRouteTests.swift play-two/journal/<role>.md play-two/backlog/BOARD.md play-two/backlog/tasks/TASK-024-route-rtsp-on-airplay-port.md

# Mac test evidence (developer-provided mirror)
ls -la /tmp/opencode/task-024-test.log
grep -nE "Test Suite '(RTSPRouteTests|HAPServerTests|ReceiverListenerTests)' (passed|failed)|Executed [0-9]+ tests?, with 0 failures" /tmp/opencode/task-024-test.log | tail -20
tail -20 /tmp/opencode/task-024-test.log

# Confirm HAPServer unchanged in diff
git diff --name-only -- play-two/src/HAP/HAPServer.swift  # no output
```

Observed log lines:
- `Test Suite 'HAPServerTests' passed at 2026-11-22 19:04:34.593.` / `Executed 10 tests, with 0 failures ...`
- `Test Suite 'RTSPRouteTests' passed at 2026-11-22 19:04:34.627.` / `Executed 2 tests, with 0 failures ...`
- `Test Suite 'ReceiverListenerTests' passed at 2026-11-22 19:04:34.647.` / `Executed 4 tests, with 0 failures ...`
- `Executed 89 tests, with 0 failures (0 unexpected) in 795.370 (795.427) seconds`
- `** TEST SUCCEEDED **`
- `ok — log: /homedir/agent/opencode/apps/20261122T165829Z-test.log`

## Findings

None.

Observations (non-blocking):
- **MINOR (observation)** — `play-two/src/RTSP/RTSPRouter.swift:160-183` replicates HTTP response framing because `HAPServer.sendResponse` is private and `HAPServer.handle` cannot take prefetched bytes. Risk is contained: parsing/routing still go through `HAPServer.parse`/`server.route` (`:130-131,147-149,160-162`), and status phrase/body framing matches `HAPServer.swift:257-267`. No criterion violated.
- Detection/fail-closed behavior is by request-line protocol token, not port and not HTTP-first fallback: `RTSPRouter.swift:38-67` reads until request line, splits 3 tokens, dispatches on `parts[2] == "RTSP/1.0"` / `"HTTP/1.1"`, else cancels; malformed/EOF-before-line/UTF8/part-count errors cancel (`:39-57,63-66,81-84,97-99,134-136,149-151`). No automated test covers a malformed/unknown-protocol request; task only requires 2 tests and notes fail-closed behavior - acceptable for this task, but a future RTSP routing task should pin it.

## Regressions

From `play-two/qa/REGRESSION.md`: R2 high-water confirmed at **89** after TASK-024 (`Executed 89 tests, with 0 failures`, `20261122T165829Z-test.log:663,665`, mirror `/tmp/opencode/task-024-test.log`); updated in this review turn. R4 confirmed: `HAPServerTests` 10/10 and `ReceiverListenerTests` 4/4 in same run. R5 static shape unchanged by inspection (no skips added in new test; gitignore/project contract unaffected by this diff). R1/R3/R6-R15 not re-run here; no code paths they cover were changed beyond ServiceAdvertiser wiring and no regression signal in the 89/0 full bundle.

## Unverifiable on this host

No Swift/iOS simulator/Xcode on this Linux host. I relied on the developer-provided Mac test log and mirror (`/tmp/opencode/task-024-test.log`, `20261122T165829Z-test.log`) and code inspection. This is the expected verification mode per `play-two/docs/STACK.md`.

## Verdict

**Verdict:** PASS

All four acceptance criteria have direct evidence in the Mac test log and matching code paths. The router detects by request-line protocol token, fails closed on unknown/malformed protocol lines by code inspection, routes HTTP/1.1 through `HAPServer.parse`/`route` with HAP response framing preserved, and leaves `HAPServer.swift` unchanged. Full bundle is 89/0 with HAPServerTests 10/10 and ReceiverListenerTests 4/4; R2 high-water updated to 89.

**Next:** BA may record G4 PASS, update board/state, and commit the task (including `qa/REGRESSION.md` and this report) when ready. QA did not edit source, task, board, state, or docs outside `qa/`.
