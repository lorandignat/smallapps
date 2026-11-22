---
id: TASK-018-review
task: TASK-018
feature: FEAT-003
verdict: PASS
date: 2026-11-22
attempt: 1
---

# Review — TASK-018 Complete `POST /pair-setup` (SRP M1–M6)

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Request 1 (`POST /pair-setup`, TLV type 4 = A, 32 bytes) → status 200, TLV type 3 = B (`SRP.nByteCount` bytes), TLV type 6 = salt (≥ 16 bytes), `HAPPairSetup.isStarted` true | PASS | `Test Case '-[PlayTwoTests.HAPServerTests testRoutePostPairSetupStartsTheExchange]' passed (49.682 seconds).` — `/tmp/opencode/task-018-test.log:429`. Route asserts both entries: `play-two/src/HAP/HAPServer.swift:154-164` (`guard let a, a.value.count == 32` → `Response(status: 200, ...)` with `TLV8Entry(type: 3, value: result.B)` and `TLV8Entry(type: 6, value: result.salt)`); assertions `play-two/test/HAPServerTests.swift:126-133` (`XCTAssertEqual(response1?.status, 200)`, type-3 entry `value.count == SRP.nByteCount`, type-6 entry `value.count >= 16`). `isStarted` asserted at `play-two/test/HAPPairSetupTests.swift:51`; set at `play-two/src/HAP/HAPPairSetup.swift:64`. Suite green: `Test Suite 'HAPServerTests' passed at 2026-11-22 13:10:06.608.` — `/tmp/opencode/task-018-test.log:430`; `Executed 9 tests, with 0 failures (0 unexpected) in 49.711 (49.715) seconds` — `:431` |
| 2 | Client proof M4 = `H(A ‖ B ‖ K)` from the response values → `complete(clientM4:)` returns `(M5, M6, K)`: M5 = `H(A ‖ M4 ‖ K)`, M6 = `K[0..<16]`, accessory K byte-identical to client K, `store.paired` true | PASS | `Test Case '-[PlayTwoTests.HAPPairSetupTests testCompleteReturnsProofAndKeyAndMarksPaired]' passed (118.152 seconds).` — `/tmp/opencode/task-018-test.log:390`. Assertions: `play-two/test/HAPPairSetupTests.swift:92` (`XCTAssertEqual(result.M5, SRP.sha512(m5Input))` where `m5Input = A ‖ proof.M4 ‖ result.K`), `:93` (`XCTAssertEqual(result.M6, proof.K[0..<16])`), `:94` (`XCTAssertEqual(result.K, proof.K, "the accessory K must be byte-identical to the client K")` — a full `Data` equality, not containment), `:95` (`XCTAssertTrue(store.paired)`). Implementation: `play-two/src/HAP/HAPPairSetup.swift:75-92` — `SRP.verify` at `:77`, M5 built at `:81-85`, M6 at `:86`, paired flip at `:88-90`. Client-side M4 = `H(A ‖ B ‖ K)`: local helper `clientHandshake(A:aClient:B:salt:code:)` — `play-two/test/HAPPairSetupTests.swift:195-233` (mirror of `SRPTests.clientHandshake`, `play-two/test/SRPTests.swift:217-279`). Companion full-equality of the session key in TASK-014: `XCTAssertEqual(result.K, client.K)` — `play-two/test/SRPTests.swift:310`; server/client K derived from the same S at `play-two/src/HAP/SRP.swift:149` and `SRPTests.swift:263` |
| 3 | Tampered M4 → `complete` nil, `store.paired` false; route answers 400 for it | PASS | `Test Case '-[PlayTwoTests.HAPPairSetupTests testCompleteReturnsNilWhenTheProofIsTampered]' passed (115.248 seconds).` — `/tmp/opencode/task-018-test.log:388`. Tamper: `tampered[0] ^= 0xFF` — `play-two/test/HAPPairSetupTests.swift:125`; `XCTAssertNil(pairSetup.complete(clientM4: tampered))` — `:126`; `XCTAssertFalse(store.paired)` — `:127`. The nil comes from the verification guard: `guard m1Computed == clientM1 else { return nil }` — `play-two/src/HAP/SRP.swift:157-159`, with the recomputed proof `m1Computed = H(A ‖ B ‖ K)` at `:152-156`. Because the genuine-proof test passes through the same guard (criterion 2), the tampered nil is a real verification failure, not a vacuous one. Route half: `XCTAssertEqual(response2?.status, 400, "a non-verifying proof must answer 400")` — `play-two/test/HAPServerTests.swift:148` (request 2 body TLV type 4 = `0x00`×64, `HAPServerTests.swift:136-140`); `XCTAssertFalse(store.paired)` — `:149`; implementation `play-two/src/HAP/HAPServer.swift:141-145`. Passed in the run: `testRoutePostPairSetupStartsTheExchange` — `/tmp/opencode/task-018-test.log:429` |
| 4 | `HAPPairSetupTests` passes: `Executed 4 tests, with 0 failures` — `testStartReturnsTheAccessoryKeyAndTheSalt`, `testCompleteReturnsProofAndKeyAndMarksPaired`, `testCompleteReturnsNilWhenTheProofIsTampered`, `testRestartReusesTheStoredVerifier` | PASS | `Test Suite 'HAPPairSetupTests' passed at 2026-11-22 13:09:16.852.` — `/tmp/opencode/task-018-test.log:395`; `Executed 4 tests, with 0 failures (0 unexpected) in 306.646 (306.647) seconds` — `:396`. Case lines: `testCompleteReturnsNilWhenTheProofIsTampered` `:388`, `testCompleteReturnsProofAndKeyAndMarksPaired` `:390`, `testRestartReusesTheStoredVerifier` `:392`, `testStartReturnsTheAccessoryKeyAndTheSalt` `:394` — all `passed`. `testRestartReusesTheStoredVerifier` also passes: the restart path reuses the stored verifier — `play-two/src/HAP/HAPPairSetup.swift:54-58`; assertion `play-two/test/HAPPairSetupTests.swift:157`. No skips (`grep -rnE 'XCTSkip|\.skip' play-two/test` → no output, per `qa/REGRESSION.md` R5) |
| 5 | `HAPServerTests` passes: `Executed 9 tests, with 0 failures` — the eight from TASK-017 plus `testRoutePostPairSetupStartsTheExchange` | PASS | `Test Suite 'HAPServerTests' passed at 2026-11-22 13:10:06.608.` — `/tmp/opencode/task-018-test.log:430`; `Executed 9 tests, with 0 failures (0 unexpected) in 49.711 (49.715) seconds` — `:431`. Case lines `:412-429` — all `passed`, including `Test Case '-[PlayTwoTests.HAPServerTests testRoutePostPairSetupStartsTheExchange]' passed (49.682 seconds).` — `:429`. The eight TASK-017 cases plus the new one are the nine counted; `play-two/test/HAPServerTests.swift` defines nine `func test` methods (`:40, :54, :63, :74, :83, :90, :109, :154, :170`) |

## What I ran

On this host — the greps the task brief asks for, against the log:

- `grep -E "Test Suite '(HAPPairSetupTests|HAPServerTests|SRPTests)' (passed|failed)" /tmp/opencode/task-018-test.log` →
  - `Test Suite 'HAPPairSetupTests' passed at 2026-11-22 13:09:16.852.` — `:395`
  - `Test Suite 'HAPServerTests' passed at 2026-11-22 13:10:06.608.` — `:430`
  - `Test Suite 'SRPTests' passed at 2026-11-22 13:17:27.117.` — `:493`
  - `Test Suite 'PlayTwoTests.xctest' passed at 2026-11-22 13:17:27.138.` — `:520`
- `grep -E "Executed [0-9]+ tests?, with 0 failures" /tmp/opencode/task-018-test.log` → `Executed 4 tests, with 0 failures` (`:396`), `Executed 9 tests, with 0 failures` (`:431`), `Executed 73 tests, with 0 failures` (`:521`, `:523`), plus the other suites (14 at `:493`, etc.)
- `grep -c "TEST SUCCEEDED" /tmp/opencode/task-018-test.log` → `1`

Code reads (independent of the developer's reasoning): `play-two/src/HAP/HAPPairSetup.swift` (the whole state machine), `play-two/src/HAP/SRP.swift:123-169` (`verify`), `play-two/src/HAP/HAPServer.swift:124-165` (`route`/`pairSetupResponse`), `play-two/test/HAPPairSetupTests.swift`, `play-two/test/HAPServerTests.swift`, `play-two/src/HAP/HAPPairingStore.swift:55-57` (`paired` reads the record), `play-two/src/HAP/TLV8.swift` (encode/decode).

Scope check (`git diff --stat`, `git status --short play-two`): `play-two/src/HAP/HAPServer.swift` (+53, TASK-018 route only — `pairSetup` property, `route` extension, `pairSetupResponse`, the `400` phrase in `sendResponse`), `play-two/src/HAP/HAPPairSetup.swift` (new, +99), `play-two/test/HAPPairSetupTests.swift` (new, +235). Out of scope: `play-two/test/HAPServerTests.swift` (dev's +50, observation in Findings) and `play-two/journal/<role>.md` (dev's journal). No test deleted or skipped.

## Findings

Ordered by severity. One finding, MINOR.

1. **MINOR — observation: `play-two/test/HAPServerTests.swift` is outside the task scope.** The brief says "the dev touched `play-two/test/HAPServerTests.swift` — it is out of the task scope; flag as observation, do not touch source." It stays: `git diff --stat` shows the file at +50 lines; its new test (`testRoutePostPairSetupStartsTheExchange`, `HAPServerTests.swift:109`) passes in the log (`:429`) and its pre-existing `testRoutePostPairSetupReturns404` still passes (`:427`). No change made.

## Regressions

From `qa/REGRESSION.md` (R2 high-water raised 68 → 73, see journal):

- `Test Suite 'PlayTwoTests.xctest' passed at 2026-11-22 13:17:27.138.` — `/tmp/opencode/task-018-test.log:520`
- `Executed 73 tests, with 0 failures (0 unexpected) in 797.116 (797.159) seconds` — `/tmp/opencode/task-018-test.log:521`
- `Executed 73 tests, with 0 failures (0 unexpected) in 797.116 (797.161) seconds` — `/tmp/opencode/task-018-test.log:523` (duplicate summary line)
- `** TEST SUCCEEDED **` — `/tmp/opencode/task-018-test.log:531`

73 ≥ the raised high-water mark; no regression rows red.

## Unverifiable on this host

- **The test-run shell exit code**: not recorded in the log; `** TEST SUCCEEDED **` (`:531`) is the exit evidence used.
- **Route-level request-2 success leg (200 with TLV type 5/7)**: the route's request-2 branch returning M5/M6 is implemented at `play-two/src/HAP/HAPServer.swift:146-152` and is exercised at `complete()` level by criterion 2; the route-level call is only driven with a bad proof (400) in `HAPServerTests.swift:136-149`. The genuine route-level success leg is deferred to TASK-019 per the developer journal ("route-level pair-verify is TASK-019"). Not a finding — the brief's criterion 5 covers the 400 leg, and criterion 2 covers `complete`.
- **Live over-the-socket `POST /pair-setup`**: out of the brief's criteria; `server.route` is called with real constructed `HAPServer.Request` values (`HAPServerTests.swift:114-125`, `:136-147`) — the route method itself, not a static shortcut — and the live-socket path for `/info` is covered by `testLiveInfoExchangeAnswersOverAPort` (`:170`).

## Verdict

`PASS` — 5/5 criteria have evidence above. The gaming checks stand: the accessory K is byte-identical to the client K via full `Data` equality (`play-two/test/HAPPairSetupTests.swift:94`); the tampered-proof case fails because `SRP.verify` returns nil on `m1Computed == clientM1` mismatch (`play-two/src/HAP/SRP.swift:157-159`) and the genuine-proof test passes through the same guard; the route answers 400 for the bad proof (`HAPServerTests.swift:148`) and 200 with the type-3/type-6 entries on the start path (`HAPServer.swift:154-164`, asserted at `HAPServerTests.swift:126-133`). Regression list green at 73/0.
