---
id: TASK-028
title: Decrypt the stream key with FairPlay v3 and a test key table
feature: FEAT-005
status: approved
attempts: 0
owner: null
depends_on: [TASK-025, TASK-027]
estimate: small
---

# TASK-028 — Decrypt the stream key with FairPlay v3 and a test key table

## Goal

Given the encrypted stream-key material from a SETUP fixture and an injected
synthetic key table, the FairPlay v3 layer decrypts the AES stream key to the
known-answer value, proving key recovery without bundling real DRM material.

## Context for the developer

- Where it lives: `src/RTSP/FairPlay.swift` (modified),
  `test/FairPlayTests.swift` (modified).
- Interfaces it may touch: `FairPlaySetup` from TASK-026; the key-table
  injection boundary defined by TASK-025's DEC; `Foundation` and `CryptoKit`
  only as allowed by `docs/STACK.md`.
- Files in scope (2): the two above.
- Explicitly **do not** touch: `project.yml`, `src/Net/`, `src/HAP/`,
  `src/AirPlay/`, `src/Diagnostics/`, `src/PlayTwoApp.swift`,
  `src/ContentView.swift`, `docs/`, `qa/`, journals other than `journal/<role>.md`,
  `scripts/`, `.opencode/`.
- **Do not start until TASK-025's DEC is recorded and any required human
  approval is present.** If the DEC is missing or marks approval pending, report
  `BLOCKED`.

## Acceptance criteria

1. [ ] Given the known-answer fixture (encrypted stream-key bytes + synthetic/
       injected key table bytes + expected AES key bytes), when
       `FairPlay.decryptStreamKey(encryptedKey:keyTable:)` (or equivalent) runs,
       then the returned key bytes equal the fixture's expected AES key exactly.
2. [ ] Given corrupted encrypted-key bytes (one byte flipped) or a missing/empty
       key table, when the same function runs, then it returns `nil`/throws a
       typed error and does not return a partial/wrong key.
3. [ ] `FairPlayTests` passes: `Test Suite 'FairPlayTests' passed` and
       `Executed 4 tests, with 0 failures` — the two TASK-027 tests still pass
       plus the two cases above.
4. [ ] No real FairPlay key table is added to the repository; fixture material
       is synthetic/test-only and the test comment states it is not Apple DRM
       material.

## Verification commands

```sh
# on this host
ls play-two/src/RTSP play-two/test
git -C /homedir/agent/opencode/apps ls-files | grep -i fairplay | grep -v DECISIONS | grep -v TASK-025 | grep -v TASK-027 | grep -v TASK-028 | grep -v FEAT-005 | grep -v FEAT-006 || echo "no fairplay impl files tracked yet"

# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.2' | tee /tmp/opencode/task-028-test.log
grep -E "Test Suite 'FairPlayTests' (passed|failed)" /tmp/opencode/task-028-test.log
grep -E "Executed [0-9]+ tests?, with 0 failures" /tmp/opencode/task-028-test.log | tail -1
```

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-028-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes: `R2` count ≥ 96 (expect ≈ 96 after the run; QA/BA update `qa/REGRESSION.md`)
- [ ] One commit `play-two/TASK-028: decrypt the stream key with FairPlay v3 and a test key table` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- This is the key-recovery half of the FEAT-005 kill-switch. If the known-answer
  fixture cannot be produced without real DRM material, stop and report; do not
  weaken the criterion to "it returns some bytes".
- Keep the AES key in memory only; do not log key bytes, do not write them to
  disk, do not export them in diagnostics. The log line required by FEAT-005 is
  `FairPlay key decrypted` (a milestone), not the key value.
- If implementation exceeds one sitting or needs a non-STACK dependency, stop
  and ask BA for a split/DEC. Do not add a package.
- TASK-027's tests remain part of the same `FairPlayTests` suite and must keep
  passing.
