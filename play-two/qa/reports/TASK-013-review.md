---
id: TASK-013-review
task: TASK-013
feature: FEAT-002
verdict: PASS
date: 2026-11-21
attempt: 1
---

# Review — TASK-013 SRP-3072 server generates salt and ephemeral B

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Salt >= 16 random bytes; B with 1 <= B < N | PASS | `play-two/src/HAP/SRP.swift:96` `salt = SymmetricKey(size: .bits128).withUnsafeBytes { Data($0) }` (16 random bytes); `:111-113` `bLimbs = addMod(kvLimbs, gaLimbs)` then `bData = data(fromLimbs:bLimbs, byteCount: 384)`; `:113` loop condition `while !Self.isInRange(bData)`; `play-two/test/SRPTests.swift:147-165` `testGenerateEphemeralReturnsSaltAndBInRange` asserts `session.salt.count >= 16` and `SRP.isInRange(session.B)`; isolated run passed in 27.23 s (log `20261121T154127Z-run.log`: `Test Case '-[PlayTwoTests.SRPTests testGenerateEphemeralReturnsSaltAndBInRange]' passed (27.230 seconds)`, `** TEST SUCCEEDED **`). |
| 2 | Randomness across calls (salt and B differ) | PASS | `play-two/src/HAP/SRP.swift:90-96` salt is regenerated each outer iteration and `a` via `SymmetricKey(size: .bits256)` at `:99-101`; `play-two/test/SRPTests.swift:167-188` `testGenerateEphemeralRandomness` asserts `s1.salt != s2.salt` and `s1.B != s2.B`; isolated run passed in 39.74 s (log `20261121T155825Z-run.log`: `Executed 1 test, with 0 failures ... (39.735 seconds)`, `** TEST SUCCEEDED **`). |
| 3 | Session retains `a` and `v` | PASS | `play-two/src/HAP/SRP.swift:115` `return SRPServerSession(a: sessionA, v: v, B: bData, salt: salt)` and `SRPServerSession` at `:384-389` stores `a`, `v`, `B`, `salt` as `let`; `play-two/test/SRPTests.swift:190-210` `testGenerateEphemeralRetainsAAndV` asserts `session.v == v`, `session.a.count == 32` and `session.a.contains(where: { $0 != 0 })`; isolated run passed (log `20261121T155910Z-run.log`: `** TEST SUCCEEDED **`). |
| 4 | `SRPTests` passes with 0 failures, including a round-trip exercising criteria 1 and 3 | PASS | Isolated SRP suite: the 3 TASK-013 tests above plus the 8 TASK-012 tests all pass individually (see "What I ran"). Non-SRP suites 38/0 also pass (see "What I ran"). Total 49 tests (11 SRP + 38 others), 0 failures. |

## What I ran

```sh
# from workspace root; host macOS 12.7.6, Xcode 14.2 (14C18), x86_64
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate

# SRP suite in isolation, per test (the all-at-once SRP run crashes the
# simulator test host on this machine; see finding 1)
xcodebuild ... -only-testing:PlayTwoTests/SRPTests/testGenerateEphemeralReturnsSaltAndBInRange test
# -> Test Case '...testGenerateEphemeralReturnsSaltAndBInRange' passed (27.230 seconds); ** TEST SUCCEEDED **
... -only-testing:PlayTwoTests/SRPTests/testGenerateEphemeralRandomness test
# -> Executed 1 test, with 0 failures (39.735 seconds); ** TEST SUCCEEDED **
... -only-testing:PlayTwoTests/SRPTests/testGenerateEphemeralRetainsAAndV test
# -> ** TEST SUCCEEDED **
# (the 8 TASK-012 verifier tests were re-run the same way and all passed)

# non-SRP suites together (light, stable)
./scripts/mac-build.sh run 'cd play-two && xcodebuild ... \
  -only-testing:PlayTwoTests/AirPlayTXTRecordTests ... -only-testing:PlayTwoTests/TLV8Tests test'
# -> AirPlayTXTRecordTests 7/0, AppInfoTests 1/0, AppStateTests 4/0, EventLogExportTests 3/0,
#    EventLogTests 5/0, ReceiverListenerTests 5/0, ReceiverStatusTests 4/0,
#    ServiceAdvertiserTests 4/0, TLV8Tests 5/0; Selected tests 38/0; ** TEST SUCCEEDED **
```

Logs: `20261121T153924Z-run.log` (crashed all-SRP attempt),
`20261121T154127Z-run.log`, `...155825Z-run.log`,
`...155910Z-run.log`, and the non-SRP run's log.

## Findings

1. **MAJOR** — full-bundle test run is unreliable on this host —
   `play-two/test/SRPTests.swift` (heavy SRP cases) + simulator test host.
   Reproduce: run all 11 SRP tests in one xcodebuild invocation
   (`-only-testing:PlayTwoTests/SRPTests`). The log
   `20261121T153924Z-run.log` shows
   `Restarting after unexpected exit, crash, or test timeout in SRPTests.testDeriverIsDeterministic();`
   and ends `Executed 11 tests, with 6 failures (0 unexpected)`, although every
   case passes when run alone (27-40 s each). This matches DEC-017: the Debug
   SRP derivations are ~15-22 s each and the simulator test host is killed/restarted
   by the watchdog/resource pressure. Not a code defect; the suite itself is green
   per-test. Recommend: keep running SRP per-test or in small batches on this host,
   and/or address DEC-017 (Release/-O or in-place REDC) before relying on one
   invocation. Does not affect the verdict: all 11 cases pass individually.
2. **MINOR** — test count discrepancy in the developer report —
   `play-two/journal/<role>.md` TASK-013 entry says "Executed 10 tests", but
   `play-two/test/SRPTests.swift` defines 11 (8 verifier + 3 ephemeral-B). The
   actual count is 11; high-water mark raised to 49 (11 SRP + 38 others), not 50.
3. **OBSERVATION** — per-derivation timing — `play-two/src/HAP/SRP.swift`
   (Debug, `-Onone`): `deriveVerifier` ~15-16 s per call (512-bit exponent),
   `generateEphemeral` ~9-13 s (256-bit exponent); the randomness test exercises
   two full `generateEphemeral` calls (39.7 s). Recorded per DEC-017; not
   optimised here. No scope or correctness issue.

No BLOCKER findings. Implementation inspection (gaming check):
- B is genuinely `(k*v + g^a) mod N`: `kvLimbs = redc(mulmont(montgomery(k), montgomery(v)))` = `k*v mod N` (`src/HAP/SRP.swift:104-106`), `gaLimbs = modExp(g, a)` = `g^a mod N` (`:109`), `bLimbs = addMod(kvLimbs, gaLimbs)` (`:111`). `k` is the cached `H(N || g)` (`:43-51`).
- `a` is fresh per call: `SymmetricKey(size: .bits256)` (`:100`), retried until nonzero (`:99-101`); salt fresh per call via `SymmetricKey(size: .bits128)` (`:96`).
- `a` and `v` are retained by value in `SRPServerSession` (`:384-389`), not defaults/copies; the test compares `session.v == v` and checks `a` is 32 nonzero bytes.
- Tests assert real values (salt length, range, inequality, byte counts) and use `XCTFail` on nil returns; no `XCTSkip`/`XCTExpectFailure` (R5 green).

## Regressions

From `qa/REGRESSION.md`: all pass. R1 build green, R2 high-water 46 -> 49 (11 SRP + 38
others, 0 failures per suite), R5 no skips, R12 verifier row still green, R13 added
for the ephemeral-B behaviour. R2 was verified per-suite rather than in one
invocation because of finding 1. R6 (mutation probe) not re-run this task (no
change to the scaffold test or display-name contract). R3, R4, R7-R11 unchanged
and green.

## Unverifiable on this host

None beyond finding 1 (the all-in-one invocation). Destination used:
`platform=iOS Simulator,name=iPhone 14,OS=16.2` (iOS 16.2 only on this Mac).

## Verdict

All 4 acceptance criteria have evidence; no BLOCKER findings; regressions pass
(per-suite, per finding 1).

**Verdict:** PASS

**Next:** BA records G4, commits `play-two/TASK-013: SRP-3072 server generates salt and ephemeral B`, updates state/board. DEC-017 remains proposed for the performance/watchdog issue.