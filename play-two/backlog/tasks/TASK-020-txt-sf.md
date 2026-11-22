---
id: TASK-020
title: Advertise the paired status in the AirPlay TXT record
feature: FEAT-003
status: proposed
attempts: 0
owner: null
depends_on: [TASK-017]
estimate: small
---

# TASK-020 — Advertise the paired status in the AirPlay TXT record

## Goal

The AirPlay TXT record gains `sf` (the HAP-style status flags; bit 0 set when
the accessory is paired), and `ServiceAdvertiser` builds the record with the
state from the pairing store — so after a relaunch the Apple TV sees the
paired status with no re-pair prompt (restart survival, half 1).

## Context for the developer

- Where it lives: `src/AirPlay/AirPlayTXTRecord.swift` (modified),
  `src/Net/ServiceAdvertiser.swift` (modified).
- Interfaces it may touch: `AirPlayTXTRecord.init(deviceID:)` (adds the
  `paired` parameter), `AirPlayTXTRecord.dictionary` (adds `"sf"`),
  `AirPlayTXTRecord.statusFlagPaired`/`statusFlagString` (new),
  `HAPPairingStore.shared.paired` (TASK-017).
- Files in scope (4): `src/AirPlay/AirPlayTXTRecord.swift` (modified),
  `src/Net/ServiceAdvertiser.swift` (modified), `test/AirPlayTXTRecordTests.swift`
  (modified), `test/ServiceAdvertiserTests.swift` (modified).
- Explicitly **do not** touch: `project.yml`, `src/PlayTwoApp.swift`,
  `src/ContentView.swift`, `src/HAP/HAPServer.swift`, `src/HAP/HAPPairSetup.swift`,
  `src/HAP/HAPPairVerify.swift`, `src/HAP/HAPPairingStore.swift`, `src/HAP/AccessoryIdentity.swift`,
  `src/HAP/TLV8.swift`, `src/HAP/SRP.swift`, `src/Diagnostics/`, `docs/`, `qa/`,
  journals other than `journal/<role>.md`, `scripts/`, `.opencode/`.

## Acceptance criteria

1. [ ] Given the accessory is unpaired, when `ServiceAdvertiser.start()`
       builds the TXT record, then `AirPlayTXTRecord(deviceID: "0A:1B:2C:3D:4E:5F",
       paired: false).dictionary["sf"] == "0"` and `AirPlayTXTRecordTests.testPairedStatusAppearsInTheSFFlag`
       passes (the record dictionary always has the key `"sf"`).
2. [ ] Given `AirPlayTXTRecord(deviceID: "0A:1B:2C:3D:4E:5F", paired: true)`,
       when the record is built, then `dictionary["sf"] == "1"` and
       `statusFlags & AirPlayTXTRecord.statusFlagPaired != 0`;
       `dictionary["sf"] == "0"` for the default `paired: false`.
3. [ ] `AirPlayTXTRecordTests` passes: `Executed 8 tests, with 0 failures` —
       the seven from TASK-019 plus `testPairedStatusAppearsInTheSFFlag`
       (also `XCTAssertEqual(Set(dictionary.keys), ["deviceid", "features",
       "model", "srcvers", "sf", "vv"])` in `testTXTRecordHasTheRequiredKeysAndValues`
       with `XCTAssertEqual(dictionary["sf"], "0")`).
4. [ ] `ServiceAdvertiserTests` passes: `Executed 9 tests, with 0 failures` —
       `testStartPublishesTheAirPlayServiceForAValidDeviceID` now asserts the
       dictionary with the extra `"sf": "0"` entry (`HAPPairingStore.shared`
       has no record in the test run, so the value is `"0"`); the other eight
       unchanged.
5. Regression: `R2` count ≥ 79 (expect ≈ 79 after the run; QA/BA update `qa/REGRESSION.md`).

## Verification commands

```sh
# on this host
ls play-two/src/AirPlay play-two/src/Net play-two/test
# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.2' | tee /tmp/opencode/task-020-test.log
grep -E "Test Suite '(AirPlayTXTRecordTests|ServiceAdvertiserTests)' (passed|failed)" /tmp/opencode/task-020-test.log
grep -E "Executed [0-9]+ tests?, with 0 failures" /tmp/opencode/task-020-test.log
```

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-020-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes: `R2` count ≥ 79 (expect ≈ 79 after the run; QA/BA update `qa/REGRESSION.md`)
- [ ] One commit `play-two/TASK-020: advertise the paired status in the AirPlay TXT record` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- `sf` value form: the flags as a hex string, always present — `"0"` (unpaired,
  the default), `"1"` (`statusFlagPaired` = bit 0, the HAP-style pairing
  status flag).
- `AirPlayTXTRecord` stays `Equatable` with the new `statusFlags` field;
  `ServiceAdvertiserTests.testStartPublishesTheAirPlayServiceForAValidDeviceID`
  and `testTXTRecordRoundTripsThroughNWTXTRecord` are updated for the new key.
- Restart half of survival: `ServiceAdvertiser.start()` reads
  `HAPPairingStore.shared.paired` at start time; the other half (the screen) is
  TASK-021.
- `AirPlayTXTRecordTests` R8 still pins the `features` constant — the `sf`
  change adds a key to `testTXTRecordHasTheRequiredKeysAndValues` only.
