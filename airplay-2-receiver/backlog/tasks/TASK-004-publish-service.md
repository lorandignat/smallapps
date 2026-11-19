---
id: TASK-004
title: Publish the _airplay._tcp service
feature: FEAT-001
status: proposed
attempts: 0
owner: null
depends_on: [TASK-002, TASK-003]
estimate: small
---

# TASK-004 — Publish the `_airplay._tcp` service

## Goal

Starting the receiver publishes one Bonjour service instance of type
`_airplay._tcp` on port 7000, under the app's name, carrying the TXT record from
TASK-002 — the thing the Apple TV browses for.

## Context for the developer

- Where it lives: `src/Net/ServiceAdvertiser.swift`
- Interfaces it may touch: `AirPlayTXTRecord` and `DeviceIdentity` (TASK-002),
  `ReceiverListener` and its fixed response (TASK-003), `AppInfo.displayName`
  (TASK-001). You may add a `service` property to `ReceiverListener`; you may not
  change its response bytes.
- Files in scope (2): the source above plus `test/ServiceAdvertiserTests.swift`
- One `NWListener` carries both the service registration and the TCP port
  (`docs/STACK.md`: `Network.framework`, no dependencies). No `NetService`, no
  multicast socket code.
- Explicitly **do not** touch: `project.yml`, `src/AirPlay/`,
  `src/AirPlayReceiverApp.swift`, `src/ContentView.swift`, `docs/`, `qa/`,
  `journal/`, `scripts/`, `.opencode/`.

## Acceptance criteria

1. [ ] Given a valid device id, when the advertiser starts, then its listener's
       service is `type == "_airplay._tcp"`, `name == AppInfo.displayName`
       (`AirPlay Receiver`), and its TXT values equal the TASK-002 record.
2. [ ] Given the advertiser starts, when 2 seconds pass, then its published
       state is `.advertising` and no crash occurred.
3. [ ] Given a name longer than 63 UTF-8 bytes, when the advertiser starts, then
       it reports `.failed` with a message containing `63` and publishes nothing
       truncated.
4. [ ] Given the app is running on the simulator and the Mac is reachable, when
       `dns-sd -B _airplay._tcp .` runs for 5 seconds on the Mac, then it prints
       one instance named `AirPlay Receiver`, not zero and not two.
5. [ ] `ServiceAdvertiserTests` passes: `Executed 3 tests, with 0 failures`.

## Verification commands

```sh
# on this host
ls airplay-2-receiver/src/Net
grep -n '_airplay._tcp' airplay-2-receiver/src/Net/ServiceAdvertiser.swift

# on the Mac (expected BLOCKED until QQ-005 resolves)
rsync -a <project> <build-host>:<build-dir>/ airplay-2-receiver
xcodegen generate
xcodebuild test airplay-2-receiver AirPlayReceiver 'platform=iOS Simulator,name=iPhone 16' | tee /tmp/opencode/task-004-test.log
grep -E "Test Suite 'ServiceAdvertiserTests' (passed|failed)" /tmp/opencode/task-004-test.log

# on the Mac, with the app running in the simulator: criterion 4
dns-sd -B _airplay._tcp . > /tmp/ap2-browse.txt & BP=$!; sleep 5; kill $BP; cat /tmp/ap2-browse.txt
```

**Expected today:** every build line is `BLOCKED` until the Mac is
configured (`QQ-005`); `dns-sd` output is empty or the command errors. An empty
browse is **not** a `PASS` for criterion 4 and **not** a `FAIL` of the code: it
is `BLOCKED` with the reason recorded.

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-004-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes
- [ ] One commit `airplay-2-receiver/TASK-004: publish the _airplay._tcp service` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- Criterion 4 is the increment-1 kill-switch in its cheapest form: it proves the
  service reaches the LAN without needing the Apple TV. If Bonjour registration
  does not work from the simulator, say so in the review as `BLOCKED` with the
  error; the device check (S1b) is the fallback and belongs to the BA, not to
  this task — installing on the 6s needs signing (`QQ-005`).
- Do not add `NWListener` parameters for interface scoping or Bonjour domains in
  this task. Default `.any` interface, default domain, one instance.
- TASK-006 owns stopping this advertiser; do not wire SwiftUI lifecycle here.
