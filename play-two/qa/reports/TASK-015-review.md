# TASK-015 — Ed25519 accessory identity key with Keychain persistence — PASS

Tester run: 2026-11-22. Host: MacBook Pro 2015, macOS 12.7.6, Xcode 14.2
(14C18), x86_64; Mac at Tailscale `<build-host>`; simulator
`platform=iOS Simulator,name=iPhone 14,OS=16.2`. Bridge: `xcodebuild -version` → exit 0 (`== xcode ==` block: `Xcode 14.2`; log
`/homedir/agent/opencode/apps/20261122T043731Z-check.log`).

Run sequence (workspace root): `sync play-two` → `ok`
(`20261122T043818Z-sync.log`) → `run 'cd play-two &&
xcodegen generate'` → `Created project at …/PlayTwo.xcodeproj`
(`20261122T043821Z-run.log`).

Because the brief notes the full bundle tends to hang after SRP-heavy cases
(DEC-017), the run followed the brief's prescription: `AccessoryIdentityTests`
plus the nine light suites in one run (per-suite `-only-testing` flags,
`/tmp/opencode/t015-nonsrp.log` — `Executed 42 tests, with 0 failures`), and the
`SRPTests` cases individually (`/tmp/opencode/t015-srp-*.log`). The full bundle
was then attempted as the canonical line and completed this time:
`Test Suite 'PlayTwoTests.xctest' passed … Executed 56 tests, with 0 failures
(0 unexpected) in 440.910 (440.971) seconds`, `** TEST SUCCEEDED **`, exit 0
(`/tmp/opencode/t015-full.log`, mirror
`20261122T045012Z-test.log`). The dev's earlier full run also
gave `Executed 56 tests, with 0 failures (0 unexpected) in 437.635 (437.673)
seconds`, `** TEST SUCCEEDED **` (`/tmp/opencode/task-015-test.log`).

## Criteria (task file)

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Given no stored key, when `loadOrCreate()` is called, then it generates a new Ed25519 key pair and returns a public key of exactly 32 bytes | PASS | `Test Case '-[PlayTwoTests.AccessoryIdentityTests testGeneratesNonZeroPublicKey]' passed (0.017 seconds)` (`/tmp/opencode/t015-nonsrp.log`) — asserts `identity.publicKey.count == 32` and `XCTAssertFalse(identity.publicKey.allSatisfy { $0 == 0 })` (`play-two/test/AccessoryIdentityTests.swift:34-35`); static: `Curve25519.Signing.PrivateKey()` at `play-two/src/HAP/AccessoryIdentity.swift:49`, `keyPair.publicKey.rawRepresentation` at `:51` (Ed25519, CryptoKit). |
| 2 | Given a stored key, when `loadOrCreate()` is called again in the same process, then the returned public key bytes are identical to the first call | PASS | `Test Case '-[PlayTwoTests.AccessoryIdentityTests testLoadOrCreateTwiceReturnsSamePublicKey]' passed (0.007 seconds)` (`/tmp/opencode/t015-nonsrp.log`). Trivial form: both calls return the same lazy `static let shared` (`play-two/src/HAP/AccessoryIdentity.swift:29`); the meaningful Keychain round-trip is criterion 3. |
| 3 | Given a key stored in a previous run, when `loadOrCreate()` is called with the Keychain entry present, then it returns that same public key rather than generating a new one | PASS | `Test Case '-[PlayTwoTests.AccessoryIdentityTests testSecondInstanceReloadsStoredPublicKey]' passed (0.018 seconds)` (`/tmp/opencode/t015-nonsrp.log`) — after `XCTAssertNotNil(AccessoryIdentity.storedSeed(service: service))` (`play-two/test/AccessoryIdentityTests.swift:45`), a second instance gives `XCTAssertEqual(first.publicKey, second.publicKey)` at `:47`. Static: read path `SecItemCopyMatching` (`play-two/src/HAP/AccessoryIdentity.swift:62`), generic-password query (`kSecClassGenericPassword`/`kSecAttrService`/`kSecAttrAccount`, `:78-80`), write `SecItemAdd` (`:90`), `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (`:86`). The case is non-vacuous: a fake persistence or a fresh generation would not pass the `storedSeed` NotNil + byte-equality pair. |
| 4 | Given the Keychain entry is deleted, when `loadOrCreate()` is called, then a new key pair is generated and stored, and the public key differs from the deleted one | PASS | `Test Case '-[PlayTwoTests.AccessoryIdentityTests testDeletedEntryGeneratesAndStoresANewKey]' passed (0.021 seconds)` (`/tmp/opencode/t015-nonsrp.log`) — `deleteEntry` then `XCTAssertNil(AccessoryIdentity.storedSeed(service: service))` (`play-two/test/AccessoryIdentityTests.swift:67`), `XCTAssertNotEqual(second.publicKey, firstPublicKey)` and `XCTAssertNotNil(AccessoryIdentity.storedSeed(service: service))` (`:70-71`). |
| 5 | `AccessoryIdentityTests` passes: `Executed 4 tests, with 0 failures` | PASS | Non-SRP run: `Test Suite 'AccessoryIdentityTests' passed at 2026-11-22 06:39:05.348` + `Executed 4 tests, with 0 failures (0 unexpected) in 0.040 (0.043) seconds`; full bundle: `Test Suite 'AccessoryIdentityTests' passed at 2026-11-22 06:50:19.135` + `Executed 4 tests, with 0 failures`; `** TEST SUCCEEDED **` (`/tmp/opencode/t015-full.log`). |

Brief verify map: (a) → criterion 1; (b) → criteria 2 + 3; (c) →
criterion 5 (plus 4, quoted above).

## What I ran

- R1 (build): `xcodebuild build -scheme PlayTwo -sdk iphonesimulator` →
  `** BUILD SUCCEEDED **`, exit 0; app bundle
  `<workspace>play-two/build/Build/Products/Debug-iphonesimulator/PlayTwo.app`
  (`20261122T043825Z-build.log`).
- Non-SRP run (`/tmp/opencode/t015-nonsrp.log`) — key lines:
  - `Test Suite 'AccessoryIdentityTests' passed at 2026-11-22 06:39:05.348.`
    `Executed 4 tests, with 0 failures (0 unexpected) in 0.040 (0.043) seconds`
  - `Test Suite 'AirPlayTXTRecordTests' passed … Executed 7 tests, with 0 failures (0 unexpected)`
  - `Test Suite 'AppInfoTests' passed … Executed 1 tests, with 0 failures`
  - `Test Suite 'AppStateTests' passed … Executed 4 tests, with 0 failures`
  - `Test Suite 'EventLogExportTests' passed … Executed 3 tests, with 0 failures`
  - `Test Suite 'EventLogTests' passed … Executed 5 tests, with 0 failures`
  - `Test Suite 'ReceiverListenerTests' passed … Executed 5 tests, with 0 failures`
  - `Test Suite 'ReceiverStatusTests' passed … Executed 4 tests, with 0 failures`
  - `Test Suite 'ServiceAdvertiserTests' passed … Executed 4 tests, with 0 failures`
  - `Test Suite 'TLV8Tests' passed … Executed 5 tests, with 0 failures`
  - `Test Suite 'PlayTwoTests.xctest' passed at 2026-11-22 06:39:05.697.`
    `Executed 42 tests, with 0 failures (0 unexpected) in 0.357 (0.396) seconds`
  - `grep -cE "Test Case '[^']+' failed" /tmp/opencode/t015-full.log` → `0`
    (also 0 failed in the non-SRP log).
- SRP per-test (14 cases; one `the build bridge run … -only-testing:PlayTwoTests/SRPTests/<Test>`
  per log, `/tmp/opencode/t015-srp-*.log`):
  - `t015-srp-deriver-is-deterministic.log`: `Test Case '-[PlayTwoTests.SRPTests testDeriverIsDeterministic]' passed (29.387 seconds).`
  - `t015-srp-testVerifierChangesWithSalt.log`: `Test Case '-[PlayTwoTests.SRPTests testVerifierChangesWithSalt]' passed (29.357 seconds).`
  - `t015-srp-testVerifierIsInRange.log`: `Test Case '-[PlayTwoTests.SRPTests testVerifierIsInRange]' passed (15.011 seconds).`
  - `t015-srp-testXByteOrderMatchesIndependentVector.log`: `Test Case '-[PlayTwoTests.SRPTests testXByteOrderMatchesIndependentVector]' passed (0.007 seconds).`
  - `t015-srp-testDerivedVerifierMatchesIndependentVector.log`: `Test Case '-[PlayTwoTests.SRPTests testDerivedVerifierMatchesIndependentVector]' passed (15.128 seconds).`
  - `t015-srp-testKIsHashOfNAndG.log`: `Test Case '-[PlayTwoTests.SRPTests testKIsHashOfNAndG]' passed (0.008 seconds).`
  - `t015-srp-testDeriveVerifierRejectsNonEightDigitCodes.log`: `Test Case '-[PlayTwoTests.SRPTests testDeriveVerifierRejectsNonEightDigitCodes]' passed (0.004 seconds).`
  - `t015-srp-testDeriveVerifierStripsDashes.log`: `Test Case '-[PlayTwoTests.SRPTests testDeriveVerifierStripsDashes]' passed (29.877 seconds).`
  - `t015-srp-testGenerateEphemeralReturnsSaltAndBInRange.log`: `Test Case '-[PlayTwoTests.SRPTests testGenerateEphemeralReturnsSaltAndBInRange]' passed (24.928 seconds).`
  - `t015-srp-testGenerateEphemeralRandomness.log`: `Test Case '-[PlayTwoTests.SRPTests testGenerateEphemeralRandomness]' passed (34.120 seconds).`
  - `t015-srp-testGenerateEphemeralRetainsAAndV.log`: `Test Case '-[PlayTwoTests.SRPTests testGenerateEphemeralRetainsAAndV]' passed (24.982 seconds).`
  - `t015-srp-testVerifyRoundTrip.log`: `Test Case '-[PlayTwoTests.SRPTests testVerifyRoundTrip]' passed (118.138 seconds).`
  - `t015-srp-testVerifyTamperedM1ReturnsNil.log`: `Test Case '-[PlayTwoTests.SRPTests testVerifyTamperedM1ReturnsNil]' passed (120.200 seconds).`
  - `t015-srp-testVerifyRejectsDegenerateA.log`: `Test Case '-[PlayTwoTests.SRPTests testVerifyRejectsDegenerateA]' passed (0.976 seconds).`
  - Each log also carries `Test Suite 'SRPTests' passed at …` + `Executed 1 test, with 0 failures (0 unexpected)` + `** TEST SUCCEEDED **`; 14 case lines passed, 0 failed.
- Full bundle (`/tmp/opencode/t015-full.log`): `Test Suite 'AccessoryIdentityTests' passed at 2026-11-22 06:50:19.135.` `Executed 4 tests, with 0 failures (0 unexpected)`; `Test Suite 'SRPTests' passed at 2026-11-22 06:57:39.993.` `Executed 14 tests, with 0 failures (0 unexpected) in 440.339 (440.345) seconds`; `Test Suite 'PlayTwoTests.xctest' passed at 2026-11-22 06:57:40.015.` `Executed 56 tests, with 0 failures (0 unexpected) in 440.910 (440.971) seconds`; `Test Suite 'All tests' passed … Executed 56 tests, with 0 failures`; `** TEST SUCCEEDED **`; exit 0 (mirror `20261122T045012Z-test.log`).

## Findings

None. Observations:

- `testLoadOrCreateTwiceReturnsSamePublicKey` is trivially true (both calls
  return the same lazy `static let shared`,
  `play-two/src/HAP/AccessoryIdentity.swift:29`); the meaningful Keychain
  round-trip is criterion 3's second-instance case, which is non-vacuous (see
  evidence). Not a finding.
- The brief's full-bundle hang warning (DEC-017) did not reproduce — the full
  bundle completed at 440.9 s. Recorded as an observation, not a finding.

## Regressions

- R1 (app builds for the simulator): pass — `** BUILD SUCCEEDED **`, exit 0,
  app at `…/play-two/build/Build/Products/Debug-iphonesimulator/PlayTwo.app`
  (`20261122T043825Z-build.log`).
- R2 (suite green, count never drops): pass — full bundle
  `Executed 56 tests, with 0 failures` (`/tmp/opencode/t015-full.log`, mirror
  `20261122T045012Z-test.log`); the piecemeal totals agree
  (non-SRP `Executed 42` + SRP 14 cases). High-water mark raised **52 → 56**
  in `qa/REGRESSION.md`.
- R5 (no skips; generated project stays out of version control): pass —
  `grep -rnE 'XCTSkip|\.skip' play-two/test` → no matches (exit 1);
  `grep -nE 'xcodeproj|build/' play-two/.gitignore` → `2:*.xcodeproj/`,
  `5:build/`.

## Unverifiable here

None — all five task criteria and R1–R5 are verified on the Mac. Device-level
behaviour outside this task's criteria (FEAT-003's network use of the identity
key) is not claimed by this task.

## Verdict

PASS — criteria 1–5 each have runtime evidence above; the suite is green
(non-SRP 42 + SRP 14 = 56, all with 0 failures, and the canonical full-bundle
line `Executed 56 tests, with 0 failures` + `** TEST SUCCEEDED **`); the Keychain
is the only persistence path (static review: the seed is stored via
`SecItemAdd`/`SecItemDelete` only — `play-two/src/HAP/AccessoryIdentity.swift`
has no `UserDefaults`/file writes).

```text
TASK-015 Ed25519 accessory identity key with Keychain persistence — PASS
Criteria: 5/5 verified · Regressions: pass
Findings: none
Unverifiable here: none
Report: qa/reports/TASK-015-review.md
```
