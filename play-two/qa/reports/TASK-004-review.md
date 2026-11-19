---
id: TASK-004-review
task: TASK-004
feature: FEAT-001
verdict: PASS
date: 2026-11-19
attempt: 2
---

# Review — TASK-004 Publish the `_airplay._tcp` service

Attempt 2. Attempt 1 was blocked on the device (the 6s held a 169.254 address and
published nothing); the rework changed two things: the app now declares
`NSLocalNetworkUsageDescription` and `NSBonjourServices` in `project.yml`, and a
policy-denied registration surfaces as `.failed` instead of staying
`.advertising`. This review covers attempt 2.

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | App starts the advertiser at launch | **PASS** | `PlayTwoApp.swift` constructs `ServiceAdvertiser()` and calls `advertiser.start()` in `init()`; the advertiser drives `ReceiverListener` with a service attached. Simulator test `testStartPublishesTheAirPlayServiceForAValidDeviceID` passes: listener service type `_airplay._tcp`, name `PlayTwo`, TXT record matches. |
| 2 | `dns-sd -B _airplay._tcp` shows one `PlayTwo` on the 6s | **PASS** | Browse from the Mac: `PlayTwo` appears exactly once among the receivers; `dns-sd -L PlayTwo _airplay._tcp local` resolves to `<device>.local.:7000` (interface 14). A second iPhone sees PlayTwo in its AirPlay picker. |
| 3 | Port is 7000 (default) | **PASS** | Resolves to port 7000; `nc -vz <device-ip> 7000` succeeds. `DEC-011` default held. |
| 4 | Simulator suite green | **PASS** | `Executed 17 tests, with 0 failures` (log `20261119T180911Z-test.log`). 13 from TASK-003 + 4 `ServiceAdvertiserTests`. |
| 5 | Plist keys present in built app | **PASS** | `plutil -p` on `PlayTwo.app/Info.plist`: `NSBonjourServices` = `["_airplay._tcp"]`, `NSLocalNetworkUsageDescription` present. |
| 6 | Policy-denied registration reports `.failed` | **PASS** | `testPolicyDeniedRegistrationFailsInsteadOfStayingAdvertising` passes: `.listening` → `.advertising`, then `.failed(.dns(-72008))` → `.failed` with message containing "Local Network" and "denied". |

## Regressions

R1–R8 run. R2 high-water mark updated 13 → 17 (4 new `ServiceAdvertiserTests`).
R4's app-level half (port 7000) is now verified: `nc <device-ip> 7000` succeeds.

## Verdict: PASS

All criteria verified. The root cause of attempt 1's silence was the missing
local-network declarations; the fix is in the tree and proven on the device.