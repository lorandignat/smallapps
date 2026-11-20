# PlayTwo

Turns an iPhone 6s into an AirPlay 2 speaker for an Apple TV, playing the audio
through a Bluetooth speaker. Personal, sideloaded, iOS 15 only.

| | |
| --- | --- |
| **Status** | increment 1 in progress (3 of 10 tasks done) |
| **Phase** | build |
| **Platform** | iOS 15.0, iPhone 6s — Swift (`docs/STACK.md`) |
| **v1** | increment 4 of `DEC-002`: discoverable, pairable, audible, useful |

## What it is

The phone runs a software AirPlay 2 receiver: it advertises itself on the local
network, pairs like an accessory, decrypts the stream and plays it. Apple licenses
that capability to hardware makers (MFi); this is a reverse-engineered
implementation for one person's own phone. It is not distributed and cannot be.

AirPlay 2 rather than AirPlay 1 because the Home app can add it and the Apple TV
can pick it as an output. Multi-room grouping with the TV's own output is
explicitly out of scope — Bluetooth latency cannot hold AP2's sync.

The feasibility work, with sources, is in `docs/SPIKE-001-airplay2.md`. The
decision and its costs are `DEC-001` and `DEC-002` in `docs/DECISIONS.md`.

## Current state

Increment 1 is in progress. FEAT-001 has ten tasks; the scaffold, the TXT record
and the rename are done and PASSed, and the app builds, signs and installs on the
reference iPhone 6s. The next task adds the RTSP listener on port 7000. The
authoritative status is `docs/STATE.md`.

## Stack

Swift 5, iOS 15.0 deployment target, SwiftUI, `Network.framework`, `CryptoKit`,
XcodeGen for the project file. Details and the reasoning: `docs/STACK.md`.

## Running it

Filled in by the developer with the first scaffold task. Intended shape, from the
workspace root:

```sh
xcodebuild -version
rsync -a <project> <build-host>:<build-dir>/
xcodebuild build -scheme PlayTwo -sdk iphoneos
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e'
```

## Running it on the iPhone

The device path is repeatable and uses the Mac's Aqua session for signing.
Prerequisites that are already true: the free Apple ID `<apple-id>`
is signed in to Xcode on the Mac, the signing team is set for PlayTwo in Xcode,
and `MAC_TEAM_ID` is present in local configuration (never committed).

From the workspace root:

```sh
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild build -scheme PlayTwo -sdk iphoneos
ios-deploy --bundle build/Build/Products/Debug-iphoneos/PlayTwo.app --id <udid>
ios-deploy --justlaunch --id <udid> --bundle play-two/build/Build/Products/Debug-iphoneos/PlayTwo.app
```

The profile `iOS Team Provisioning Profile: com.lorand.playtwo` expires
**2026-11-23**. After that date the app stops launching; rebuild and
reinstall with the commands above (`-allowProvisioningUpdates` regenerates the
profile).

Device: UDID `<udid>`, name
"<device>", iOS 15.8.8, connected over USB.

`xcrun devicectl` does not work for iOS 15 (it requires iOS 17); install and
launch go through `ios-deploy`, which does. Device builds must go through
build (Aqua session); running `xcodebuild` over ssh loses keychain
access and fails with `errSecInternalComponent`.

## Layout

```
product/    requirements: idea notes, approved spec
docs/       state, design, stack, decisions, questions, spike
backlog/    board, features, atomic tasks
qa/         test plan, regression list, per-task verdicts
journal/    one log per role
```

Source directories are added by the first scaffold task, following the stack's
conventions.

## Decisions and questions

- Decisions with consequences: `docs/DECISIONS.md`
- Anything waiting on the human: `docs/QUESTIONS.md`
- Architecture and data model, once they exist: `docs/DESIGN.md`

## Notes

This project is built inside a shared workspace; the process, agents and
conventions are described in the workspace `README.md` and `docs/PROCESS.md`.
Project-specific rules for the agents belong in `AGENTS.md` next to this file.
