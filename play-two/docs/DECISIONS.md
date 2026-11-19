# DECISIONS — Relay

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

## DEC-003 — The advertised name is fixed in increment 1; the settings screen lands in increment 2

- date: 2026-11-15
- status: accepted
- owner: ba
- context: SPEC §4 lists a name settings screen as in v1 but assigns it to no
  increment; FEAT-001 therefore advertises a default name and S1 says "under the
  configured name" (QQ-006).
- decision: Increment 1 advertises the default `AirPlay Receiver`, taken from
  `AppInfo.displayName`. The rename UI belongs to increment 2, where pairing and
  the Home app make a stable, human-chosen name matter.
- consequences: S1 is verified with the default name in increment 1 and
  re-verified with a renamed device when the UI lands. No task is added to
  FEAT-001.

## DEC-004 — S1's disappearance check means a graceful withdrawal, not cache expiry

- date: 2026-11-15
- status: accepted
- owner: ba
- context: S1 says the entry disappears "within 30 seconds of the app being
  killed", but no app code runs after a kill: the Apple TV's Bonjour cache decides
  (QQ-007).
- decision: Verify the half the app controls — backgrounding or stopping the
  receiver withdraws the advertisement promptly (TASK-006) — and record the
  post-kill disappearance as cache expiry, measured once and noted, not as a
  pass/fail on app code. S5 keeps the stale-entry check, which is the part that
  actually matters to the owner.
- consequences: the increment-1 demo measures both, and QA states which one is
  the app's responsibility. S1's wording is read this way until the next G1
  touch, when it can be paraphrased.

## DEC-005 — Simulator destination is `iPhone 16e`; the Mac runs Xcode 26.6

- date: 2026-11-16
- status: accepted
- owner: ba
- context: The Mac has Xcode 26.6 with the iOS 26.5 SDK and no `iPhone 16`
  simulator; the only iPhone-shaped simulator installed is `iPhone 16e`
  (`xcrun simctl list devices available`). Task files and the QA plan were
  written against a guessed name.
- decision: Use `platform=iOS Simulator,name=iPhone 16e` in every verification
  command. The deployment target stays iOS 15.0: it builds with the 26.5 SDK, and
  the 6s is the real target, not the simulator.
- consequences: PM updates the remaining task files; the simulator's iOS is 26.5,
  so passing there proves compilation and unit behaviour, never iOS 15 runtime
  behaviour. Only the 6s does that.

## DEC-006 — The app is called Relay (superseded by DEC-007)

- date: 2026-11-16
- status: superseded by DEC-007
- owner: ba (human decision)
- context: "AirPlay 2 Receiver" was a description, not a name: two words of
  Apple trademark, no identity, and it reads as a component. The name is what
  the Apple TV shows in its speaker list and what the Home app would store, so
  changing it later costs the pairing identity.
- decision: The product is **Relay**. Project directory `relay/`, Xcode target
  and scheme `Relay`, test target `RelayTests`, bundle identifier
  `com.lorand.relay`, displayed name `Relay`. The protocol work is unchanged;
  "AirPlay 2" stays in the documentation as the thing implemented, not as the
  product name.
- consequences: one mechanical rename before the code grows. TASK-010 does the
  code and manifest half; the directory, docs and registry were renamed first.
  Pairing keys do not exist yet, so nothing is invalidated in the Home app.

## DEC-007 — The app is called PlayTwo

- date: 2026-11-16
- status: accepted
- owner: ba (human decision)
- context: DEC-006 chose Relay, which the human rejected: the name has to
  reflect that this is AirPlay 2, not a generic bridge. Nothing had been built
  under the Relay name except the directory and docs, and pairing keys do not
  exist yet, so the cost of changing again was one commit.
- decision: The product is **PlayTwo**. Project directory `play-two/`, Xcode
  target and scheme `PlayTwo`, test target `PlayTwoTests`, bundle identifier
  `com.lorand.playtwo`, displayed name `PlayTwo`. "AirPlay 2" stays in the
  documentation as the thing implemented; "PlayTwo" is the product.
- consequences: same mechanical rename as DEC-006, applied once. TASK-010 does
  the code and manifest half. The name avoids Apple's "AirPlay" trademark while
  still reading as AirPlay 2 to anyone who knows the protocol.
