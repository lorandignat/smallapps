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
- update (2026-11-22): the build host now runs Xcode 14.2 (14C18) with only an
  iOS 16.2 simulator. Every verification command uses
  `platform=iOS Simulator,name=iPhone 14,OS=16.2`; `iPhone 16e`/`OS 26.5` no
  longer exists here. The deployment target is still iOS 15.0 and the 6s is
  still the real target.

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

## DEC-008 — Device builds use a free Apple ID

- date: 2026-11-16
- status: accepted
- owner: ba (human decision)
- context: device builds need a signing team. The free tier was chosen over the
  paid programme because this is a personal receiver on one phone, and the cost
  of the free tier — a seven-day profile and a periodic re-sign — is acceptable.
- decision: device builds are signed with a free Apple ID's personal team. The
  account and the team identifier live in local configuration and are not part of
  this repository; nothing about signing is committed.
- consequences: profiles expire weekly, so the app must be rebuilt and reinstalled
  about once a week. The free tier allows three devices and ten app ids per week,
  which is enough here.

## DEC-009 — Default title, glass treatment and auto-advertise

- date: 2026-11-16
- status: accepted
- owner: ba (human decision)
- context: the human's post-G1 requests (see `product/IDEA.md`) needed three
  answers before SPEC v1.1 could be drafted: what the Apple TV shows before
  anyone edits it, whether an approximation of the requested glass look is
  acceptable on iOS 15, and whether advertising is a switch that must be turned
  on or a state the app enters by itself.
- decision: the default advertised title is the phone's own name
  (`UIDevice.current.name`, which reads `<device>` on this device),
  editable in the app (increment 2). The human chose the device name over a
  hardcoded literal because it is simpler and follows the phone if it is
  renamed. The UI may use `ultraThinMaterial` / vibrancy for the glass
  treatment — an approximation, understood as such, not Liquid Glass. The
  receiver advertises as soon as it launches; the on/off control turns it off,
  the default is on.
- consequences: increment 2 carries the title setting, the on/off control and the
  idle-timer work; increment 3 carries the visual treatment, because it needs
  something playing to show. Advertising at launch means the first thing a new
  user sees is the phone already offered to the Apple TV, so the state screen must
  say so plainly, and any failure to advertise must be visible rather than silent.

## DEC-010 — Port-7000 tests run on the iPhone, not the simulator

- date: 2026-11-17
- status: superseded by `DEC-011`
- owner: ba (human decision)
- context: TASK-003 binds TCP 7000 because that is where an AirPlay 2 receiver
  is looked for. On the simulator the listener shares the Mac's network
  namespace, and macOS keeps 7000 for its own AirPlay Receiver: `lsof -nP
  -iTCP:7000 -sTCP:LISTEN` names ControlCenter, and `NWListener` fails with
  `bind … [48: Address already in use]`. The developer proved all four
  behaviours by running the same suite on a free port, so the code is right and
  the destination is wrong.
- decision: tests that need the real port 7000 run on the reference iPhone 6s
  (`xcodebuild test -destination 'id=<udid>'`, routed through the Mac's GUI
  session like every device build). Simulator tests stay for everything that
  does not bind a fixed port. The Mac's AirPlay Receiver is neither disabled nor
  part of the test setup.
- consequences: a port-7000 test cycle needs the phone connected, trusted and
  signed, and takes longer than a simulator run; the seven-day profile applies
  to it. Port-7000 evidence becomes device evidence, which is stronger than a
  simulator claim. `qa/TEST-PLAN.md` keeps the simulator for the general suite
  and names the device wherever port 7000 is the subject.

## DEC-011 — The listener port is injectable; 7000 is the default

- date: 2026-11-17
- status: accepted
- owner: ba (human decision)
- context: `DEC-010` moved the fixed-port tests to the phone because macOS owns
  TCP 7000. That does not work either: Xcode 26.6 refuses to plan any unit test
  on a physical device — `Cannot test target "PlayTwoTests" … Logic Testing
  Unavailable` — so the suite could only run on the simulator, where it is red
  by construction, which takes `R2` down with it for every later task. A second
  blocker is independent of the toolchain: nothing calls the listener until
  TASK-004, so a network check against the phone could not pass in TASK-003 no
  matter where the tests ran.
- decision: `ReceiverListener` takes `port: NWEndpoint.Port = .init(rawValue:
  7000)!`; the app always passes nothing and therefore uses 7000. Unit tests bind
  a free ephemeral port and assert every behaviour there, plus one assertion that
  the default initialiser's port is 7000. The real port 7000 is proven on the
  phone when the listener has a caller (TASK-004 wiring, feature close), not
  before.
- consequences: the simulator suite stays the evidence for unit behaviour and
  `R2` can be green again; the AirPlay port itself moves to an app-level
  observation on the device. No second Xcode is installed and `DEC-010`'s
  device-test path is dropped. Tests must still prove the reply byte for byte,
  two sequential connections, the port-in-use failure and the refusal after
  `stop()` — on a free port, which is the same code path.

## DEC-012 — Discovery is proven on the 6s, not on the simulator

- date: 2026-11-18
- status: accepted
- owner: ba (human decision)
- context: TASK-004 registers the `_airplay._tcp` service on the listener's port,
  7000. On the simulator that port is already held by macOS ControlCenter, so the
  listener never becomes ready, the registration never appears, and a `dns-sd`
  browse run on the Mac shows nothing — the same collision that blocked TASK-003
  attempt 1. The alternatives were to switch the Mac's AirPlay Receiver off before
  every run, or to advertise on a random port under a debug flag, which would prove
  a registration the Apple TV never uses.
- decision: the discovery criterion runs against the signed app on the iPhone 6s,
  with the Mac browsing `_airplay._tcp` on the same LAN. The simulator suite stays
  the unit evidence: it proves the service descriptor (type, name, TXT values) and
  the failure path without needing port 7000. The app-level 7000 check on the
  simulator is dropped, not deferred.
- consequences: TASK-004 needs the device path the bridge already provides
  (`build … iphoneos`, `install`, `ios-deploy --justlaunch`), and the app must be
  in the foreground and the phone unlocked while the browse runs. The free-Apple-ID
  profile expires 2026-11-23, so the check must happen while it is valid; after
  that the app has to be rebuilt. This makes discovery the first thing observed on
  the real hardware, which is S1b, and it remains a human observation for the Apple
  TV's own speaker list.

## DEC-014 — TASK-006 rework scope expansion (clear the listener)

- date: 2026-11-19
- status: accepted
- owner: ba (human decision)
- context: TASK-006 was delivered with `src/Net/ServiceAdvertiser.swift` out of
  scope; QA attempt 1 (FAIL) showed the real-app bug: `start()` no-ops because
  `listener` is never cleared, so returning to the foreground does not republish
  the service and `AppState.status` stays `.stopped`. The unit tests passed only
  because the spy has no `listener` guard, masking the defect.
- decision: the developer's rework clears `self.listener = nil` in
  `listenerChanged(.cancelled)` before `report(.stopped)` (one line in
  `ServiceAdvertiser.swift`). QA attempt 2 passed 5/5 on the suite
  (`Executed 25 tests, with 0 failures`); criterion 2's republish path is
  verified statically. The expansion is recorded so any future re-cut of
  TASK-006 includes it.
- consequences: the task's stated scope is narrower than the code that closed
  it; the only source change beyond TASK-006's normal closure artifacts is the
  one line in `ServiceAdvertiser.swift`.
