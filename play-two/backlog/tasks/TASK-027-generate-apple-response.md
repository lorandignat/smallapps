---
id: TASK-027
title: Generate Apple-Response from a challenge and test key table
feature: FEAT-005
status: blocked
attempts: 1
owner: null
depends_on: [TASK-025, TASK-026]
estimate: small
---

# TASK-027 — Generate Apple-Response from a challenge and test key table

## Goal

Given an `Apple-Challenge` and an injected synthetic key table, the FairPlay v3
layer produces the expected `Apple-Response` bytes for a known-answer fixture,
proving the handshake response path without bundling real DRM material.

## Context for the developer

- Where it lives: `src/RTSP/FairPlay.swift` (new), `test/FairPlayTests.swift` (new or extended by later TASK-028; prefer a single `FairPlayTests` suite file — record the choice in the journal).
- Interfaces it may touch: `FairPlaySetup` model from TASK-026; `Foundation`.
  The key table is passed as an injected value (e.g. `Data`/bytes) — no file
  path to a repo-committed real table, no bundle resource containing DRM.
- Files in scope (2): `src/RTSP/FairPlay.swift` (new), `test/FairPlayTests.swift` (new).
- Explicitly **do not** touch: `project.yml`, `src/Net/`, `src/HAP/`,
  `src/AirPlay/`, `src/Diagnostics/`, `src/PlayTwoApp.swift`,
  `src/ContentView.swift`, `docs/`, `qa/`, journals other than `journal/<role>.md`,
  `scripts/`, `.opencode/`.
- **Do not start until TASK-025's DEC is recorded and any required human
  approval is present.** If the DEC is missing or marks approval pending, report
  `BLOCKED`.

## Acceptance criteria

1. [ ] Given the known-answer fixture (challenge bytes + synthetic/injected key
       table bytes + expected `Apple-Response` bytes), when
       `FairPlay.generateAppleResponse(challenge:keyTable:)` (or equivalent)
       runs, then the returned bytes equal the fixture's expected
       `Apple-Response` exactly.
2. [ ] Given a malformed/too-short challenge or a missing/empty key table, when
       the same function runs, then it returns `nil`/throws a typed error and
       does not crash.
3. [ ] `FairPlayTests` passes: `Test Suite 'FairPlayTests' passed` and
       `Executed 2 tests, with 0 failures` — covering the two cases above.
4. [ ] No real FairPlay key table is added to the repository: the fixture key
       table in the test is synthetic/test-only and the test comment states it
       is not Apple DRM material.

## Verification commands

```sh
# on this host
ls play-two/src/RTSP play-two/test
git -C /homedir/agent/opencode/apps ls-files | grep -i fairplay | grep -v DECISIONS | grep -v TASK-025 | grep -v TASK-027 | grep -v TASK-028 | grep -v FEAT-005 | grep -v FEAT-006 || echo "no fairplay impl files tracked yet"

# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.2' | tee /tmp/opencode/task-027-test.log
grep -E "Test Suite 'FairPlayTests' (passed|failed)" /tmp/opencode/task-027-test.log
grep -E "Executed [0-9]+ tests?, with 0 failures" /tmp/opencode/task-027-test.log | tail -1
```

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-027-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes: `R2` count ≥ 94 (expect ≈ 94 after the run; QA/BA update `qa/REGRESSION.md`)
- [ ] One commit `play-two/TASK-027: generate Apple-Response from a challenge and test key table` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- This task is the FairPlay v3 handshake half only; key decryption is
  TASK-028. Keep it to one behaviour.
- The "known-answer fixture" must be traceable to the reference behaviour named
  in SPIKE-001 or to a synthetic vector whose derivation is explained in the
  test comment. Do not make the expected bytes equal to whatever the code
  produces.
- If the implementation cannot fit in one sitting or requires a dependency not
  in `docs/STACK.md`, stop and report; do not add a package, do not vendor a
  large blob, and do not commit real DRM tables. Escalate to BA for a split or
  DEC.
- Key table injection boundary must follow TASK-025's DEC. If the DEC is not
  present, this task is `BLOCKED`.
- **BLOCKED 2026-11-22 (attempt 1, BA):** developer produced a transparent
  synthetic XOR stand-in (not real FairPlay v3) with self-consistent fixtures.
  BA rejected it as not meeting TASK-027/FEAT-005 intent (real Apple TV
  handshake needs real FairPlay v3 behavior). Escalated as QQ-012; no fake
  crypto committed.
