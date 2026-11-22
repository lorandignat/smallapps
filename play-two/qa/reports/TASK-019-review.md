---
id: TASK-019-review
task: TASK-019
feature: FEAT-003
verdict: PASS
date: 2026-11-22
attempt: 1
---

# Review — TASK-019 Establish an encrypted session with `POST /pair-verify`

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Given a `POST /pair-verify` request with TLV type 1 = A_e, when routed, then the response status is 200, the TLV contains the accessory's ephemeral public key B_e (type 2, 32 bytes), and `HAPServer.pairVerifySession` is set. | PASS | Route dispatch: `play-two/src/HAP/HAPServer.swift:141-143` → `pairVerifyResponse`; request-1 branch `:207-217` — guard on TLV type 1, `Session(clientA:)` assigned to `pairVerifySession` (`:210-211`), answer 200 with `TLV8Entry(type: 2, value: session.b)` (`:212-217`); `b` is the 32-byte accessory ephemeral public key (`play-two/src/HAP/HAPPairVerify.swift:54-59`). Run: `Test Suite 'HAPServerTests' passed at 2026-11-22 14:20:24.670.` + `Executed 10 tests, with 0 failures (0 unexpected) in 50.669 (50.673) seconds` (`/tmp/opencode/task-019-test.log:310-311`); `Test Case '-[PlayTwoTests.HAPServerTests testRoutePostPairVerifyReturnsTheAccessoryKey]' passed (0.006 seconds).` (`:309`); assertions `play-two/test/HAPServerTests.swift:172-180`: `response.status == 200`, `bE.count == 32`, `XCTAssertNotNil(server.pairVerifySession)`, `XCTAssertEqual(bE, server.pairVerifySession?.b)`. |
| 2 | Given request 2 with TLV type 4 = T = `H(A_e ‖ B_e ‖ accessoryIdentityPublicKey ‖ pairingSalt)` (the client computes this from the response — `Session.proof` is the contract), when routed, then 200 + TLV type 3 = the server proof `H(A_e ‖ B_e ‖ accessoryIdentityPublicKey ‖ T)` and `Session.key != nil` (armed). | PASS | Request-2 branch `play-two/src/HAP/HAPServer.swift:188-205`: `session.verify(clientT:accessoryPublicKey:AccessoryIdentity.shared.publicKey, salt:pairingStore.record?.salt)` → 200 + `TLV8Entry(type: 3, value: proof)` (`:199-204`). Byte-compare: implementation `play-two/src/HAP/HAPPairVerify.swift:65-80` — `expected = a ‖ b ‖ accessoryPublicKey ‖ salt`, guard `SRP.sha512(expected) == clientT` (`:66-71`); on match `proofInput = a ‖ b ‖ accessoryPublicKey ‖ clientT`, `proof = SRP.sha512(proofInput)` (`:72-77`); `SRP.sha512` is CryptoKit `SHA512.hash(data:)` (`play-two/src/HAP/SRP.swift:236-240`). The test recomputes the digest and byte-compares: `play-two/test/HAPPairVerifyTests.swift:69-79` — `expectedProof.append(clientA)`, `append(bE)`, `append(AccessoryIdentity.shared.publicKey)`, `append(clientT)`; `XCTAssertEqual(serverProof, SRP.sha512(expectedProof), "the server proof must be H(A_e ‖ B_e ‖ accessoryIdentityPublicKey ‖ T)")`; plus `XCTAssertEqual(session.proof, serverProof)` (`:62-66`) and `XCTAssertNotNil(session.key)` / `XCTAssertEqual(session.key, Data(clientT.prefix(32)))` (`:67-68`). Run: `Test Suite 'HAPPairVerifyTests' passed at 2026-11-22 14:19:33.960.` + `Executed 4 tests, with 0 failures (0 unexpected) in 0.098 (0.100) seconds` (`/tmp/opencode/task-019-test.log:273-274`); `Test Case '-[PlayTwoTests.HAPPairVerifyTests testRequestOneCarriesTheAccessoryKeyAndRequestTwoVerifies]' passed (0.008 seconds).` (`:266`). |
| 3 | Given a tampered T, when routed, then the response status is 400. | PASS | `play-two/src/HAP/HAPServer.swift:190-198` — the request-2 guard chain returns `Response(status: 400, ...)` when `session.verify` returns nil; `play-two/src/HAP/HAPPairVerify.swift:71` — `guard SRP.sha512(expected) == clientT else { return nil }` returns **before** `proof`/`key` are assigned (`:77-78`), so the mismatch path arms nothing. Test `play-two/test/HAPPairVerifyTests.swift:86-101` — flips one bit of `clientT` (`clientT[0] ^= 0x01`), asserts `response.status == 400`, `XCTAssertNil(session.key, "a tampered proof must arm nothing")`, `XCTAssertTrue(session.proof.isEmpty, "a tampered proof must set no server proof")`. Run: `Test Case '-[PlayTwoTests.HAPPairVerifyTests testTamperedProofVerifiesNothing]' passed (0.037 seconds).` (`/tmp/opencode/task-019-test.log:270`). |
| 4 | `HAPPairVerifyTests` passes: `Executed 4 tests, with 0 failures` — the four named cases. | PASS | Suite: `Test Suite 'HAPPairVerifyTests' passed at 2026-11-22 14:19:33.960.` + `Executed 4 tests, with 0 failures (0 unexpected) in 0.098 (0.100) seconds` (`/tmp/opencode/task-019-test.log:273-274`). Cases (all passed): `testRequestOneCarriesTheAccessoryKeyAndRequestTwoVerifies` (`:266`), `testTamperedProofVerifiesNothing` (`:270`), `testTheSealedSessionRoundTrips` (`:272`), `testSealFailsBeforeVerify` (`:268`). `testTheSealedSessionRoundTrips` runs the real `session.seal`/`session.open` over the armed key and asserts the sealed payload is not the plaintext and `open` recovers it (`play-two/test/HAPPairVerifyTests.swift:107-124`). `testSealFailsBeforeVerify` asserts `XCTAssertNil(session.key)` and `XCTAssertThrowsError(try session.seal/open(...))` expecting `HAPPairVerifyError.keyNotArmed` (`:130-141`; implementation `play-two/src/HAP/HAPPairVerify.swift:85-98`). `grep -c "Test Case '.*' failed" /tmp/opencode/task-019-test.log` → `0`. |
| 5 | `HAPServerTests` passes: `Executed 10 tests, with 0 failures` — the nine from TASK-018 plus `testRoutePostPairVerifyReturnsTheAccessoryKey`. | PASS | Suite: `Test Suite 'HAPServerTests' passed at 2026-11-22 14:20:24.670.` + `Executed 10 tests, with 0 failures (0 unexpected) in 50.669 (50.673) seconds` (`/tmp/opencode/task-019-test.log:310-311`); `grep -c "Test Case '.*' failed" /tmp/opencode/task-019-test.log` → `0`. The ten: the nine from TASK-018 (`testParseReturnsMethodPathAndBody`, `testParseReadsTheContentLengthBody`, `testParseReturnsNilOnMalformedInput`, `testRouteInfoReturns200WithNameCategoryAndPaired`, `testRouteOtherPathReturns404`, `testRoutePostPairSetupReturns404`, `testRoutePostPairSetupStartsTheExchange`, `testInfoReportsThePairedStateFromTheStore`, `testLiveInfoExchangeAnswersOverAPort` — `play-two/test/HAPServerTests.swift:40-257`) plus `testRoutePostPairVerifyReturnsTheAccessoryKey` (`:158-181`): builds `HAPServer(pairingStore:)` with a saved salt record, routes a real `HAPServer.Request(method: "POST", path: "/pair-verify", body: TLV8.encode([TLV8Entry(type: 1, value: Data(repeating: 0x22, count: 32))]))` through `server.route` (`:171`) and asserts 200, a type-2 value of count 32, `server.pairVerifySession != nil`, and `bE == server.pairVerifySession?.b`. Run: `Test Case '-[PlayTwoTests.HAPServerTests testRoutePostPairVerifyReturnsTheAccessoryKey]' passed (0.006 seconds).` (`:309`). |

## What I ran

```sh
xcodebuild -version                                        # exit 0 — macOS 12.7.6, Xcode 14.2 (14C18), x86_64
rsync -a <project> <build-host>:<build-dir>/                                # exit 0
xcodegen generate  # exit 0 — "Created project at …/play-two/PlayTwo.xcodeproj"
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.2' | tee /tmp/opencode/task-019-test.log   # exit 0
```

Key log lines (`/tmp/opencode/task-019-test.log`):

```
Test Suite 'HAPPairVerifyTests' passed at 2026-11-22 14:19:33.960.
	 Executed 4 tests, with 0 failures (0 unexpected) in 0.098 (0.100) seconds
Test Suite 'HAPServerTests' passed at 2026-11-22 14:20:24.670.
	 Executed 10 tests, with 0 failures (0 unexpected) in 50.669 (50.673) seconds
Test Suite 'PlayTwoTests.xctest' passed at 2026-11-22 14:27:43.979.
	 Executed 78 tests, with 0 failures (0 unexpected) in 802.477 (802.529) seconds
Test Suite 'All tests' passed at 2026-11-22 14:27:43.980.
	 Executed 78 tests, with 0 failures (0 unexpected) in 802.477 (802.532) seconds
** TEST SUCCEEDED **
```

Per-case (`/tmp/opencode/task-019-test.log`):

```
Test Case '-[PlayTwoTests.HAPPairVerifyTests testRequestOneCarriesTheAccessoryKeyAndRequestTwoVerifies]' passed (0.008 seconds).
Test Case '-[PlayTwoTests.HAPPairVerifyTests testTamperedProofVerifiesNothing]' passed (0.037 seconds).
Test Case '-[PlayTwoTests.HAPPairVerifyTests testTheSealedSessionRoundTrips]' passed (0.047 seconds).
Test Case '-[PlayTwoTests.HAPPairVerifyTests testSealFailsBeforeVerify]' passed (0.007 seconds).
Test Case '-[PlayTwoTests.HAPServerTests testRoutePostPairVerifyReturnsTheAccessoryKey]' passed (0.006 seconds).
```

Additional greps: `grep -c "Test Case '.*' failed" /tmp/opencode/task-019-test.log` → `0`; `grep -cE "^Test Suite '[A-Za-z]+Tests' failed" /tmp/opencode/task-019-test.log` → `0`.

## Findings

None — all five criteria pass, with byte-level proof checks and tests that route through the real `HAPServer.route`.

## Regressions

From `qa/REGRESSION.md`:

- R2 — pass. `Test Suite 'PlayTwoTests.xctest' passed at 2026-11-22 14:27:43.979.` + `Executed 78 tests, with 0 failures (0 unexpected) in 802.477 (802.529) seconds` (`/tmp/opencode/task-019-test.log:400-401`). **R2 high-water actual: 78.** The R2 row was raised to `count ≥ the high-water mark: **78** after TASK-019` (history now notes `TASK-018 raised **68 → 73**`; this task raised it to 78: +4 `HAPPairVerifyTests` — new suite — and +1 `HAPServerTests.testRoutePostPairVerifyReturnsTheAccessoryKey`).
- All named suites green; `grep -cE "^Test Suite '[A-Za-z]+Tests' passed" /tmp/opencode/task-019-test.log` → `14` (`TLV8Tests` also passed — the regex's `[A-Za-z]+` stops at the digit in `8`), plus the two bundle lines `Test Suite 'PlayTwoTests.xctest' passed` and `Test Suite 'All tests' passed` — 17 passed suite lines, 0 failed.
- R15 added for the new pair-verify behaviours.

## Unverifiable on this host

- The feature-close observation S2a — the task's note: the wire shape is a documented assumption ("no Home-app reference exists on this host; the shape is exercised by `HAPPairVerifyTests` and by the feature-close observation S2a"). There is no live-socket pair-verify test; the only live-socket test is `testLiveInfoExchangeAnswersOverAPort` (`GET /info`).
- The live HTTP wire framing for `POST /pair-verify` (status line and headers as they would go over TCP): the route returns `HAPServer.Response(status: 200/400, body: …)`; `HAPServer.sendResponse` (`play-two/src/HAP/HAPServer.swift:257-272`) phrases it `HTTP/1.1 200 OK` / `HTTP/1.1 400 Bad Request` — no test asserts it.
- Device behaviour: not in scope for this task's criteria (protocol/unit level).

## Verdict

`PASS` — every criterion has byte-level evidence (the test recomputes `SRP.sha512` over `clientA ‖ bE ‖ AccessoryIdentity.shared.publicKey ‖ clientT` and byte-compares to the server proof; the tampered path returns 400 before `key`/`proof` are set; seal/open throw `keyNotArmed` before request 2 arms the key), the tests exercise the real `HAPServer.route`, and the full suite is green: `Executed 78 tests, with 0 failures`, `** TEST SUCCEEDED **` (`/tmp/opencode/task-019-test.log`).

**Next:** the BA may close TASK-019 after reading the diff (G4); the task DoD's outstanding commit item (`play-two/TASK-019: establish an encrypted session with POST /pair-verify`) is noted for the BA — not committed per brief.
