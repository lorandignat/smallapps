# STACK — AirPlay 2 Receiver

Owner: `ba`. Decided at G1, changed only by a new `DEC-###` plus human approval.
The developer may not deviate from this file.

| | |
| --- | --- |
| Platform | iOS 15.0 deployment target, arm64 device build (iPhone 6s, A9) |
| Language / SDK | Swift 5, iOS SDK from the Mac's Xcode |
| UI toolkit | SwiftUI (one screen: state, start/stop, last error) |
| Networking | `Network.framework` (`NWListener`) for mDNS advertisement and TCP; `Foundation` |
| Crypto | `CryptoKit` (Curve25519, Ed25519, ChaCha20-Poly1305, SHA-512); SRP-3072 implemented in-project |
| Project generation | XcodeGen — `project.yml` is the source of truth, `.xcodeproj` is generated and gitignored |
| Test runner | XCTest, run on a simulator on the Mac |
| Dependencies | none at increment 1; every later dependency needs a `DEC-###` |
| Build command | `xcodebuild build airplay-2-receiver AirPlayReceiver iphoneos` |
| Test command | `xcodebuild test airplay-2-receiver AirPlayReceiver 'platform=iOS Simulator,name=iPhone 16'` |
| Verification here | unit tests: no (needs the Mac). Device behaviour: no. See below. |

## Why this stack

The product is a protocol implementation with a thin UI, on one fixed OS version
and one device. Swift with Apple's own networking and crypto frameworks is the
only stack that gives direct access to `Network.framework` (mDNS without a
dependency), `CryptoKit` (the HAP primitives) and `AVAudioSession` (background
audio), and it can be signed and installed by the Mac that already exists.
Flutter and React Native would put a bridge between the app and all three of
those, on an OS version they support poorly.

XcodeGen because the generated `.xcodeproj` is a machine-rewritten binary-ish
plist; committing it invites merge conflicts that the agents cannot resolve
without Xcode. A `project.yml` is reviewable text and regenerates identically.

## Feasibility risks carried into the build

- **FairPlay key material.** Increment 3 needs the extracted key tables from the
  openairplay receiver. Personal, sideloaded use only (`DEC-001`). This is the
  reason there is no App Store path and no distribution.
- **Background discovery.** Increment 1 only has to work with the app in the
  foreground, which sidesteps the hard problem. Increment 4 is where it may end.
- **No public iOS AP2 receiver exists.** Every increment is a first-of-kind port;
  the reference implementations are Python, Go, C, Rust and Java.
- **Bluetooth timing.** Multi-room grouping with the Apple TV's own output is out
  of scope by `DEC-002`; a single stream to the BT speaker is the target.
- **iOS 15 SDK availability.** The Mac's Xcode must still offer an iOS 15.0
  deployment target. If Apple has dropped it, the fallback is to pin an older
  Xcode; that is a `DEC-###`, not a workaround.

## What cannot be verified on this host

Nothing iOS runs here — no Swift, no simulator, no Xcode. Every build and test
runs on the Mac through the build bridge (contract: the private build notes).
The tester may claim a PASS only from quoted build output or the
human's observation of the Apple TV. Anything else is `BLOCKED`, not "probably
fine".

The human is also the only one who can press buttons on the Apple TV, so
"appears in the speaker list" is verified by the human following a written
procedure and reporting what they saw.

## Installed toolchain

- This host: the local environment log — git, openssh, rsync under `.tooling/`. No
  Swift, no iOS SDK, by design.
- Mac (human-provided): current Xcode from the App Store, opened once; XcodeGen
  (`brew install xcodegen`); Remote Login enabled; the agent's key installed;
  the iPhone 6s paired and trusted. Prerequisites and the fallback are in
  the private build notes.
