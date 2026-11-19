# IDEA — PlayTwo — raw intake notes

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

## Requests added after G1 — 2026-11-16

Stated by the human while increment 1 was in the build loop. Not in the approved
SPEC v1.0; these become its next revision, and none of them changes increment 1.

- **Configurable advertised title.** The name the Apple TV shows should be
  editable in the app, not fixed to the product name or the phone's name.
- **A real control surface, still quiet.** Receiver on/off, what is playing, and
  where the audio is going. Minimal text, album art when the stream carries it,
  and a translucent "glass" treatment rather than a settings form.
- **Output picker.** Bluetooth speaker *or* the 3.5 mm jack — the 6s has one, so
  wired output is a first-class choice, not a fallback. Built-in speaker too.
- **Screen stays awake.** The receiver has to keep advertising and streaming, so
  the app may not let the display sleep while it is receiving.
- **App icon.** One recognisable icon; it is the only thing visible on the home
  screen of a phone that spends its life as a receiver.
- **AirPlay 2 must be the real thing.** Explicitly: "make sure we can make
  airplay 2 work with or like shairport-sync". shairport-sync's AirPlay 2 mode is
  the reference implementation to follow, not an approximation of it.

Constraints these run into, recorded so the next revision is honest:

| Request | Constraint |
| --- | --- |
| Glass UI | The 6s runs iOS 15.8.8. Apple's Liquid Glass is an iOS 26 design language and its APIs do not exist there. Translucency can be approximated with `ultraThinMaterial` / `UIVisualEffectView`, not reproduced. |
| Output picker | Route selection is system-owned. `AVRoutePickerView` is the sanctioned picker and works on iOS 15; enumerating and switching routes programmatically is limited. Bluetooth pairing itself stays in Settings. |
| Album art | Artwork arrives in the stream's metadata (increment 3+), not from the phone's library; it is absent for some senders and must degrade to a placeholder. |
| Screen awake | `UIApplication.shared.isIdleTimerDisabled` — small, but it belongs to the receiver's lifecycle, so it is specified with increment 2, not bolted on. |
| AirPlay 2 via shairport-sync | SPIKE-001 already accepted the reverse-engineered route. Following shairport-sync means its RTSP, HAP pairing and buffered-audio flow, which is increment 2's largest risk and deserves a second spike before any UI work. |
