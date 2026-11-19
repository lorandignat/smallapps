---
id: FEAT-001
title: Discoverable AirPlay 2 receiver
status: approved
slice: Launching the app puts the phone in the Apple TV speaker list under the app's name, and the phone answers a TCP connection on port 7000.
spec_ref: product/SPEC.md#6-success-criteria
depends_on: []
---

# FEAT-001 — Discoverable AirPlay 2 receiver

**Demo:** 1. Launch the app on the iPhone and read the state screen: `Advertising
as <name>` with no error. 2. On the Apple TV, open the AirPlay speaker list: the
phone appears under that name within 30 seconds; kill the app and it disappears.

This is increment 1 of `DEC-002` and the "Discovery on iOS 15" phase of
`SPIKE-001` (section "If A is chosen anyway"). It is the kill-switch for the
whole project: if a sideloaded iOS app cannot make the Apple TV offer it, no
later increment has a platform.

## User value

The owner wants the TV's sound through a speaker they already own. Before any
pairing or audio work, the Apple TV must see the phone at all. This slice delivers
exactly that, plus the evidence to tell "the Apple TV ignores us" apart from
"the app never advertised".

## In scope

- [ ] The app publishes `_airplay._tcp` over Bonjour with an AirPlay TXT record
      (S1, S5, `DEC-002`).
- [ ] The app listens on TCP 7000 and answers a connection with a fixed
      response, so a sender that found us is not left hanging.
- [ ] One screen shows the receiver state (`Idle`, `Advertising`, `Stopped`,
      error text) and the advertised name.
- [ ] The advertisement is withdrawn when the app leaves the foreground, so the
      Apple TV has no ghost entry afterwards (S1, S5).
- [ ] Advertisement events are recorded in an in-app log and can be written to a
      file, so the human's observation is backed by evidence (SPEC §4, "A log
      view exportable to a file").

## Out of scope

- HAP pairing, the Home app, Ed25519/TLV8/SRP — increment 2.
- RTSP session setup, FairPlay, audio decode and playback — increment 3.
- Bluetooth routing and background execution — increment 4.
- Editing the advertised name, persisting a receiver identity beyond what the
  TXT record needs, and mDNS tuning beyond one service instance. The settings
  screen from SPEC §4 is **not** in this feature; its increment is open, see
  Notes (QQ-006).
- Answering anything real on port 7000: no RTSP parsing, no OPTIONS handling.

## Acceptance criteria (feature level)

Traced to SPEC §6. The automated parts are the only ones an agent may claim; the
rest are the human's observation.

- [ ] **S1a (automated).** Given `xcodebuild -version` passes and the app
      is foregrounded on the simulator, when the app has been running for 30
      seconds, then `dns-sd -B _airplay._tcp .` on the Mac lists exactly one
      instance under the app's name.
- [ ] **S1b (human).** Given the app is foregrounded on the iPhone, when the
      human opens the Apple TV's AirPlay speaker list, then the phone appears
      there within 30 seconds under the app's name.
- [ ] **S1c (human).** Given the phone was listed, when the app is killed, then
      the entry is gone from the Apple TV list within 30 seconds.
- [ ] **S1d (automated).** Given the app is advertising, when a TCP client
      connects to the phone's port 7000, then it receives the fixed response
      within 5 seconds and the connection closes.
- [ ] **S5 (human + log).** Given the Apple TV selected the phone and the app
      was then killed, when the app is launched again, then the list shows one
      entry under the same name, no stale duplicate, and the exported log
      contains the `Restart` line for that launch.
- [ ] Every task in the table below is `done` with a `qa` verdict of `PASS`.

## Tasks

Dependency order, one at a time. Only this feature is broken down; increments 2-4
stay at feature level until their turn (`DEC-002`). TASK-010 (`DEC-007`, which
supersedes `DEC-006`) depends only on TASK-001 and runs first among the
001-children because every build command in TASK-002..009 names the
`PlayTwo` scheme it creates.

| ID | Title | Status |
| --- | --- | --- |
| TASK-001 | Scaffold the XcodeGen app with one unit test | done |
| TASK-010 | Rename the Xcode project to PlayTwo | approved |
| TASK-002 | Build the AirPlay TXT record from a stable device id | proposed |
| TASK-003 | Answer TCP connections on port 7000 | proposed |
| TASK-004 | Publish the `_airplay._tcp` service | proposed |
| TASK-005 | Show the receiver state on the main screen | proposed |
| TASK-006 | Withdraw the advertisement when the app leaves the foreground | proposed |
| TASK-007 | Record advertisement events in a diagnostic log | proposed |
| TASK-008 | Export the diagnostic log to a file | proposed |
| TASK-009 | Install a signed build on the device | blocked (QQ-008) |

## Notes

**Verified on the Mac, not here.** No task below can be verified on this Linux
host. Every build and test runs on the human's Mac through the build bridge;
the bridge is configured and `check` passes (`QQ-005` resolved 2026-11-16), so each
task carries runnable commands rather than a standing block.

**Device install.** S1b, S1c and S5 exist only on the iPhone 6s, and TASK-001
verifies `iphonesimulator` only. TASK-009 builds, installs and launches a signed
`iphoneos` build; it is `blocked` until `QQ-008` names the signing team, and the
team is read from a gitignored `Signing.xcconfig`, never from `project.yml`.

**S5's log line.** TASK-007 records a `Restart` line on every launch, which is the
producer of the "`Restart` line for that launch" that S5 requires; its
exported-file check runs after TASK-008.

**Process gap, not a spec gap.** `rsync -a <project> <build-host>:<build-dir>/` copies the tree but
does not run `xcodegen`, and `.xcodeproj` is gitignored (`docs/STACK.md`). After
any `project.yml` change the tester must run, once on the Mac:

```sh
xcodegen generate
```

Without it, `build` and `test` fail with `no .xcworkspace or .xcodeproj in
play-two`.

**Open questions for the BA.** Recorded here because PM may not write
`docs/QUESTIONS.md`:

- `QQ-006` — the advertised-name settings screen is "also in v1" (SPEC §4) and S1
  says "under the configured name", but no increment owns it. This feature ships
  a single default name. Where does the settings screen go: this increment, or a
  separate feature between FEAT-001 and increment 2?
- `QQ-007` — S1 requires the entry to disappear "within 30 seconds of the app
  being killed". No app code runs on a kill, so the disappearance depends on
  Bonjour cache expiry, which the app cannot set. Is the criterion "the app
  withdraws the advertisement when it leaves the foreground, and the entry clears
  after a kill on its own" (observable, TASK-006), or is a specific expiry time
  required?

**Assumptions.**

- One service instance, one listener, foreground only. SPEC §2 and §3 step 1 put
  the app in the foreground; background discovery is increment 4.
- The phone and the Apple TV share an IPv4 LAN (SPEC §7); no IPv6 work.
- The name shown in the speaker list is the Bonjour service instance name and
  the same string the state screen shows.
- A fixed response on port 7000 is enough for increment 1: the Apple TV only
  needs to see the service. A real RTSP reply is increment 3.
