---
id: TASK-002
title: Build the AirPlay TXT record from a stable device id
feature: FEAT-001
status: proposed
attempts: 0
owner: null
depends_on: [TASK-001]
estimate: small
---

# TASK-002 — Build the AirPlay TXT record from a stable device id

## Goal

The app has one stable AirPlay device identity and produces the `_airplay._tcp`
TXT record from it: same device id on every launch, and a key/value set that
encodes and decodes unchanged.

## Context for the developer

- Where it lives: `src/AirPlay/DeviceIdentity.swift`, `src/AirPlay/AirPlayTXTRecord.swift`
- Interfaces it may touch: `AppInfo.displayName` (TASK-001), read only
- Files in scope (3): the two sources above plus `test/AirPlayTXTRecordTests.swift`
- No `project.yml` change: the app target's `sources: [src]` already picks up
  `src/AirPlay/`, and the test target's `[test]` picks up the new test file.
- Explicitly **do not** touch: `project.yml`, `src/AirPlayReceiverApp.swift`,
  `src/ContentView.swift`, `docs/`, `qa/`, `journal/`, `scripts/`, `.opencode/`,
  and any file owned by another role.

## Acceptance criteria

1. [ ] Given an install with no stored identity, when `DeviceIdentity.current` is
       read twice in the same process, then both reads return the identical
       17-character `AA:BB:CC:DD:EE:FF` string and exactly one value is stored
       under the fixed `UserDefaults` key.
2. [ ] Given device id `0A:1B:2C:3D:4E:5F`, when `AirPlayTXTRecord(deviceID:)` is
       built, then its keys are exactly `deviceid`, `features`, `model`,
       `srcvers`, `vv`; `deviceid` equals the input; `vv` is `2`; `features`
       parses as a 64-bit hex value with bit 38 set.
3. [ ] Given a record, when it is encoded with `NWTXTRecord` and decoded again,
       then every value round-trips unchanged (no truncation, no case change).
4. [ ] Given an empty string or a malformed device id, when
       `AirPlayTXTRecord(deviceID:)` is called, then it returns `nil` and no
       record is produced — the caller must treat it as `status .failed` later.
5. [ ] `AirPlayTXTRecordTests` passes: `Executed 5 tests, with 0 failures`.

## Verification commands

```sh
# on this host: the files exist and no dependency was added
ls airplay-2-receiver/src/AirPlay airplay-2-receiver/test
grep -c 'packages:' airplay-2-receiver/project.yml   # expected: 0

# on the Mac (expected BLOCKED until QQ-005 resolves)
rsync -a <project> <build-host>:<build-dir>/ airplay-2-receiver
xcodegen generate
xcodebuild test airplay-2-receiver AirPlayReceiver 'platform=iOS Simulator,name=iPhone 16' | tee /tmp/opencode/task-002-test.log
grep -E "Test Suite 'AirPlayTXTRecordTests' (passed|failed)" /tmp/opencode/task-002-test.log
grep -E "Executed [0-9]+ tests?, with 0 failures" /tmp/opencode/task-002-test.log
```

**Expected today:** `xcodebuild test` is `BLOCKED` until the Mac is configured
(`QQ-005`). The `ls`/`grep` checks are the only evidence available on this host
and are not a substitute for a `PASS`.

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-002-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes
- [ ] One commit `airplay-2-receiver/TASK-002: build the AirPlay TXT record from a stable device id` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- The device id is **generated once**, not read from hardware: iOS hides the MAC
  address. A random 48-bit value persisted in `UserDefaults` is enough for
  discovery and is deliberately not the HAP identity (that arrives with pairing,
  increment 2). Do not add Keychain work here.
- `features` bit 38 (AP2 audio receiver) is taken from the reference
  implementations named in `docs/SPIKE-001-airplay2.md`. Put the source in a code
  comment next to the constant. If the tester finds the value must change for the
  Apple TV to list us, that is a correction inside this task, not a new task.
- The TXT record carries no name: the name is the Bonjour service instance name
  (TASK-004). Do not duplicate it into the TXT record.
