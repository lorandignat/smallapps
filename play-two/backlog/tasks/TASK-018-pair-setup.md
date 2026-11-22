---
id: TASK-018
title: Complete `POST /pair-setup` (SRP M1–M6) using the SRP primitives
feature: FEAT-003
status: proposed
attempts: 0
owner: null
depends_on: [TASK-017]
estimate: small
---

# TASK-018 — Complete `POST /pair-setup` (SRP M1–M6) using the SRP primitives

## Goal

`POST /pair-setup` completes the SRP-3072 exchange between the accessory and a
Home-app client, using the `FEAT-002` primitives (`SRP.deriveVerifier` TASK-012,
`SRP.generateEphemeral` TASK-013, `SRP.verify` TASK-014): the accessory marks
the pairing stored in the store as `paired`.

## Context for the developer

- Where it lives: `src/HAP/HAPPairSetup.swift` (new), `src/HAP/HAPServer.swift`
  (modified: `pairSetup`, the `POST /pair-setup` route).
- Interfaces it may touch: `HAPPairingStore` (record save, `salt`, `verifier`,
  `paired`), `SRPServerSession`, `SRP.deriveVerifier`/`generateEphemeral`/`verify`,
  `TLV8`/`TLV8Entry`, `HAPServer.route`/`tlvEntry`.
- Files in scope (3): `src/HAP/HAPPairSetup.swift` (new), `src/HAP/HAPServer.swift`
  (modified), `test/HAPPairSetupTests.swift` (new).
- Explicitly **do not** touch: `project.yml`, `src/PlayTwoApp.swift`,
  `src/ContentView.swift`, `src/Net/`, `src/HAP/SRP.swift`, `src/HAP/TLV8.swift`,
  `src/HAP/AccessoryIdentity.swift`, `src/HAP/HAPPairingStore.swift`,
  `src/AirPlay/`, `src/Diagnostics/`, `docs/`, `qa/`, journals other than
  `journal/<role>.md`, `scripts/`, `.opencode/`.

## Acceptance criteria

1. [ ] Given a `POST /pair-setup` request with TLV type 4 = A (the client's
       public key), when routed, then the response status is 200 and the TLV
       contains M2 (type 3, `SRP.nByteCount` bytes) and the salt (type 6,
       ≥ 16 bytes), and `HAPPairSetup.isStarted` is true (request 2 follows).
2. [ ] Given the client proof M4 = `H(A ‖ B ‖ K)` computed by the client from
       the response values (test client: `SRPTests.clientHandshake`,
       `test/SRPTests.swift:217`), when `HAPPairSetup.complete(clientM4:)` is
       called, then it returns `(M5, M6, K)`: M5 is the accessory proof
       `H(A ‖ M4 ‖ K)`, M6 is `K[0..<16]`, and the accessory K is byte-identical
       to the client K; `store.paired` is true.
3. [ ] Given a tampered M4, when `complete` is called, then it returns nil and
       `store.paired` stays false; the route answers 400 for it.
4. [ ] `HAPPairSetupTests` passes: `Executed 4 tests, with 0 failures` —
       `testStartReturnsTheAccessoryKeyAndTheSalt`,
       `testCompleteReturnsProofAndKeyAndMarksPaired`,
       `testCompleteReturnsNilWhenTheProofIsTampered`,
       `testRestartReusesTheStoredVerifier`.
5. [ ] `HAPServerTests` passes: `Executed 9 tests, with 0 failures` — the eight
       from TASK-017 plus `testRoutePostPairSetupStartsTheExchange`
       (request 1 → 200 with TLV type 3 and type 6; request 2 with a
       mismatched proof → 400, `server.pairingStore.paired` false).

## Verification commands

```sh
# on this host
ls play-two/src/HAP play-two/test
# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.2' | tee /tmp/opencode/task-018-test.log
grep -E "Test Suite '(HAPPairSetupTests|HAPServerTests|SRPTests)' (passed|failed)" /tmp/opencode/task-018-test.log
grep -E "Executed [0-9]+ tests?, with 0 failures" /tmp/opencode/task-018-test.log
```

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-018-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes: `R2` count ≥ 73 (expect ≈ 73 after the run; QA/BA update `qa/REGRESSION.md`)
- [ ] One commit `play-two/TASK-018: complete POST /pair-setup (SRP M1–M6) using the SRP primitives` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- Exchange shape — request 1: TLV type 4 = M1 (A, 32 bytes); response 1: TLV
  type 3 = M2 (B, `SRP.nByteCount` bytes), TLV type 6 = the salt the verifier
  was derived from. Request 2: TLV type 4 = M4 (the client proof); response 2:
  TLV type 5 = M5 (the accessory proof), TLV type 7 = M6 (the accessory
  session start, `K[0..<16]`). Assumption — no Home-app reference is available
  on this host; `FEAT-003`'s scope lists the endpoints, not the TLV types.
- `HAPPairSetup` persists the record on request 1
  (`HAPPairingStore.Record(salt: verifier: paired: false)`) and marks
  `paired: true` on a verified request 2 — that is the store half of
  `FEAT-003`'s "Pairing stored in the Keychain".
- SRP timings: `generateEphemeral` ~27 s, the verify round trip ~125 s
  (TASK-014). Run the heavy tests on `DispatchQueue.global()` with the
  `SRPTests` timeouts (300 s+ for the verify leg).
- TASK-019 adds the `POST /pair-verify` route; criteria 1–2 state the
  `POST /pair-setup` contract until then.
