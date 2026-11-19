---
id: TASK-004
title: Publish the _airplay._tcp service
feature: FEAT-001
status: approved
attempts: 0
owner: developer
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
- Files in scope (3): the source above, `src/PlayTwoApp.swift` and
  `test/ServiceAdvertiserTests.swift`
- `src/PlayTwoApp.swift` is in scope for **one** purpose: construct the advertiser
  once at launch and start it, holding it for the app's lifetime, so the app
  process actually publishes. Displaying its state is TASK-005 (which owns
  `ContentView`); foreground/background transitions are TASK-006. Build neither
  here.
- One `NWListener` carries both the service registration and the TCP port
  (`docs/STACK.md`: `Network.framework`, no dependencies). No `NetService`, no
  multicast socket code.
- Explicitly **do not** touch: `project.yml`, `src/AirPlay/`,
  `src/ContentView.swift`, `docs/`, `qa/`, journals other than `journal/<role>.md`,
  `scripts/`, `.opencode/`.

## Acceptance criteria

1. [ ] Given a valid device id, when the advertiser starts, then its listener's
       service is `type == "_airplay._tcp"`, `name == AppInfo.displayName`
       (`PlayTwo`), and its TXT values equal the TASK-002 record.
2. [ ] Given the advertiser starts, when 2 seconds pass, then its published
       state is `.advertising` and no crash occurred.
3. [ ] Given a name longer than 63 UTF-8 bytes, when the advertiser starts, then
       it reports `.failed` with a message containing `63` and publishes nothing
       truncated.
4. [ ] Given the signed app has been installed and launched on the iPhone 6s by
       the commands below and the Mac is on the same network, when
       `dns-sd -B _airplay._tcp .` runs for 5 seconds on the Mac, then it prints
       exactly one instance named `PlayTwo`, not zero and not two (`DEC-012`).
5. [ ] `ServiceAdvertiserTests` passes: `Executed 3 tests, with 0 failures`.

## Verification commands

```sh
# on this host
ls play-two/src/Net
grep -n '_airplay._tcp' play-two/src/Net/ServiceAdvertiser.swift
grep -n 'ServiceAdvertiser' play-two/src/PlayTwoApp.swift

# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.5' | tee /tmp/opencode/task-004-test.log
grep -E "Test Suite 'ServiceAdvertiserTests' (passed|failed)" /tmp/opencode/task-004-test.log

# on the Mac: criterion 4 — signed build, install on the 6s, launch, browse, count
# (the simulator cannot bind 7000: macOS ControlCenter holds it, DEC-012)
xcodebuild build -scheme PlayTwo -sdk iphoneos
ios-deploy --bundle build/Build/Products/Debug-iphoneos/PlayTwo.app --id <udid>
export PATH=/opt/homebrew/bin:$PATH; ios-deploy --bundle "play-two/build/Build/Products/Debug-iphoneos/PlayTwo.app" --id <udid> --justlaunch
sleep 5   # the phone must be unlocked and the app in the foreground
dns-sd -B _airplay._tcp . > /tmp/ap2-browse.txt & BP=$!; sleep 5; kill $BP; cat /tmp/ap2-browse.txt
grep "_airplay\._tcp\." /tmp/ap2-browse.txt | grep -c "PlayTwo"
```

**Toolchain note:** the Mac moved to Xcode 27.2 on 2026-11-19 and its simulator
is `iPhone 16e` on iOS 26.5, so the destination carries `OS=26.5`; without it
`latest` resolves to a runtime the simulator does not have. Xcode 27 also ships
no iOS 15 developer disk image, which `ios-deploy --justlaunch` needs: without
one it stops at `Unable to locate DeviceSupport directory with suffix
'DeveloperDiskImage.dmg'`. The image is installed on this Mac, so the command
above works; if it ever stops working, launching by tapping the icon is the
fallback and gives the same app state. Criterion 4 also
needs the phone on the same LAN as the Mac — a self-assigned `169.254` address
means it is not, and the browse will be empty whatever the code does.

**Expected today:** the Mac bridge is proven (`QQ-005`, closed), so every
build line runs and the suite is green. Criterion 4 runs on the phone
(`DEC-012`), because the simulator cannot bind 7000 — macOS ControlCenter keeps
it. A green run is one `Add` line for `_airplay._tcp.` whose instance name is
`PlayTwo`, and the count command prints `1`. An empty browse is **not** a `PASS`
and **not** a `FAIL` of the code: it is `BLOCKED` with the reason recorded —
signing expired, the phone locked, the app backgrounded, or the Mac and phone on
different networks are all reasons, and they belong in the review, not fixed
here. The verification path is only as good as the profile: it expires
2026-11-23.

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-004-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes
- [ ] One commit `play-two/TASK-004: publish the _airplay._tcp service` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- Criterion 4 is the increment-1 kill-switch in its cheapest form: it proves the
  service reaches the LAN without needing the Apple TV. It runs on the 6s
  (`DEC-012`), because the simulator cannot bind 7000. Device signing is the
  human's free Apple ID (`DEC-008`, `QQ-008`); if the profile has expired, say so
  as `BLOCKED` and the BA rebuilds rather than the developer working around it.
- Do not add `NWListener` parameters for interface scoping or Bonjour domains in
  this task. Default `.any` interface, default domain, one instance.
- TASK-006 owns stopping this advertiser; do not wire SwiftUI lifecycle here.
