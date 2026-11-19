---
id: TASK-010
title: Rename the Xcode project to PlayTwo
feature: FEAT-001
status: done
attempts: 1
owner: null
depends_on: [TASK-001]
estimate: small
---

# TASK-010 — Rename the Xcode project to PlayTwo

## Goal

The tree generates and builds a project called `PlayTwo` — `DEC-007`, which
supersedes `DEC-006` (Relay): scheme `PlayTwo`, app target `PlayTwo`, test target
`PlayTwoTests`, module `PlayTwo`, bundle ids `com.lorand.playtwo` and
`com.lorand.playtwo.tests`, and nothing called `AirPlayReceiver` left behind.

## Context for the developer

- Where it lives: `project.yml`, `play-two/.gitignore`, `src/PlayTwoApp.swift`
  (renamed from `src/AirPlayReceiverApp.swift`), `test/AppInfoTests.swift`.
- Files in scope (4): exactly those. The Swift file move is a `git mv` plus the
  struct name, so the diff stays readable.
- The exact mapping, nothing else changes:

  | File | From | To |
  | --- | --- | --- |
  | `project.yml` | `name: AirPlayReceiver` | `name: PlayTwo` |
  | `project.yml` | target `AirPlayReceiver` (`type: application`) | target `PlayTwo` |
  | `project.yml` | target `AirPlayReceiverTests` | target `PlayTwoTests` |
  | `project.yml` | scheme `AirPlayReceiver` | scheme `PlayTwo` |
  | `project.yml` | `TEST_HOST`/`BUNDLE_LOADER` `…/AirPlayReceiver.app/AirPlayReceiver` | `…/PlayTwo.app/PlayTwo` |
  | `project.yml` | header comment naming `AirPlayReceiver.xcodeproj` and `<build-dir>` | `PlayTwo.xcodeproj` and the current Mac path |
  | `project.yml` | `CFBundleDisplayName: AirPlay Receiver` | removed (see Notes) |
  | `project.yml` | `options.bundleIdPrefix` (`com.airplayreceiver`) | removed; bundle ids set explicitly per target: `com.lorand.playtwo`, `com.lorand.playtwo.tests` |
  | `src/AirPlayReceiverApp.swift` | `struct AirPlayReceiverApp` | `src/PlayTwoApp.swift`, `struct PlayTwoApp` |
  | `src/PlayTwoApp.swift` | `AppInfo.displayName = "AirPlay Receiver"` | `"PlayTwo"` |
  | `test/AppInfoTests.swift` | `@testable import AirPlayReceiver` | `@testable import PlayTwo` |
  | `test/AppInfoTests.swift` | asserts `"AirPlay Receiver"` | asserts `"PlayTwo"` |
  | `.gitignore` | — | two new lines: `src/Info.plist`, `test/Info.plist` |

- Bundle ids: set `PRODUCT_BUNDLE_IDENTIFIER` in each target's `settings.base` and
  drop `options.bundleIdPrefix`. A prefix plus the target name would produce
  `com.lorand.PlayTwo` (capitalised, mixed case) or `com.lorand.play-two` (the old
  `DEC-006` hyphenated form); neither is `DEC-007`'s value, so the two explicit
  settings are not optional.
- `CFBundleName` follows the target name automatically
  (`CFBundleName = $(PRODUCT_NAME)`), so no plist key has to carry the name.
- `AppInfo.displayName` is not the home-screen label: it is the advertised Bonjour
  name and the state-screen name (`DEC-003`, `DEC-007`) and it must read
  `"PlayTwo"`.
- Explicitly **do not** touch: `src/ContentView.swift`, `src/AppState.swift`,
  `src/AirPlay/`, `src/Net/`, `src/Diagnostics/`, any other file in `test/`,
  `docs/`, `product/`, `qa/`, `journal/`, `backlog/` (the BA moves the status),
  `scripts/`, `.opencode/`, `../../docs/`, `../../templates/`.

## Acceptance criteria

1. [ ] Given `play-two/project.yml`, when
       `grep -nE '^name: |PlayTwo|com\.lorand' play-two/project.yml` runs, then it
       matches `name: PlayTwo`, the app target `PlayTwo`, the target `PlayTwoTests`
       with `type: bundle.unit-test`, the scheme `PlayTwo`, and both bundle ids
       `com.lorand.playtwo` (app) and `com.lorand.playtwo.tests` (tests); and
       `grep -c 'CFBundleDisplayName' play-two/project.yml` prints `0`.
2. [ ] Given the same file, when `grep -nE 'com\.lorand\.playtwo' play-two/project.yml`
       runs, then the two matching lines read the bundle ids with **no** hyphen:
       `grep -c 'com\.lorand\.play-two' play-two/project.yml` prints `0` and
       `grep -c 'bundleIdPrefix' play-two/project.yml` prints `0`.
3. [ ] Given the renamed tree, when `ls play-two/src play-two/test` and
       `grep -nE 'struct PlayTwoApp|displayName|@testable import' play-two/src/PlayTwoApp.swift play-two/test/AppInfoTests.swift`
       run, then `src/PlayTwoApp.swift` exists and declares `@main struct PlayTwoApp`
       with `static let displayName = "PlayTwo"`, `test/AppInfoTests.swift` has
       `@testable import PlayTwo` and asserts `"PlayTwo"`, and
       `src/AirPlayReceiverApp.swift` no longer exists.
4. [ ] Given the renamed tree, when
       `grep -rn 'AirPlayReceiver' play-two/project.yml play-two/src play-two/test`
       runs, then it prints nothing and exits 1 — no module name, scheme, bundle id,
       `TEST_HOST` or comment mentions the old product name.
5. [ ] Given the tree, when
       `git check-ignore -v play-two/src/Info.plist play-two/test/Info.plist` runs,
       then both lines name `play-two/.gitignore` and the exit status is 0 — the two
       plists `xcodegen` writes are ignored, so a generate inside the repository
       cannot be committed.
6. [ ] Given a synced copy on the Mac, when
       `xcodegen generate`, `build play-two PlayTwo iphonesimulator` and
       `test play-two PlayTwo 'platform=iOS Simulator,name=iPhone 16e'` run, then all
       exit 0, the generated project is `PlayTwo.xcodeproj`, `xcodebuild -list`
       offers the scheme `PlayTwo` and no `AirPlayReceiver`, and the built bundle is
       `…/Debug-iphonesimulator/PlayTwo.app` whose plist reads
       `CFBundleName = PlayTwo`, has no `CFBundleDisplayName` key, and whose
       `CFBundleIdentifier` is `com.lorand.playtwo`.
7. [ ] Given that same run, when the test log is read, then it contains
       `Test Case '-[PlayTwoTests.AppInfoTests` and
       `Executed 1 test, with 0 failures`.

## Verification commands

```sh
# on this host (static, all expected green)
grep -nE '^name: |PlayTwo|com\.lorand' play-two/project.yml
grep -c 'com\.lorand\.play-two' play-two/project.yml       # expected: 0, exit 1
grep -c 'bundleIdPrefix' play-two/project.yml              # expected: 0, exit 1
grep -c 'CFBundleDisplayName' play-two/project.yml         # expected: 0, exit 1
grep -nE 'struct PlayTwoApp|displayName|@testable import' play-two/src/PlayTwoApp.swift play-two/test/AppInfoTests.swift
ls play-two/src play-two/test                               # no AirPlayReceiverApp.swift
grep -rn 'AirPlayReceiver' play-two/project.yml play-two/src play-two/test || echo 'no stale identifier'
git check-ignore -v play-two/src/Info.plist play-two/test/Info.plist
git status --porcelain --untracked-files=all | grep -E 'Info\.plist' || echo 'plists not in status'

# on the Mac (QQ-005 is resolved; these are expected to run, not to block)
xcodebuild -version
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
ls -d PlayTwo.xcodeproj && xcodebuild -list -project PlayTwo.xcodeproj
xcodebuild build -scheme PlayTwo -sdk iphonesimulator
/usr/libexec/PlistBuddy -c "Print :CFBundleName" <workspace>play-two/build/Build/Products/Debug-iphonesimulator/PlayTwo.app/Info.plist; /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" <workspace>play-two/build/Build/Products/Debug-iphonesimulator/PlayTwo.app/Info.plist; /usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" <workspace>play-two/build/Build/Products/Debug-iphonesimulator/PlayTwo.app/Info.plist || echo "no CFBundleDisplayName key"
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e' | tee /tmp/opencode/task-010-test.log
grep -E "Test Case '-\[PlayTwoTests\.AppInfoTests" /tmp/opencode/task-010-test.log
grep -E "Executed 1 test, with 0 failures" /tmp/opencode/task-010-test.log

# the old scheme must not resolve: expected to FAIL, exit 1
xcodebuild test -scheme AirPlayReceiver -destination 'platform=iOS Simulator,name=iPhone 16e'
```

**Expected today:** every line above is runnable — the Mac answers, Xcode 26.6 is
installed and `QQ-005` is resolved. A `BLOCKED` now means the bridge broke, and is
reported as such; it is no longer the normal outcome.

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-010-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only the four files listed above changed (`src/PlayTwoApp.swift` counted once)
- [ ] Regression list still passes (R1, R2, R3, R5 in particular)
- [ ] One commit `play-two/TASK-010: rename the Xcode project to PlayTwo` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| 1 | 2026-11-16 | PASS, 7/7 criteria, regressions clean; mutation probe re-run | Done. |

## Notes

**One name, one decision.** `DEC-007` names the product **PlayTwo** and supersedes
`DEC-006` (Relay); nothing in the tree, the manifest or this task may follow the
older name. `DEC-006` is history only — it is not the decision this task
implements, and no Relay-era identifier (`Relay`, `com.lorand.relay`, the
hyphenated `com.lorand.play-two`) survives the rename.

**Display name: one source, and it is the target name.** `CFBundleDisplayName` is
**dropped** from `project.yml`. XcodeGen then emits `CFBundleName =
$(PRODUCT_NAME)`, which resolves to `PlayTwo` because the target is `PlayTwo`, and
iOS falls back to `CFBundleName` for the home-screen label. So the displayed name
has exactly one configuration source — the target name — instead of a literal
that can drift from it, which is QA finding 5 on TASK-001. Do not re-add the key
as a literal (`PlayTwo`) or as `$(PRODUCT_NAME)`: the literal restores the
duplication, and the variable is an extra moving part that buys nothing over the
fallback. `AppInfo.displayName` is a different thing — it is the advertised
Bonjour name and the state-screen name (`DEC-003`), it is not the home-screen
label, and criterion 3's grep plus `AppInfoTests` keep it pinned.

**Generated plists.** `xcodegen` writes `src/Info.plist` and `test/Info.plist`
from the `info:` blocks in `project.yml`, inside the tree. They exist only on the
synced copy today, so nothing leaks by itself (QA finding 4 on TASK-001); the
exposure is an agent generating in the repository and then committing. Both paths
go into `play-two/.gitignore`; `*.xcodeproj/` and `build/` stay.

**The rename invalidates the tester's commands.** Renaming the scheme means every
`xcodebuild build|test|install play-two AirPlayReceiver …` line, and
renaming the module means every `@testable import AirPlayReceiver`, would no
longer resolve. PM has already corrected TASK-002..TASK-009 to the `PlayTwo`
scheme in the same batch as this task; do not edit them from this task and do not
keep the old scheme as an alias to make anything work — a second scheme would
defeat criterion 4 and `DEC-007`.

**Out of scope here.** The export filename `airplay-receiver-log.txt` (TASK-008)
keeps its name in this task: it is that task's deliverable, and PM has raised the
naming inconsistency with the BA rather than deciding it here. Nothing else in
`src/` is renamed — no type, method or directory.

**Not a restyle.** Deployment target stays `iOS: "15.0"`, `sources: [src]` and
`[test]` stay, the scheme's actions stay as they are (build/run/test/profile/
analyze/archive with the same configs). This is an identity change only.
