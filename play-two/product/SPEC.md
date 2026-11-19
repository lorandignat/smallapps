# SPEC — PlayTwo

Owner: `ba`. Status: `approved` at G1 on 2026-11-15. A change to any section
after approval needs a new G1 approval and a `DEC-###`.

- **Version:** 1.0
- **Date:** 2026-11-15
- **Platform:** iOS 15.0, iPhone 6s (`docs/STACK.md`)
- **One-liner:** An old iPhone becomes AirPlay 2 speaker for an Apple TV, playing
  through a Bluetooth speaker.

## 1. Problem

An iPhone 6s and a Bluetooth speaker are already on the shelf, and the Apple TV
can only send audio to a licensed AirPlay 2 accessory or to the TV. Nothing in
that setup lets the TV's audio come out of the better speaker, and the phone
cannot be an AirPlay target without an app that speaks the protocol.

Buying an AirPort Express or a modern AirPlay 2 speaker adapter solves the sound
problem with money and no project. It does not reuse the phone, and it caps out
at the same single-stream behaviour. The reason to build instead is that the
protocol is understood — five independent software receivers exist — and no iOS
implementation does. That is also the reason this is a research-grade product
rather than a weekend app, and `DEC-001` accepts that.

## 2. Primary user

One person: the owner, at home, with an iPhone 6s that is no longer their daily
phone, an Apple TV, and a Bluetooth speaker. Technically comfortable with
sideloading, able to run a command on a Mac, and aware that the app is not in the
App Store and never will be. Will not tolerate: audio that drops mid-album, an
app that has to be watched, or a setup that takes longer than turning the speaker
on.

## 3. Core flow (v1)

1. The speaker is switched on and already paired with the phone; the phone is
   plugged in and the app is running.
2. On the Apple TV, the phone appears in the list of AirPlay speakers under the
   name chosen in the app.
3. Selecting it starts the stream: the TV's audio comes out of the Bluetooth
   speaker.
4. Audio keeps playing for a full listening session — pause, resume, track
   changes, TV sleep — without reopening the app.
5. When the session ends and the phone is left alone, the phone is still offered
   as a speaker the next time.

## 4. Scope — v1

v1 is increment 4 of `DEC-002`. Each increment is a kill-switch: it is built,
demonstrated, and only then is the next one specified.

| Increment | In scope | Demonstrated by |
| --- | --- | --- |
| 1. Discoverable | App publishes an AirPlay 2 receiver service and a TCP endpoint; a name; a visible state screen. No pairing, no audio. | The phone appears in the Apple TV's speaker list while the app is in the foreground. |
| 2. Pairable | HAP pairing (SRP-3072, Ed25519, TLV8) so the device can be added in the Home app on iOS 15.3. | The Home app completes "Add Accessory" and lists the phone as a speaker. |
| 3. Audible | RTSP setup, FairPlay v3 handshake and key decryption, buffered audio, ALAC decode, playback through the phone's own speaker. | An Apple TV stream plays, in sync with itself, on the phone speaker. |
| 4. Useful | Audio routed to the paired Bluetooth speaker; the app keeps the receiver alive while backgrounded and the screen is off. | A full listening session from the Apple TV with the app never brought to the foreground. |

| Also in v1 | Why |
| --- | --- |
| A settings screen for the advertised name | Otherwise every phone in the house is "iPhone" in the Apple TV list. |
| A log view exportable to a file | Nothing about this protocol can be debugged from a screenshot; QA needs evidence. |
| Clean shutdown of the advertisement on app exit | A ghost entry in the Apple TV list is the most common complaint about software receivers. |

## 5. Non-goals — v1

| Out of scope | Why it can wait |
| --- | --- |
| Multi-room grouping with the Apple TV's own output | Bluetooth latency and jitter break AP2's sub-millisecond sync. Physics, not effort (`DEC-002`). |
| Screen mirroring, video, HLS | Audio only. A different, much larger protocol surface. |
| AirPlay 1 senders | v1 targets the Apple TV, which speaks AP2. AP1 compatibility is a separate feature. |
| App Store, TestFlight, distribution of any kind | FairPlay key material makes this personal-use, sideload-only (`DEC-001`). |
| Home app control beyond adding the accessory | Volume/playback control from the Home app is a nice-to-have that follows pairing, not a v1 criterion. |
| Android, iPad, Mac, tvOS clients | Not the device in the problem statement. |
| Handling multiple concurrent senders | One Apple TV, one stream; concurrency is a later feature. |

## 6. Success criteria

Each is checked by the increment that owns it, and only then counts.

- [ ] **S1.** With the app foregrounded, the iPhone appears in the Apple TV's
      AirPlay speaker list within 30 seconds of launch, under the configured
      name, and disappears within 30 seconds of the app being killed.
- [ ] **S2.** The phone completes Home app "Add Accessory" on iOS 15.3 and
      appears there as a speaker; the pairing survives an app restart.
- [ ] **S3.** Audio from an Apple TV stream is decrypted and played on the phone's
      own speaker without dropping for 10 continuous minutes.
- [ ] **S4.** With the Bluetooth speaker connected, audio plays from it, and the
      app keeps receiving for 30 minutes with the screen off and the app
      backgrounded.
- [ ] **S5.** After a failed connection (Apple TV selects the phone, then the
      phone's app is killed), the next launch advertises again with no stale
      entry left behind.

S1-S5 are observable. Nothing in this list is "feels responsive" or "works well".

## 7. Constraints

- **One device, one OS:** iPhone 6s, iOS 15.x, A9. No newer-OS APIs. No
  simulator-only behaviour may be relied on.
- **Sideload lifetime:** 7-day provisioning with a free Apple ID, one year with a
  paid account. The app must survive being reinstalled without losing its
  identity (pairing keys are stored in the Keychain and exported).
- **Legal:** FairPlay key tables are Apple DRM material. The app is never
  distributed, never uploaded, never shared. This is a hard constraint, not a
  preference.
- **Network:** the phone and the Apple TV are on the same IPv4 LAN. No cloud
  services, no accounts, no telemetry.
- **Power:** the phone is assumed plugged in; no battery-efficiency target in v1.
- **Latency:** ~100-300 ms of Bluetooth output latency is acceptable for music.
  It is not compensated in v1, and lip-sync is explicitly not a goal.
- **No paid services or credentials** are introduced by the agents. Signing
  setup is done once by the human in Xcode.
- **Everything stays in this folder:** sources here, builds on the Mac's scratch
  directory, installs only on the owner's phone.

## 8. Open questions

- `QQ-003` — personal use assumed (that is what `DEC-001` accepted). If this ever
  becomes something to share, the FairPlay constraint ends the project.
- `QQ-005` — Mac configuration: host, user, key install, Xcode opened once.
  Nothing is verifiable until `xcodebuild -version` passes.

Neither blocks writing increment 1's spec or design; both block claiming a PASS.

## 9. Approval

- [x] Human approved at G1 on 2026-11-15 (SPEC v0.1 approved as v1.0; stack in `docs/STACK.md` approved in the same gate)
