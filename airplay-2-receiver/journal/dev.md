# Developer journal — AirPlay 2 Receiver

Append only, newest at the bottom. One entry per attempt, including failed ones,
so the next attempt does not repeat a mistake.

```md
## YYYY-MM-DD — TASK-### (attempt n)
- changed: files
- approach: 1-2 lines
- checks run: commands + result
- surprises / gotchas:
- for the tester:
```

---

## 2026-11-15 — TASK-001 (attempt 1)
- changed: `project.yml`, `.gitignore`, `src/AirPlayReceiverApp.swift`,
  `src/ContentView.swift`, `test/AppInfoTests.swift` (new files only; nothing else
  touched, backlog status left to the BA)
- approach: XcodeGen spec with a project-wide iOS 15.0 deployment target, an
  `AirPlayReceiver` application target (`sources: [src]`) and an
  `AirPlayReceiverTests` `bundle.unit-test` target (`sources: [test]`,
  `TEST_HOST`/`BUNDLE_LOADER` pointing at the app), plus one explicit shared
  scheme `AirPlayReceiver` that builds both targets and tests the test target.
  `AppInfo.displayName` lives next to the `@main` struct; `ContentView` is a
  static placeholder for TASK-005; one XCTest pins the display name.
- checks run:
  - `grep -n 'iOS: "15.0"' project.yml` → match (line 14)
  - `grep -n 'AirPlayReceiverTests' project.yml` → 3 matches (target + scheme)
  - `grep -c 'packages:' project.yml` → 0
  - `ls src test` → both dirs exist with the expected files
  - `git check-ignore` → `*.xcodeproj/` and `build/` both ignored
  - `python3 -c 'yaml.safe_load(project.yml)'` → parses; targets, types,
    deploymentTarget, TEST_HOST and scheme keys read back as intended
  - `xcodebuild -version|sync|run|build|test` → all exit 1 with
    `error: missing .../local configuration, i.e. BLOCKED (`QQ-005`), not a code
    result. `/tmp/opencode/task-001-test.log` therefore contains no test output.
- surprises / gotchas:
  - XcodeGen writes the Info.plist itself, so the app and test targets use an
    `info:` block (`src/Info.plist`, `test/Info.plist`) instead of a committed
    plist. Those two files appear only on the Mac's synced copy after `xcodegen
    generate`; they are not in this tree and are not committed.
  - No `projectFormat` is pinned, so XcodeGen uses its default (matching current
    Xcode). If the Mac's Xcode is older and refuses the generated project, the
    fix is to pin `options.projectFormat` — needs the Mac's Xcode version, which
    nothing here can report.
  - The word "packages" is deliberately absent from `project.yml`, since
    criterion 4 is checked with `grep -c 'packages:'` expecting 0.
- for the tester: nothing Swift/Xcode runs on this host. Criteria 1, 2, 3 and 5
  need the Mac (sync → `xcodegen generate` → build → test); criterion 4 is
  satisfied statically. Expect `Executed 1 test, with 0 failures` from
  `AppInfoTests.testDisplayNameIsTheAdvertisedName`; if the run fails, the first
  thing to look at is the generated project format and whether the simulator
  named `iPhone 16` exists on that Mac.
