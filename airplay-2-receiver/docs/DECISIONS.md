# DECISIONS — AirPlay 2 Receiver

Append only. Reverse a decision with a new entry, never by editing the old one.
Workspace-level decisions live in `../../docs/DECISIONS.md`.

```md
## DEC-001 — <title>
- date: YYYY-MM-DD
- status: proposed | accepted | superseded by DEC-###
- owner: ba
- context: what forced a choice
- decision: what we chose
- consequences: what it costs, what it enables
```

---

## DEC-001 — Build the AirPlay 2 receiver as a sideloaded iOS app

- date: 2026-11-15
- status: accepted
- owner: ba (human decision)
- context: The product goal is an iPhone 6s that receives AirPlay 2 from an Apple
  TV and forwards audio to a Bluetooth speaker, with Home app entry. SPIKE-001
  established that AP2 receiving is software-feasible (five implementations), that
  a software receiver can be added to the Home app on iOS 15.3, and that no iOS
  implementation exists. The two real risks are iOS background discovery and
  FairPlay key material, which is extracted DRM.
- decision: Attempt the iOS AP2 receiver anyway. Personal use, sideloaded to the
  owner's own iPhone 6s; not for distribution and not for the App Store, because
  of the FairPlay key material.
- consequences: 3-4 months of work with an early kill-switch at the discovery
  phase; no App Store path ever; every iOS upgrade can break it; the phone must
  stay on a sideloading routine (7-day resign on a free account, annual on a paid
  one). Accepted by the human with the risk stated.
- revisit if: discovery cannot be made to work from an iOS app, background audio
  cannot be kept alive, or the DRM exposure becomes unacceptable.

## DEC-002 — Scope ladder: prove one layer at a time

- date: 2026-11-15
- status: accepted (G1, 2026-11-15)
- owner: ba
- context: The full product spans discovery, HAP pairing, FairPlay, buffered
  audio decoding, Bluetooth output and background execution. Building it as one
  milestone would hide failure until month three.
- decision: Four increments, each independently demonstrable:
  1. **Discoverable**: the phone advertises `_airplay._tcp`, appears in the Apple
     TV's speaker list.
  2. **Pairable**: HAP pairing works and the phone can be added to the Home app.
  3. **Audible**: an Apple TV stream decrypts and plays through the phone's own
     speaker.
  4. **Useful**: audio is routed to the paired Bluetooth speaker and the app
     survives backgrounding for a full listening session.
- consequences: v1 is defined as increment 4; multi-room grouping with the Apple
  TV's own output is explicitly out of scope because Bluetooth timing cannot
  support it. Each increment is a kill-switch: if it fails, the next one is not
  written.
