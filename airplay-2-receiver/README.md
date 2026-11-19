# AirPlay 2 Receiver

Turns an iPhone 6s into an AirPlay 2 speaker for an Apple TV, playing the audio
through a Bluetooth speaker. Personal, sideloaded, iOS 15 only.

| | |
| --- | --- |
| **Status** | specified, awaiting G1 |
| **Phase** | intake |
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

No code. Spec and stack are written and awaiting the G1 gate; the Mac build
bridge (the build bridge in the workspace) is built but not yet tested
against the real Mac. The authoritative status is `docs/STATE.md`.

## Stack

Swift 5, iOS 15.0 deployment target, SwiftUI, `Network.framework`, `CryptoKit`,
XcodeGen for the project file. Details and the reasoning: `docs/STACK.md`.

## Running it

Filled in by the developer with the first scaffold task. Intended shape, from the
workspace root:

```sh
xcodebuild -version
rsync -a <project> <build-host>:<build-dir>/  airplay-2-receiver
xcodebuild build airplay-2-receiver AirPlayReceiver iphoneos
xcodebuild test  airplay-2-receiver AirPlayReceiver 'platform=iOS Simulator,name=iPhone 16'
```

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
