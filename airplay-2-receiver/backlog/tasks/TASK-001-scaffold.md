---
id: TASK-001
title: Scaffold the XcodeGen app with one unit test
feature: FEAT-001
status: approved
attempts: 0
owner: null
depends_on: []
estimate: small
---

# TASK-001 — Scaffold the XcodeGen app with one unit test

## Goal

The project builds and runs a test on the Mac: `project.yml` generates an
`AirPlayReceiver` scheme with an iOS 15.0 app target and a test target, the app
has one SwiftUI screen, and one XCTest passes.

## Context for the developer

- Where it lives: project root `project.yml`, `src/`, `test/`
- Interfaces it may touch: none yet — this creates the tree
- Files in scope (5): `project.yml`, `.gitignore`, `src/AirPlayReceiverApp.swift`,
  `src/ContentView.swift`, `test/AppInfoTests.swift`
- `src/AirPlayReceiverApp.swift` declares `enum AppInfo { static let displayName =
  "AirPlay Receiver" }` next to the `@main` app struct; `AppInfo.displayName` is
  the default advertised name used by later tasks.
- `.gitignore` ignores `*.xcodeproj/` and `build/`, per `docs/STACK.md` (the
  `.xcodeproj` is generated, never committed).
- No signing team, no entitlements, no Info.plist file: XcodeGen generates the
  plist from `project.yml`. No SPM packages.
- Explicitly **do not** touch: `product/`, `docs/`, `qa/`, `journal/`,
  `backlog/` (other than this file's status), `.opencode/`, `scripts/`,
  `../../docs/`, `../../templates/`.

## Acceptance criteria

1. [ ] Given the tree with no `.xcodeproj`, when `xcodegen generate` runs on the
       Mac from the synced copy, then it exits 0 and `AirPlayReceiver.xcodeproj`
       exists.
2. [ ] Given the generated project, when `build ... iphonesimulator` runs, then
       it exits 0, prints `ok — log:` and reports
       `.../AirPlayReceiver.app` under `build/Build/Products/Debug-iphonesimulator/`.
3. [ ] Given the generated project, when `test` runs on the simulator, then the
       log contains `Executed 1 test, with 0 failures` and no `error:` lines.
4. [ ] `project.yml` declares `deploymentTarget: iOS: "15.0"`, a scheme named
       `AirPlayReceiver`, a target `AirPlayReceiverTests` of type
       `bundle.unit-test`, and no `packages:` section.
5. [ ] Given `project.yml` is edited without regenerating on the Mac, when
       `build` runs, then it fails with `no .xcodeproj or .xcworkspace` — the
       documented fix in `FEAT-001` Notes is the expected resolution, not a code
       change.

## Verification commands

```sh
# on this host: static checks (work today)
grep -n 'iOS: "15.0"' airplay-2-receiver/project.yml
grep -n 'AirPlayReceiverTests' airplay-2-receiver/project.yml
grep -c 'packages:' airplay-2-receiver/project.yml   # expected: 0
ls airplay-2-receiver/src airplay-2-receiver/test

# on the Mac: build and test (expected BLOCKED until QQ-005 resolves)
xcodebuild -version
rsync -a <project> <build-host>:<build-dir>/ airplay-2-receiver
xcodegen generate
xcodebuild build airplay-2-receiver AirPlayReceiver iphonesimulator
xcodebuild test airplay-2-receiver AirPlayReceiver 'platform=iOS Simulator,name=iPhone 16' | tee /tmp/opencode/task-001-test.log
grep -E "Executed 1 test, with 0 failures" /tmp/opencode/task-001-test.log
```

**Expected today:** the `grep`/`ls` checks pass after the developer writes the
files; every build command is `BLOCKED` until local configuration
exists and the agent key is installed on the Mac (`QQ-005`). A `BLOCKED` here is
recorded in the review, not hidden.

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-001-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes (`qa/REGRESSION.md`; empty in increment 1)
- [ ] One commit `airplay-2-receiver/TASK-001: scaffold the XcodeGen app with one unit test` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- The scaffold test is green, not deliberately failing. An intentionally red test
  would leave the tree red for the next task, which the build loop forbids;
  every later task adds its own test for its own behaviour.
- `iphonesimulator` is the build target for verification because `iphoneos`
  needs the human's signing team (`QQ-005`). Do not add a team to `project.yml`:
  it is machine-specific and would be committed.
- Scheme target order: the app target is `AirPlayReceiver`, the test target
  `AirPlayReceiverTests` with `AirPlayReceiver` as its test host.
