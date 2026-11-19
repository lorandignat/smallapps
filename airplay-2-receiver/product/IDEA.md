# IDEA — AirPlay 2 Receiver — raw intake notes

Owner: `ba`. Scratchpad for the human's words. Not a contract; `SPEC.md` is.

## Session 1 — 2026-11-15

**What they said:**

> I want to turn my iPhone 6s into an airplay 2 receiver that can forward the
> sound to bluetooth speaker. I want airplay 2 because that can be added to apple
> home, connected to apple tv, and multiple devices can be connected to apple tv.
> There is a reference project https://github.com/neon443/AirAP/tree/main/AirAP,
> but this is airplay 1.

**What I heard:**

- Device: an iPhone 6s, used as a fixed receiver → Bluetooth speaker.
- Sender: Apple TV (and anything else that can pick an AirPlay target).
- The reason for *AirPlay 2* specifically: Home app integration, Apple TV output
  selection, multi-room grouping.
- Known prior art: AirAP, which is AirPlay **1** (Swift, shairplay-based, App
  Store/TestFlight, appears as an AirPlay destination).

**Facts that constrain the product**

| Fact | Consequence |
| --- | --- |
| iPhone 6s stops at iOS 15.x | Whatever we build must run on iOS 15 and A9 hardware. Modern AudioToolbox features and newer Swift concurrency tooling may not be available. |
| AirPlay 1 (AirAP) is a solved problem in software | A receiver that appears in the AirPlay menu without Apple certification is achievable today, single-stream only. |
| AirPlay 2 adds buffered audio, HomeKit pairing, multi-room grouping | The Home-app and "group with Apple TV" requirements come from AirPlay 2, not from the audio transport itself. |
| AirPlay 2 receiver support is licensed for hardware (MFi) | Software receivers exist only as reverse-engineered implementations (e.g. shairport-sync's AirPlay 2 mode, community emulators of the auth chip). Fragile, and not App Store material. |
| Bluetooth output adds latency | Fine for music playback, fatal for lip-sync and for AirPlay 2's tight multi-room synchronisation. |
| An iOS app cannot be a *system* AirPlay target | Only licensed accessory software shows up everywhere; a sideloaded app must advertise and handle pairing itself. |

**Assumptions to confirm:** personal use on their own 6s vs. something to
distribute; whether AirPlay 1 is an acceptable v1; whether the phone may be
jailbroken or sideloaded.

**Rejected / out of scope:** none yet.
