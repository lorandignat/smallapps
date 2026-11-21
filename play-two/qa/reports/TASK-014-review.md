---
id: TASK-014-review
task: TASK-014
feature: FEAT-002
verdict: PASS
date: 2026-11-21
attempt: 1
---

# Review — TASK-014 SRP-3072 server verifies client proof and derives session key

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Given a valid client proof `M1` from a matching test client, when `verify(session:clientA:clientM1:)` is called, then it returns `M2` and `K`, and the returned `M2` equals the value the test client computes independently. | PASS | `Test Case '-[PlayTwoTests.SRPTests testVerifyRoundTrip]' passed (125.333 seconds).` in `20261121T190935Z-run.log` (`Executed 1 test, with 0 failures`). The nil path is not vacuous: `SRPTests.swift:305` `XCTFail("verify returned nil for valid proof")`. `XCTAssertEqual(result.M2, client.M2)` at `play-two/test/SRPTests.swift:309` — the client computes its own `M2 = H(A ‖ M1 ‖ K)` in `clientHandshake` (`:272-276`). |
| 2 | Given a tampered `M1` (one bit flipped), when verify is called, then it returns nil and no `K` is exposed. | PASS | `Test Case '-[PlayTwoTests.SRPTests testVerifyTamperedM1ReturnsNil]' passed (124.999 seconds).` in `20261121T191150Z-run.log`. `tampered[0] ^= 0x01` + `XCTAssertNil(SRP.verify(...))` at `play-two/test/SRPTests.swift:337-341`; the server aborts via `guard m1Computed == clientM1 else { return nil }` at `play-two/src/HAP/SRP.swift:157-159`. |
| 3 | Given a completed handshake, when the accessory's `K` and the test client's `K` are compared, then they are byte-identical. | PASS | `XCTAssertEqual(result.K, client.K)` at `play-two/test/SRPTests.swift:310`, passed inside the round trip above (both the individual run and the full-bundle run: `Test Case ... testVerifyRoundTrip]' passed (119.752 seconds)` in `20261121T192232Z-test.log`). The two sides compute `S` by independent code paths: the server computes `S = (A·v^u)^a mod N` (`play-two/src/HAP/SRP.swift:141-147`) while the client computes `S = term1·term2` with `term1 = base^aClient` and `term2 = base^u·v^x` (`play-two/test/SRPTests.swift:258-262`); the equal-byte assert is therefore a real cross-check, not a self-comparison. |
| 4 | Given `A == 0` or `A % N == 0`, when verify is called, then it aborts (returns nil) rather than dividing by zero. | PASS | `Test Case '-[PlayTwoTests.SRPTests testVerifyRejectsDegenerateA]' passed (0.760 seconds).` in `20261121T191404Z-run.log`. `SRP.verify` aborts on `isZeroModN(clientA)` at `play-two/src/HAP/SRP.swift:125-127` (`isZeroModN` at `:171-179`); the test calls `verify` twice — with a 384-byte zero `A` and with `SRP.NData` (`A % N == 0`) — and asserts nil for both (`play-two/test/SRPTests.swift:348-356`), so the "second call" is also covered. |
| 5 | `SRPTests` passes: `Executed N tests, with 0 failures`, including a round-trip test exercising criteria 1 and 3. | PASS | `Test Suite 'SRPTests' passed at 2026-11-21 21:30:02.905.` — `Executed 14 tests, with 0 failures (0 unexpected) in 444.336 (444.342) seconds` in `20261121T192232Z-test.log` (N = 14: 8 verifier + 3 ephemeral-B + 3 verify). The three verify cases are listed green inside it: `testVerifyRoundTrip` (118.835 s), `testVerifyTamperedM1ReturnsNil` (117.952 s), `testVerifyRejectsDegenerateA` (0.595 s). |

## What I ran

```sh
# from workspace root
xcodebuild -version                       # exit 0: macOS 12.7.6, Xcode 14.2 (14C18), x86_64
rsync -a <project> <build-host>:<build-dir>/               # ok — log: 20261121T190914Z-sync.log
xcodegen generate   # ok — log: 20261121T190915Z-run.log

xcodebuild build -scheme PlayTwo -sdk iphonesimulator            # R1
# -> ** BUILD SUCCEEDED **, app at build/Build/Products/Debug-iphonesimulator/PlayTwo.app
#    (log 20261121T190915Z-build.log)

# heavy verify tests individually (destination platform=iOS Simulator,name=iPhone 14,OS=16.2)
./scripts/mac-build.sh run 'cd play-two && xcodebuild -project PlayTwo.xcodeproj -scheme PlayTwo \
  -destination "platform=iOS Simulator,name=iPhone 14,OS=16.2" -derivedDataPath "play-two/build" \
  -allowProvisioningUpdates test -only-testing:PlayTwoTests/SRPTests/testVerifyRoundTrip'
# -> Test Case '-[PlayTwoTests.SRPTests testVerifyRoundTrip]' passed (125.333 seconds).   # 20261121T190935Z-run.log
... -only-testing:PlayTwoTests/SRPTests/testVerifyTamperedM1ReturnsNil test
# -> Test Case '-[PlayTwoTests.SRPTests testVerifyTamperedM1ReturnsNil]' passed (124.999 seconds).  # 20261121T191150Z-run.log
... -only-testing:PlayTwoTests/SRPTests/testVerifyRejectsDegenerateA test
# -> Test Case '-[PlayTwoTests.SRPTests testVerifyRejectsDegenerateA]' passed (0.760 seconds).  # 20261121T191404Z-run.log

# the SRPTests suite itself (criterion 5)
xcodebuild ... -only-testing:PlayTwoTests/SRPTests test
# -> Test Suite 'SRPTests' passed at 2026-11-21 21:21:52.212. / Executed 14 tests, with 0 failures (0 unexpected) in 445.289 seconds  # 20261121T191423Z-run.log

# the other non-SRP suites (9, fast)
xcodebuild ... -only-testing:PlayTwoTests/AirPlayTXTRecordTests -only-testing:PlayTwoTests/AppInfoTests -only-testing:PlayTwoTests/AppStateTests -only-testing:PlayTwoTests/EventLogExportTests -only-testing:PlayTwoTests/EventLogTests -only-testing:PlayTwoTests/ReceiverListenerTests -only-testing:PlayTwoTests/ReceiverStatusTests -only-testing:PlayTwoTests/ServiceAdvertiserTests -only-testing:PlayTwoTests/TLV8Tests test
# -> 9 suites passed; Executed 38 tests, with 0 failures  # 20261121T192204Z-run.log

# R2: the full bundle (observes the DEC-017 hang question)
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.2'
# -> ** TEST SUCCEEDED **; Test Suite 'All tests' passed; Executed 52 tests, with 0 failures  # 20261121T192232Z-test.log

# R5
grep -rnE 'XCTSkip|\.skip' play-two/test || echo 'no skips'        # -> no skips
grep -nE 'xcodeproj|build/' play-two/.gitignore                    # -> *.xcodeproj/ (:2), build/ (:5)

# R3 static re-check
grep -c 'packages:' play-two/project.yml                           # -> 0
grep -n 'iOS: "15.0"' play-two/project.yml                         # -> project.yml:13
grep -A1 '^schemes:' play-two/project.yml                          # -> PlayTwo:
grep -c 'DEVELOPMENT_TEAM' play-two/project.yml                    # -> 0 (exit 1)
```

Implementation inspection, per the dev's claims, as read from `play-two/src/HAP/SRP.swift` and `play-two/test/SRPTests.swift`:
`verify` returns `(M2: Data, K: Data)?` (`:123`); `u = H(A || B)` (`:133-138`); `S = (A·v^u)^a mod N` (`:141-147`); `K = H(S)` (`:149`); `M2 = H(A || M1 || K)` (`:162-166`); nil on `A == 0`/`A % N == 0` via `isZeroModN` (`:125-127`, `:171-179`); nil on M1 mismatch (`:157-159`); the session (`a`, `v`) is taken by value and never retained (`:118-123`, `SRPServerSession` is a struct of `let`s, `:447-452`). No swallowed errors, no `XCTSkip`/`XCTExpectFailure` (R5).

## Findings

1. **OBSERVATION — timing** — `verify` is ~2× a single derivation in the Debug simulator: 125.333 s (round trip, `20261121T190935Z-run.log`) and 124.999 s (tampered, `20261121T191150Z-run.log`) vs ~15-22 s per derivation elsewhere (`play-two/journal/<role>.md`, TASK-013). Expected shape, not a defect; the DEC-017 (performance/watchdog) decision remains open.
2. **OBSERVATION — full-bundle hang did not reproduce this run** — the TASK-013-precedent hang (`20261121T153924Z-run.log`, TASK-013 attempt 1) was not observed: the full bundle completed, `Executed 52 tests, with 0 failures`, `** TEST SUCCEEDED **` (`20261121T192232Z-test.log`). The per-test runs of the heavy SRP cases were still done as the task's verification plan requests; recommend the DEC-017 follow-up to see whether the hang returns with the heavier suite.

No BLOCKER or MAJOR findings.

## Regressions

From `qa/REGRESSION.md`:

- **R1 pass** — `** BUILD SUCCEEDED **`, app at `build/Build/Products/Debug-iphonesimulator/PlayTwo.app` (`20261121T190915Z-build.log`).
- **R2 pass** — `Executed 52 tests, with 0 failures`, `** TEST SUCCEEDED **` (`20261121T192232Z-test.log`); per suite: `SRPTests` `Executed 14 tests, with 0 failures` (`20261121T191423Z-run.log`) and the nine non-SRP suites `Executed 38 tests, with 0 failures` (`20261121T192204Z-run.log`). High-water mark raised **49 → 52** (TASK-013 → TASK-014; R2's new number updated in `qa/REGRESSION.md`).
- **R3 pass** (re-run) — static: `packages:` 0, `iOS: "15.0"` at `project.yml:13`, scheme `PlayTwo`, `DEVELOPMENT_TEAM` 0; generated project: scheme `PlayTwo`, `IPHONEOS_DEPLOYMENT_TARGET = 15.0`.
- **R5 pass** — `grep -rnE 'XCTSkip|\.skip' play-two/test` → `no skips`; `grep -nE 'xcodeproj|build/' play-two/.gitignore` → `*.xcodeproj/` (`:2`), `build/` (`:5`).
- **R6 not applicable** — no change to the scaffold test or the display-name contract.

## Unverifiable on this host

None blocking. Device-side observations (TEST-PLAN O1-O6) are human-only and out of this task's scope.

Scope: the dev diff (`git diff fa48371 HEAD -- play-two/src play-two/test`) touches only `play-two/src/HAP/SRP.swift` and `play-two/test/SRPTests.swift` (the commit also carries BA bookkeeping in `backlog/BOARD.md`, `backlog/tasks/TASK-014-srp-verify-m1.md`, `docs/STATE.md`, `journal/<role>.md`). This turn wrote only `qa/reports/TASK-014-review.md`, `qa/REGRESSION.md` and `journal/<role>.md`.

## Verdict

All 5 acceptance criteria have evidence; regressions pass; the full bundle is green this run (`Executed 52 tests, with 0 failures`). Two observations recorded, neither failing the task.

**Verdict: PASS** — criteria 5/5; high-water mark 52.

**Next:** BA records G4, commits `play-two/TASK-014: SRP-3072 server verifies client proof and derives session key`.
