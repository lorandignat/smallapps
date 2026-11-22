---
id: TASK-017
title: Expose the pairing state in the pairing store
feature: FEAT-003
status: proposed
attempts: 0
owner: null
depends_on: [TASK-016]
estimate: small
---

# TASK-017 — Expose the pairing state in the pairing store

## Goal

The accessory exposes its pairing state. `HAPPairingStore` holds the
`HAPPairingStore.Record` (`salt`, `verifier`, `paired`), `GET /info` reports
`paired` from it, and a new store instance on the same service reloads the
record from the Keychain — the restart-survival read (restart survival half 1;
the screen half is TASK-021).

## Context for the developer

- Where it lives: `src/HAP/HAPPairingStore.swift` (new), `src/HAP/HAPServer.swift`
  (modified), `src/HAP/HAPServer.swift`'s route (modified).
- Interfaces it may touch: `HAPPairingStore` (new API: `shared`, `service`,
  `record`, `salt`, `verifier`, `paired`, `save`, `delete`, static
  `defaultService`), `HAPServer.init(pairingStore:)`, `HAPServer.route`'s
  `GET /info` response, `HAPPairingStore.Record`.
- Files in scope (4): `src/HAP/HAPPairingStore.swift` (new), `test/HAPPairingStoreTests.swift`
  (new), `src/HAP/HAPServer.swift` (modified), `test/HAPServerTests.swift` (modified).
- Explicitly **do not** touch: `project.yml`, `src/PlayTwoApp.swift`,
  `src/ContentView.swift`, `src/Net/`, `src/HAP/HAPServer.swift` except the
  `pairingStore` init/route change above (same file — the scope line covers
  exactly the `init` and the `GET /info` body), `src/HAP/SRP.swift`,
  `src/HAP/TLV8.swift`, `src/HAP/AccessoryIdentity.swift`, `src/AirPlay/`,
  `src/Diagnostics/`, `docs/`, `qa/`, journals other than `journal/<role>.md`,
  `scripts/`, `.opencode/`.

## Acceptance criteria

1. [ ] Given `HAPPairingStore.Record(salt: 16 bytes, verifier: 384 bytes,
       paired: false)` saved, when a new store instance is created on the same
       service, then `record` is equal to the saved record and `paired` is
       false (the reload proves persistence).
2. [ ] Given a saved record with `paired: true`, when a new store instance is
       created (the relaunch), then `paired` is true (restart survival).
3. [ ] Given `HAPPairingStore.shared`, when `GET /info` routes, then the body
       contains `"paired": false` while no record is saved (TASK-018 marks
       true).
4. [ ] `HAPPairingStoreTests` passes: `Executed 5 tests, with 0 failures` —
       `testFreshStoreHasNoRecordAndIsUnpaired`, `testSaveAndReloadAcrossInstances`,
       `testPairedStateReloadsAcrossInstances`, `testSaveReplacesTheRecord`,
       `testDeleteClearsTheRecord`.
5. [ ] `HAPServerTests` passes: `Executed 8 tests, with 0 failures` — the seven
       from TASK-016 plus `testInfoReportsThePairedStateFromTheStore`
       (`HAPPairingStore(service: unique)` saves `paired: true`;
       `HAPServer(pairingStore: store).route(GET /info)` body contains `"paired": true`).

## Verification commands

```sh
# on this host
ls play-two/src/HAP play-two/test
# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.2' | tee /tmp/opencode/task-017-test.log
grep -E "Test Suite '(HAPServerTests|HAPPairingStoreTests)' (passed|failed)" /tmp/opencode/task-017-test.log
```

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-017-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes: `R2` count ≥ 68 (expect ≈ 68 after the run; QA/BA update `qa/REGRESSION.md`)
- [ ] One commit `play-two/TASK-017: expose the pairing state in the pairing store` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- Keychain shape mirrors `AccessoryIdentity` (service + account,
  `kSecClassGenericPassword`, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`);
  the record is stored as JSON in `kSecValueData`.
- `HAPPairSetup` (TASK-018) is the first writer of the record and the first
  setter of `paired = true`; until then `paired` reads false.
- `HAPPairSetup` (TASK-018) saves its record on `POST /pair-setup` request 1;
  TASK-020 advertises `paired` in the TXT record from the same store.
