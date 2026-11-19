# PLATFORM — where iOS apps get built

Owner: `ba`. Status: **undecided** (`DEC-004`). Settle this during intake,
before PM breaks the first feature into tasks, because it decides what the
developer is allowed to install and what the tester can actually verify.

## The constraint

iOS binaries require Apple's toolchain: Xcode, the iOS SDK, `xcodebuild`, code
signing. None of that runs on Linux, and it cannot be legally or practically
reproduced there. So on this Linux host we can always do *everything except the
final iOS build and device run*:

- write app code and run its tests,
- run the app in a simulator or desktop/web target for visual checks,
- build and verify all business logic.

The Mac step is only needed for: simulator on real iOS SDK, `.app`/`.ipa`
packaging, signing, TestFlight, App Store.

## Options

| # | Stack | Runs on Linux | iOS build needs | Cost / notes |
| --- | --- | --- | --- | --- |
| A | **Flutter** (Dart) | app, widget tests, Linux desktop target, `flutter test` | a Mac or macOS CI, one command (`flutter build ipa`) | One codebase, later Android/web/desktop for free. SDK ~2 GB under `.tooling/`. |
| B | **React Native + Expo** | app logic, Jest tests, Expo Go on a real phone | EAS Build (cloud, needs Apple account) or a Mac | Node is already here. Fastest feedback loop on a real device. |
| C | **Swift + SwiftPM** | compiles and tests pure logic only | a Mac for any UI | Truest to native iOS, weakest verification here (no SwiftUI/UIKit on Linux). |
| D | **Swift + remote Mac** | everything but the build | a Mac you own, reached over SSH | Best fidelity. Needs a Mac, a key pair, and a build script or MCP bridge (below). |

## Option D detail: driving a Mac from here

Two workable shapes, either can be added later without changing the process:

1. **SSH + wrapper script (simplest, recommended first).** Add
   the build bridge that runs
   `ssh mac 'xcodebuild -project ... -scheme ... -destination ...'` and copies
   artifacts back. Requires a Mac on the network, an SSH key with no passphrase,
   and `xcodebuild` on the Mac. Fits the existing developer/tester loop with no
   new moving parts.
2. **MCP server on the Mac (richest).** Run an Xcode MCP server on the Mac that
   exposes build/test/simulator/screenshot tools, then point OpenCode at it:

   ```jsonc
   // opencode.jsonc — sketch, verify the server's actual transport first
   "mcp": {
     "servers": {
       "xcode": { "type": "remote", "url": "http://mac.local:8765/mcp" }
     }
   }
   ```

   The Mac must be reachable (LAN, Tailscale, or an SSH tunnel) and the server
   must be started on the Mac. Adding this grants the agents tools that act on
   another machine, so it is a human decision and gets a `DEC-###`.

3. **Cloud macOS CI** (GitHub Actions `macos-*` runner, Codemagic, Xcode Cloud,
   MacStadium). Needs an Apple developer account for signing; good for
   unattended builds once the human sets up credentials. CI credentials are
   outside this folder's trust boundary: the human holds them, agents do not.

## Not recommended

Hackintosh / virtualised macOS: breaks Apple's licence, is fragile, and gives
the agents a build host nobody can maintain. Use a real Mac, a rented Mac, or
CI.

## What choosing an option commits us to

- Record the choice as `DEC-###` and update this file.
- Developer installs exactly the SDK that option needs, under `.tooling/`, and
  logs it in the local environment log.
- Tester writes the verification commands for that stack into
  `qa/TEST-PLAN.md`; every acceptance criterion must be checkable with them.
- `qa` must never mark `PASS` on an iOS-only claim it could not run. It returns
  `BLOCKED` and says which Mac-only step is missing.
