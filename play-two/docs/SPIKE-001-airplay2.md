# SPIKE-001 — can an iPhone 6s be an AirPlay 2 receiver?

- **Owner:** ba
- **Status:** done — evidence pass 2 complete, recommendation below, `DEC-001`
  pending the human's call
- **Timebox:** two working sessions (used: two)
- **Blocks:** G1 for `play-two`

## The question

Can a sideloaded iOS app on iOS 15 (iPhone 6s) act as an AirPlay 2 receiver — be
discoverable and pairable, accept an AirPlay 2 stream from an Apple TV, appear in
the Home app, and forward the audio to a Bluetooth speaker?

Four sub-questions, because they fail independently:

| # | Question | Verdict |
| --- | --- | --- |
| Q1 | AirPlay 2 receiving without MFi hardware? | **Yes** — five independent implementations, all software |
| Q2 | Inside an iOS 15 app on a 6s? | **No public proof.** Would be a first-of-kind port |
| Q3 | Home app entry and Apple TV grouping? | **Yes** — proven on iOS 15.3 with an uncertified software receiver |
| Q4 | Bluetooth output? | **Works, but no meaningful multi-room sync** |

## Evidence

| Source | Finding | Answers |
| --- | --- | --- |
| shairport-sync (C) `AIRPLAY2.md` | Full AP2 receiver: realtime and buffered audio, ALAC/AAC, 16/24-bit, 44.1/48 kHz, stereo to 7.1, synchronised playback with other AP2 devices, sources include iOS and Apple TV. | Q1 yes |
| shairport-sync `ADDINGTOHOME.md` | A **software** AP2 receiver, no MFi chip, can be added to the **Home app on iOS 15.3** and then appears as a speaker. Step-by-step, with screenshots. | Q3 yes, on our exact target OS |
| openairplay/airplay2-receiver (Python, 2.4k★) | HAP transient and non-transient pairing (SRP/Curve25519/ChaCha20-Poly1305), FairPlay v3 authentication and AES key decryption, AP2 service publication, all AP2 codecs, some multi-room. States MFi auth may never be implemented. | Q1 yes, Q3 yes |
| openairplay/goplay2 (Go, 424★), rairplay (Rust), java-airplay (Java), esphome-airplay2 (ESP32) | The protocol is understood well enough to reimplement repeatedly, in several languages and on microcontrollers. | Q1 yes — not a one-off hack |
| AirAP (Swift, iOS) | Native AirPlay **1** server inside an iOS app; ships via TestFlight; appears in AirPlay menus. | Q2 partial: the app shape is proven, AP2 is not |
| `ap2/fairplay3.py` (654 KB) | FairPlay decryption is implemented as **key tables**, not as a licensed API. This is the load-bearing dependency, and it is extracted DRM material. | Q2 blocker |
| No repository found | Search for Swift/Objective-C AirPlay 2 receivers returns nothing. Not one public iOS implementation. | Q2: unproven, and nobody has published an attempt |

## Verified answers

**Q1 — yes.** AirPlay 2 receiving is reverse-engineerable software. MFi is
required for *certified products*, not for the protocol. Five implementations
disagree with the "impossible without Apple" framing.

**Q3 — yes, and better than expected.** shairport-sync documents adding a
software AP2 receiver to the Home app on iOS 15.3, and it then behaves as a
speaker. Home app entry does not require certification; it requires correct HAP
pairing. That removes the objection that killed the AirPlay 1 fallback for your
stated use case.

**Q4 — works, with a caveat.** Audio out to Bluetooth is ordinary
`AVAudioSession` work. Multi-room synchronisation uses PTP timing with
sub-millisecond targets; Bluetooth adds 100-300 ms with jitter. A BT speaker can
follow a single stream, but grouping it with the Apple TV's own output will drift.
Synced multi-room is only credible through the phone's own speaker.

**Q2 — this is the whole risk.** Nothing proves an AP2 receiver can run inside an
iOS app. Three specific unknowns:

1. **FairPlay key material.** Every implementation ships extracted key tables.
   Anyone can technically embed the same tables in an iOS app, but that is
   circumvention of Apple's DRM: not App Store material, legally exposed to
   distribute, and Apple can invalidate it. Personal sideload use is the only
   defensible context.
2. **Background execution.** A receiver must answer discovery and pairing while
   idle. iOS suspends apps that are not actively playing audio. The usual
   workaround is a silent audio session, which Apple has rejected in review and
   which is fragile across iOS versions. AirAP lives on TestFlight for related
   reasons.
3. **Effort.** HAP pairing (SRP-3072, TLV8, Ed25519), FairPlay v3 handshake,
   RTSP setup, buffered audio, ALAC/AAC decode, timestamp/PTP handling, BT output
   — in Swift, with no reference to copy, on iOS 15. A competent iOS engineer is
   looking at **3-4 months**, with a real chance of discovering in month two that
   backgrounding cannot be made reliable on a 6s.

## What this host cannot answer

There is no macOS and no Xcode here, so nothing can be compiled, signed,
installed on the 6s, or observed against a real Apple TV. The spike's ceiling is
a literature and source review. Any "it works" claim from this machine would be
fiction.

## Options

| Option | What it is | Effort | Risk |
| --- | --- | --- | --- |
| **A. iOS AP2 receiver** | Swift port of HAP pairing + FairPlay + RTSP + buffered audio, sideloaded to the 6s | 3-4 months, needs a Mac | High: DRM material, backgrounding, unproven |
| **B. AirPlay 1 iOS app** | AirAP-shaped receiver, BT output, TestFlight | 4-6 weeks, needs a Mac | Low, proven path; no Home app, no multi-room |
| **C. AP2 receiver on a small Linux box** | shairport-sync next to the BT speaker; iPhone becomes a remote, if anything | Days | Low; gets Home app + real multi-room + Apple TV grouping; abandons the 6s |
| **D. Stop** | Use an AirPort Express / AirPlay 2 speaker adapter | None | Cheapest of all |

## Recommendation

**C** if Home app integration and multi-room matter, **B** if the 6s itself is the
point. **A** is a research project with legal exposure, not a product — and it
should only be attempted with a Mac in hand, a paid developer account, and an
explicit decision that sideloaded DRM-circumvention code is acceptable for
personal use.

What would change this: a public Swift AP2 receiver appearing, a working iOS
background-audio receiver prototype proving discovery while suspended, or Apple
opening receiver support. None exist today.

## If A is chosen anyway

Order of work, each phase independently falsifiable:

1. **Discovery on iOS 15** — advertise `_airplay._tcp` from an app, see it in the
   Apple TV picker. One week. Kills the idea early if it fails.
2. **HAP pairing** — implement SRP + TLV8 pairing, get the device into the Home
   app (shairport-sync's documented flow is the acceptance test).
3. **RTSP setup + FairPlay v3** — get an AES key and decrypt a stream, no audio
   output yet.
4. **Buffered audio + ALAC decode** — play through the phone speaker, measure
   latency.
5. **Bluetooth output** — route to the paired speaker, accept the latency, drop
   multi-room sync.
6. **Background hardening** — the phase most likely to end the project.

## Exit

`DEC-001` in this project: the chosen option, what was ruled out, and the
conditions for revisiting. Until it exists, no spec work starts.
