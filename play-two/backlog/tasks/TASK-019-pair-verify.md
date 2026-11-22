---
id: TASK-019
title: Establish an encrypted session with `POST /pair-verify`
feature: FEAT-003
status: in-progress
attempts: 1
owner: null
depends_on: [TASK-018]
estimate: small
---

# TASK-019 — Establish an encrypted session with `POST /pair-verify`

## Goal

`POST /pair-verify` establishes the encrypted session between the accessory and
the Home app, using CryptoKit's `ChaCha20Poly1305` (`docs/STACK.md`: the stack's
crypto for this feature). The wire shape is a documented assumption — no
Home-app reference exists on this host; the shape is exercised by
`HAPPairVerifyTests` and by the feature-close observation S2a.

## Context for the developer

- Where it lives: `src/HAP/HAPPairVerify.swift` (new), `src/HAP/HAPServer.swift`
  (modified: `pairVerifySession`, the `POST /pair-verify` route).
- Interfaces it may touch: `AccessoryIdentity` (the accessory's identity key,
  ` accessory.shared.publicKey`), `HAPPairingStore` (the pairing `salt`),
  `SRP.sha512`, `TLV8`/`TLV8Entry`.
- Files in scope (4): `src/HAP/HAPPairVerify.swift` (new), `src/HAP/HAPServer.swift`
  (modified), `test/HAPPairVerifyTests.swift` (new), `test/HAPServerTests.swift`
  (modified).
- Explicitly **do not** touch: `project.yml`, `src/PlayTwoApp.swift`,
  `src/ContentView.swift`, `src/Net/`, `src/HAP/SRP.swift`, `src/HAP/TLV8.swift`,
  `src/HAP/HAPPairSetup.swift`, `src/HAP/HAPPairingStore.swift`,
  `src/HAP/AccessoryIdentity.swift`, `src/AirPlay/`, `src/Diagnostics/`, `docs/`,
  `qa/`, journals other than `journal/<role>.md`, `scripts/`, `.opencode/`.

## Acceptance criteria

1. [ ] Given a `POST /pair-verify` request with TLV type 1 = A_e (the client's
       ephemeral public key), when routed, then the response status is 200, the
       TLV contains the accessory's ephemeral public key B_e (type 2, 32
       bytes), and `HAPServer.pairVerifySession` is set.
2. [ ] Given request 2 with TLV type 4 = T = `H(A_e ‖ B_e ‖ accessoryIdentityPublicKey ‖
       pairingSalt)` (the client computes this from the response values:
       `HAPPairVerify.Session.proof` is the contract), when routed, then the
       response status is 200 with the server proof `H(A_e ‖ B_e ‖
       accessoryIdentityPublicKey ‖ T)` (TLV type 3) and the session's key is
       armed (`HAPPairVerify.Session.key != nil`).
3. [ ] Given a tampered T, when routed, then the response status is 400.
4. [ ] `HAPPairVerifyTests` passes: `Executed 4 tests, with 0 failures` —
       `testRequestOneCarriesTheAccessoryKeyAndRequestTwoVerifies`,
       `testTamperedProofVerifiesNothing`, `testTheSealedSessionRoundTrips`,
       `testSealFailsBeforeVerify`.
5. [ ] `HAPServerTests` passes: `Executed 10 tests, with 0 failures` — the nine
       from TASK-018 plus `testRoutePostPairVerifyReturnsTheAccessoryKey`
       (request 1 → 200, TLV type 2, `server.pairVerifySession != nil`).

## Verification commands

```sh
# on this host
ls play-two/src/HAP play-two/test
# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.2' | tee /tmp/opencode/task-019-test.log
grep -E "Test Suite '(HAPPairVerifyTests|HAPServerTests)' (passed|failed)" /tmp/opencode/task-019-test.log
grep -E "Executed [0-9]+ tests?, with 0 failures" /tmp/opencode/task-019-test.log
```

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-019-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes: `R2` count ≥ 78 (expect ≈ 78 after the run; QA/BA update `qa/REGRESSION.md`)
- [ ] One commit `play-two/TASK-019: establish an encrypted session with POST /pair-verify` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- Wire shape — request 1 (`POST /pair-verify`, TLV type 1 = A_e): response
  [B_e (TLV type 2)]. Request 2 (`POST /pair-verify`, TLV type 4 = T): response
  [M (TLV type 3)], the server proof. Assumption — no Home-app reference here;
  TASK-019's wire shape is exercised by the unit tests and by S2a at feature
  close.
- The agreed key: `T[0..<32]` on both sides — the server derives it from the
  proof it verified, the client from the proof it sent; they are the same
  digest by construction of `HAPPairVerify.Session.proof`.
- API-shape risk: CryptoKit's `ChaCha20Poly1305` calls — `seal(_:using:)` /
  `open(_:using:)` — are written against the public API; if the SDK has the
  nonce parameter spelled differently, adjust in the first build (the
  `HAPPairVerifyTests` failures say exactly which).
- TASK-021 shows the setup code on the state screen
  (`HAPServer.setupCode`); the pair-verify tests use their own constants.
