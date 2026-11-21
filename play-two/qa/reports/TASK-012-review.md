# TASK-012 — Derive SRP-3072 verifier from setup code and salt — PASS

**Reviewer:** qa (tester)
**Date:** 2026-11-21
**Verdict:** PASS
**Attempts:** 3 (final attempt verified here)

## Summary

All five acceptance criteria are met with quotable evidence. The full suite ran
green on the current host (macOS 12.7.6, Xcode 14.2, iOS 16.2 simulator):
`Executed 46 tests, with 0 failures`. `SRPTests` is 8/8. The verifier is
genuinely `g^x mod N` over the RFC 3526 3072-bit group (independently
recomputed in Python and matched byte-for-byte), `x` uses the documented
`salt || utf8(code)` order, and the three independent vectors (`x`, `v`, `k`)
were verified against a Python computation rather than produced by the
implementation. Two quality findings (flakiness on a cold simulator, scope
drift) and one process observation (performance) are recorded below; none
blocks the verdict.

## Environment

- Host: MacBook Pro 2015, macOS 12.7.6 (21H1320), Xcode 14.2 (14C18), x86_64,
  Tailscale `<build-host>`.
- Simulator destination used: `platform=iOS Simulator,name=iPhone 14,OS=16.2`
  (no iPhone 16e / iOS 26.5 runtime on this host; `REGRESSION.md` updated).
- xcodegen 2.38.0 staged at `<build-dir>/.tooling/xcodegen` (`DEC-016`).

## Acceptance criteria — evidence

### Criterion 1 — deterministic (same code + salt → byte-identical verifier)
- Test: `SRPTests.testDeriverIsDeterministic()` — PASSED.
- Log: `20261121T143554Z-test.log`:
  `Test Case '-[PlayTwoTests.SRPTests testDeriverIsDeterministic]' passed (30.815 seconds).`
- Code: `play-two/src/HAP/SRP.swift:51-58` (`deriveVerifier`) is a pure function
  of its inputs; no mutable/global state. The assert is a real `XCTAssertEqual`
  on `Data`, not vacuous.

### Criterion 2 — salt sensitivity (same code, two salts → different verifiers)
- Test: `SRPTests.testVerifierChangesWithSalt()` — PASSED.
- Log: `20261121T143554Z-test.log`:
  `Test Case '-[PlayTwoTests.SRPTests testVerifierChangesWithSalt]' passed (30.076 seconds).`
- Assert: `XCTAssertNotEqual` between `deriveVerifier(... salt)` and
  `deriveVerifier(... otherSalt)`.

### Criterion 3 — `1 <= v < N` for any valid input
- Test: `SRPTests.testVerifierIsInRange()` — PASSED.
- Log: `20261121T143554Z-test.log`:
  `Test Case '-[PlayTwoTests.SRPTests testVerifierIsInRange]' passed (15.574 seconds).`
- Code: `play-two/src/HAP/SRP.swift:69-76` (`isInRange`) rejects all-zero and
  requires `compare(value, N) < 0`. Independently verified: the hardcoded
  `expectedVHex` vector satisfies `1 <= v < N` (Python check, see below).

### Criterion 4 — `x = SHA512(salt || utf8(code))` with documented byte order
- Tests: `SRPTests.testXByteOrderMatchesIndependentVector()` — PASSED;
  `SRPTests.testDerivedVerifierMatchesIndependentVector()` — PASSED.
- Log: `20261121T143554Z-test.log`:
  `Test Case '-[PlayTwoTests.SRPTests testXByteOrderMatchesIndependentVector]' passed (0.001 seconds).`
  `Test Case '-[PlayTwoTests.SRPTests testDerivedVerifierMatchesIndependentVector]' passed (16.532 seconds).`
- Code documentation: `play-two/src/HAP/SRP.swift:5-14` and `:60-67` state
  `x = SHA512(salt || setupCode)` with salt bytes first then the 8 ASCII
  digits, the digest read as a big integer (first digest byte = x's MSB).
- Code: `SRP.x(salt:code:)` (line 62-67) appends `salt` then `code.utf8` and
  hashes with `SHA512`. Verified byte-for-byte against Python
  `hashlib.sha512(salt + code.encode())` →
  `dc5a21fe…0f3cf5` (matches `expectedXHex`).
- Independent vector for `v`: Python `pow(2, x, N)` (RFC 3526 §4 modulus) →
  384 bytes, equals `expectedVHex` (see "Independent verification" below).

### Criterion 5 — `SRPTests` passes, suite green
- Command run:
  `xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.2'`
  (tee'd to `/tmp/opencode/task-012-test2.log`, mirror log
  `20261121T143554Z-test.log`).
- Result: `** TEST SUCCEEDED **`.
- Quoted lines:
  `Test Suite 'SRPTests' passed at 2026-11-21 16:38:03.645.`
  `Executed 8 tests, with 0 failures (0 unexpected) in 123.676 (123.723) seconds`
  `Test Suite 'All tests' passed at 2026-11-21 16:38:03.646.`
  `Executed 46 tests, with 0 failures (0 unexpected) in 123.676 (123.727) seconds`
- All ten suites passed: `AirPlayTXTRecordTests`, `AppInfoTests`, `AppStateTests`,
  `EventLogExportTests`, `EventLogTests`, `ReceiverListenerTests`,
  `ReceiverStatusTests`, `SRPTests`, `ServiceAdvertiserTests`, `TLV8Tests`.

## Independent verification (vectors not produced by the implementation)

Recomputed in Python 3 on this host, without using the Swift code, from the RFC
3526 §4 modulus (parsed from `play-two/src/HAP/SRP.swift`'s `N` array,
little-endian limbs → big integer; `bit_length == 3072`, top/bottom 64 bits
all `0xffffffffffffffff`, matching RFC 3526):

- `N` is 3072 bits, odd, with the RFC 3526 form. ✓
- `x = SHA512(salt || "00102003")` = `dc5a21fe…0f3cf5` == `expectedXHex`. ✓
- `v = pow(2, x, N)` = 384 bytes == `expectedVHex`. ✓ (`1 <= v < N` true.)
- `k = SHA512(N || 0x02)` = `6fd1d7f8…0f3b455` == `expectedKHex`. ✓

The test vectors are therefore independent of the implementation and correct.

## Gaming / implementation checks

1. `v` is genuinely `g^x mod N` over the RFC 3526 group, not a hash or
   truncation: the independent-vector test (`testDerivedVerifierMatchesIndependentVector`)
   compares the full 384-byte result to `pow(2, x, N)` and passed. ✓
2. `x` uses the documented order `salt || utf8(code)`: `SRP.x` (line 62-67)
   appends salt then `code.utf8`; verified against Python SHA-512. ✓
3. `k = H(N || g)` (standard SRP-6a multiplier) is computed and documented in
   a comment (`SRP.swift:8, 42-47`); `k()` returns `SHA512(NData || g)`. ✓
4. `N`, `g` are `static let` constants in `SRP` (`N` line 21, `g` line 40);
   `nByteCount = 384`. ✓
5. Helpers (`modExp`, byte↔int conversion, etc.) are `static` on `SRP`, internal,
   reusable by TASK-013/014. ✓
6. Imports are only `CryptoKit` and `Foundation` (line 1-2); no package added. ✓
7. Tests assert real values (`XCTAssertEqual`/`XCTAssertNotEqual`/`XCTAssertTrue`/
   `XCTAssertNil`), no `XCTSkip`, no swallowed errors (the `guard let v else {
   XCTFail; return }` pattern in `testVerifierIsInRange` is a legitimate nil
   guard, not a swallowed failure). ✓
8. Setup-code validation: dashes stripped, 8 digits required, nil otherwise
   (`validatedCode`, line 82-89); covered by
   `testDeriveVerifierRejectsNonEightDigitCodes` and
   `testDeriveVerifierStripsDashes` (both passed). ✓
9. No vacuous asserts found; the file-name/value literals in tests are hardcoded
   (not derived from the code under test). ✓

## Regression list

- **R1** (build): PASS — `** BUILD SUCCEEDED **`, app at
  `build/Build/Products/Debug-iphonesimulator/PlayTwo.app`
  (log `20261121T143958Z-build.log`).
- **R2** (tests, high-water 38 → 46): PASS — `Executed 46 tests, with 0 failures`
  (log `20261121T143554Z-test.log`). `REGRESSION.md` updated:
  high-water mark **46**, plus new row **R12** for the SRP verifier.
- **R5** (no skips, generated project ignored): PASS — `grep -rnE 'XCTSkip|\.skip'`
  → `no skips`; `.gitignore` has `*.xcodeproj/` and `build/`.
- Other rows (R3, R4, R6, R7, R8, R9, R10, R11): destinations in
  `REGRESSION.md` corrected to `platform=iOS Simulator,name=iPhone 14,OS=16.2`
  (host record corrected to macOS 12.7.6 / Xcode 14.2 / iOS 16.2 simulators) in
  the same edit. Their behaviour is unchanged by this task (SRP touches no
  AirPlay/Net/UI code).

## Findings

1. **MAJOR — test flakiness on a cold simulator (watchdog).** During the first
   full run on a cold simulator, four `SRPTests` cases (`testDeriverIsDeterministic`,
   `testDeriveVerifierStripsDashes`, `testVerifierChangesWithSalt`,
   `testVerifierIsInRange`) crashed with `SIGKILL` / `0x8BADF00D`:
   "application … failed to terminate gracefully after 5.0s" (FrontBoard watchdog),
   because each derivation blocks the main thread for ~15-30 s. The same suite
   passed 46/0 once the simulator was warm (second run, log
   `20261121T143554Z-test.log`). Crash reports:
   `~/Library/Logs/DiagnosticReports/PlayTwo-2026-11-21-1622*.ips`.
   Root cause: long synchronous work on the main (test) thread. The developer
   should either move the derivation off the main thread in tests (dispatch +
   wait) or run SRP tests with a watchdog-friendly configuration. This is a
   reliability issue, not a correctness one, and does not fail the criterion
   (the suite is green on a warm run), but it makes the suite non-deterministic.
   File/line: `play-two/test/SRPTests.swift:49-102` (test methods block the main
   thread); implementation `play-two/src/HAP/SRP.swift:142` (`modExp`).

2. **MINOR — scope drift.** The task's "Files in scope (2)" lists only
   `src/HAP/SRP.swift` and `test/SRPTests.swift`, and explicitly forbids `docs/`,
   backlog and other journals. The developer's commits also touched
   `play-two/backlog/BOARD.md`, `play-two/backlog/tasks/TASK-012-srp-verifier.md`
   and `play-two/docs/STATE.md` (status/attempts bookkeeping) in commits
   `6b799c9`, `e58e13d`, `0773b96`. Behaviour is correct; this is a process/
   ownership deviation for the BA to reconcile (status changes belong to the BA).
   No source files outside the two listed were changed.

3. **OBSERVATION (not a failure) — performance.** Each derivation takes ~16-22 s
   in this Debug (`-Onone`) test build (suite ~124 s for 8 cases), far above the
   task's "~2 s" note. The developer recorded this but did not file a `DEC-###`
   before the algorithm was finalised; no optimisation was applied, as required
   (do not silently change the algorithm). The criterion does not cover
   performance, so this is not a FAIL. **Should it gate FEAT-003?** Yes in the
   sense that FEAT-003's pairing flow derives `v` during setup, so a 16-22 s
   blocking derivation is a poor UX and a watchdog risk on device; it should be
   resolved (record the `DEC-###`, then either accept the cost for a one-time
   setup step or optimise the REDC/in-place limbs) before FEAT-003 ships. It does
   not gate TASK-012 itself.

## Unverifiable here

- None blocking. The device-level / human-observable items (share sheet tap,
  home-screen label) belong to other tasks and are out of scope for TASK-012.
- The performance measurement is from the Debug simulator build only; a
  Release/`-O` measurement on device would be needed to decide whether
  optimisation is actually required.

## Report

`qa/reports/TASK-012-review.md` (this file). New regression high-water mark: **46**.