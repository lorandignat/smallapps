---
id: TASK-001-review
task: TASK-001
feature: FEAT-001
verdict: PASS
date: 2026-11-16
attempt: 1
round: 2
---

# Review — TASK-001 Scaffold the XcodeGen app with one unit test

Round 2, attempt 1. The round-1 verdict was `BLOCKED` for one reason only: no Mac
was reachable (`QQ-005`, local configuration absent, every build command
dying in `load_env`). That cause is resolved — `mac.env` exists, the key is
installed and `check` exits 0 — so this report re-runs every criterion from
scratch on the real Mac instead of inheriting round 1's static conclusions.
Nothing below is copied from round 1; the round-1 findings are re-checked at the
end.

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | `xcodegen generate` on the Mac exits 0 and `AirPlayReceiver.xcodeproj` exists | **PASS** | After `sync` the copy had none: `zsh:1: no matches found: *.xcodeproj`, `ls: src/Info.plist: No such file or directory`, `ls: test/Info.plist: No such file or directory` (`20261116T151350Z-sync.log`, `…151351Z-run.log`). Then `xcodegen generate` → exit 0, `⚙️ Generating project… ⚙️ Writing project… Created project at airplay-2-receiver/AirPlayReceiver.xcodeproj` (`…151355Z-run.log`), and `ls -ld` shows the directory with `project.pbxproj`, `project.xcworkspace`, `xcshareddata`, plus both generated plists. |
| 2 | `build … iphonesimulator` exits 0, prints `ok — log:` and reports `.../AirPlayReceiver.app` under `build/Build/Products/Debug-iphonesimulator/` | **PASS** | exit 0, `** BUILD SUCCEEDED **`, `ok — log: …/20261116T151400Z-build.log`, `app bundle: airplay-2-receiver/build/Build/Products/Debug-iphonesimulator/AirPlayReceiver.app`. The bundle is real, not just printed: `-rwxr-xr-x … 123824 … AirPlayReceiver.app/AirPlayReceiver`, plist `CFBundleDisplayName = AirPlay Receiver`, `MinimumOSVersion = 15.0` (`…151428Z-run.log`). Re-run from an emptied derived-data directory (`rm -rf build`): exit 0 again, `** BUILD SUCCEEDED **`, 8 `SwiftCompile` lines (`…152006Z-build.log`). |
| 3 | The `test` log contains `Executed 1 test, with 0 failures` and no `error:` lines | **PASS** | exit 0; `Test Case '-[AirPlayReceiverTests.AppInfoTests testDisplayNameIsTheAdvertisedName]' passed (0.001 seconds).`; `Executed 1 test, with 0 failures (0 unexpected) in 0.001 (0.002) seconds` (three suite lines); `** TEST SUCCEEDED **`; `ok — log: …/20261116T152024Z-test.log`. `grep -E "Executed 1 test, with 0 failures"` → match, exit 0. `grep -nE 'error:'` on that log → no match, exit 1. Cold run after the clean build; an earlier warm run gave the identical result (`…151434Z-test.log`). |
| 4 | `project.yml` declares `deploymentTarget: iOS: "15.0"`, a scheme `AirPlayReceiver`, a target `AirPlayReceiverTests` of type `bundle.unit-test`, and no `packages:` section | **PASS** | `project.yml:14 iOS: "15.0"`; `:34-35 AirPlayReceiverTests:` / `type: bundle.unit-test`; `:49-50 schemes:` / `AirPlayReceiver:`; `grep -c 'packages:'` → `0` and the word appears nowhere in the file (`grep -nE 'packages?\b'` → no match); `DEVELOPMENT_TEAM` count 0. YAML parse: top keys `['name','options','targets','schemes']`, `deploymentTarget {'iOS': '15.0'}`, scheme test action `['AirPlayReceiverTests']`, `packages` key absent. XcodeGen's own output agrees: `xcodebuild -list` → `Targets: AirPlayReceiver, AirPlayReceiverTests`, `Schemes: AirPlayReceiver`; `project.pbxproj` → `IPHONEOS_DEPLOYMENT_TARGET = 15.0;` (×2), `productType = "com.apple.product-type.bundle.unit-test"`, shared `xcshareddata/xcschemes/AirPlayReceiver.xcscheme`. |
| 5 | Editing `project.yml` without regenerating makes `build` fail with `no .xcodeproj or .xcworkspace` | **PASS** (with a wording note, finding 2) | After `sync` (no `.xcodeproj` present) `build airplay-2-receiver AirPlayReceiver iphonesimulator` → exit 1, `error: no .xcworkspace or .xcodeproj in airplay-2-receiver — run: xcodegen generate`. Same command, same tree, succeeds when the project exists (criterion 2), so the failure is not collateral. The two artifact names are the ones the criterion names, in the other order, and the message carries the documented fix. |

All five criteria were executed on the Mac; none is claimed from reading code.

### Anti-accident checks — the ways these criteria could be green by accident

- **Is the passing test real?** On the Mac copy only, `AppInfo.displayName` was
  changed to `"AirPlay Receiver MUTATED"`, the test re-run: exit 1,
  `test/AppInfoTests.swift:9: error: … XCTAssertEqual failed: ("AirPlay Receiver
  MUTATED") is not equal to ("AirPlay Receiver")`,
  `Executed 1 test, with 1 failure (0 unexpected)`, `** TEST FAILED **`
  (`…151548Z-test.log`). The repo was not touched; `sync` restored the file and
  its `sha256` equals the repo's again
  (`00ec5f60e31f4155cc33538f0353f518b71d2f5bd01d9e836009ca91e48c1779`), after
  which the test passed again. So `Executed 1 test, with 0 failures` is a real
  assertion, not an empty suite. Recorded as R6.
- **Is `Executed 1` the one intended test?** `grep -rn 'func test'` in `test/`
  → one method, `testDisplayNameIsTheAdvertisedName` at `AppInfoTests.swift:7`;
  `find … -type f` → one file. One `AppInfo` definition
  (`src/AirPlayReceiverApp.swift:8-9`), and the run's `Test Case` line names the
  same method.
- **Could it pass without running against the app?** `project.pbxproj` sets
  `TEST_HOST = "$(BUILT_PRODUCTS_DIR)/AirPlayReceiver.app/AirPlayReceiver"` and
  `BUNDLE_LOADER = "$(TEST_HOST)"` (Debug and Release), and the test bundle
  compiles `@testable import AirPlayReceiver`, which only resolves against the app
  module; the same `xcodebuild test` log builds the `AirPlayReceiver` app before
  it runs the bundle.
- **Could the test opt out?** `grep -rnE 'XCTSkip|XCTExpectFailure|\.skip|#if|try\?|guard'`
  in `test/` → none. R5 re-verified.
- **Could a stale generated project hide a broken `project.yml`?** Criterion 4
  was checked in the *generated* output as well as the source, and the clean
  derived-data build recompiled from zero.
- **Could the `iPhone 16` → `iPhone 16e` rename be cosmetic?** No: the literal
  `platform=iOS Simulator,name=iPhone 16` fails, exit 1, `xcodebuild: error:
  Unable to find a device matching the provided destination specifier`
  (`…151833Z-test.log`). `xcrun simctl list devices available` shows the only
  iPhone-shaped iOS 26.5 simulator is `iPhone 16e (5F70EE69-…)` (`…151829Z-run.log`).
  Criterion 3 is therefore proven on the destination `DEC-005` names, and the
  task file's `iPhone 16` could not have produced a green run at all.

## What I ran

From `/homedir/agent/opencode/apps`. Logs are under ``.

```sh
$ xcodebuild -version                                   # exit 0
== host ==
<user>@<build-host>
26.6.2
arm64
== xcode ==
Xcode 26.6
Build version 17F113
log: /homedir/agent/opencode/apps/20261116T151335Z-check.log

$ rsync -a <project> <build-host>:<build-dir>/ airplay-2-receiver                  # exit 0
syncing airplay-2-receiver -> <user>@<build-host>:airplay-2-receiver
ok — log: …/20261116T151350Z-sync.log

$ ls -d *.xcodeproj …
zsh:1: no matches found: *.xcodeproj
ls: src/Info.plist: No such file or directory
ls: test/Info.plist: No such file or directory

$ xcodegen generate   # exit 0
⚙️  Generating plists...
⚙️  Generating project...
⚙️  Writing project...
Created project at airplay-2-receiver/AirPlayReceiver.xcodeproj

$ … ls -ld AirPlayReceiver.xcodeproj && ls -l src/Info.plist test/Info.plist && ls AirPlayReceiver.xcodeproj
drwxr-xr-x  5 <user>  staff  160 Nov 16 17:13 AirPlayReceiver.xcodeproj
-rw-r--r--  1 <user>  staff  918 Nov 16 17:13 src/Info.plist
-rw-r--r--  1 <user>  staff  701 Nov 16 17:13 test/Info.plist
project.pbxproj
project.xcworkspace
xcshareddata

$ xcodebuild build airplay-2-receiver AirPlayReceiver iphonesimulator   # exit 0
...
** BUILD SUCCEEDED **
ok — log: …/20261116T151400Z-build.log
app bundle: airplay-2-receiver/build/Build/Products/Debug-iphonesimulator/AirPlayReceiver.app

$ … ls -l …/AirPlayReceiver.app/AirPlayReceiver && PlistBuddy CFBundleDisplayName && PlistBuddy MinimumOSVersion
-rwxr-xr-x  1 <user>  staff  123824 … AirPlayReceiver.app/AirPlayReceiver
AirPlay Receiver
15.0

$ xcodebuild test airplay-2-receiver AirPlayReceiver 'platform=iOS Simulator,name=iPhone 16e' \
    > /tmp/opencode/task-001-test.log                              # exit 0
Test Case '-[AirPlayReceiverTests.AppInfoTests testDisplayNameIsTheAdvertisedName]' passed (0.001 seconds).
	 Executed 1 test, with 0 failures (0 unexpected) in 0.001 (0.002) seconds
** TEST SUCCEEDED **
ok — log: …/20261116T152024Z-test.log

$ grep -E "Executed 1 test, with 0 failures" /tmp/opencode/task-001-test.log ; echo $?
0
$ grep -nE 'error:' /tmp/opencode/task-001-test.log ; echo $?
1

# criterion 4, in the generated project
$ … xcodebuild -list -project AirPlayReceiver.xcodeproj; grep -o "IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*;" …/project.pbxproj; grep productType …; ls …/xcshareddata/xcschemes/
    Targets:
        AirPlayReceiver
        AirPlayReceiverTests
    Schemes:
        AirPlayReceiver
   2 IPHONEOS_DEPLOYMENT_TARGET = 15.0;
92:			productType = "com.apple.product-type.bundle.unit-test";
AirPlayReceiver.xcscheme

# criterion 3 anti-accident: mutate the constant on the Mac copy, then sync to restore
$ sed -i "" "s/\"AirPlay Receiver\"/\"AirPlay Receiver MUTATED\"/" src/AirPlayReceiverApp.swift
9:    static let displayName = "AirPlay Receiver MUTATED"
$ xcodebuild test airplay-2-receiver AirPlayReceiver 'platform=iOS Simulator,name=iPhone 16e'  # exit 1
…/test/AppInfoTests.swift:9: error: -[AirPlayReceiverTests.AppInfoTests testDisplayNameIsTheAdvertisedName] : XCTAssertEqual failed: ("AirPlay Receiver MUTATED") is not equal to ("AirPlay Receiver")
	 Executed 1 test, with 1 failure (0 unexpected) in 0.274 (0.275) seconds
** TEST FAILED **
$ rsync -a <project> <build-host>:<build-dir>/ airplay-2-receiver &&
  shasum -a 256 src/AirPlayReceiverApp.swift
00ec5f60e31f4155cc33538f0353f518b71d2f5bd01d9e836009ca91e48c1779  src/AirPlayReceiverApp.swift   # = repo

# criterion 5: after a sync there is no .xcodeproj, so build must fail
$ xcodebuild build airplay-2-receiver AirPlayReceiver iphonesimulator  # exit 1
error: no .xcworkspace or .xcodeproj in airplay-2-receiver — run: xcodegen generate

# criterion 5's literal wording probed: regenerate, edit project.yml on the Mac copy, build
$ … xcodegen generate && sed -i "" 's/MARKETING_VERSION: "1.0"/MARKETING_VERSION: "9.9"/' project.yml
24:        MARKETING_VERSION: "9.9"
$ xcodebuild build airplay-2-receiver AirPlayReceiver iphonesimulator  # exit 0, stale project
$ PlistBuddy Print :CFBundleShortVersionString …/AirPlayReceiver.app/Info.plist
1.0                                                              # the 9.9 edit was not picked up

# R1
$ rsync -a <project> <build-host>:<build-dir>/ airplay-2-receiver &&
  xcodegen generate &&
  xcodebuild build airplay-2-receiver AirPlayReceiver iphonesimulator   # exit 0
ok — log: …   Created project at …   ** BUILD SUCCEEDED ** / ok — log: …/20261116T151710Z-build.log

# R2
$ xcodebuild test airplay-2-receiver AirPlayReceiver 'platform=iOS Simulator,name=iPhone 16e'  # exit 0
	 Executed 1 test, with 0 failures (0 unexpected) in 0.001 (0.002) seconds   # ×3 suite lines

# clean-room rebuild for criterion 2
$ rm -rf build
$ xcodebuild build airplay-2-receiver AirPlayReceiver iphonesimulator   # exit 0
** BUILD SUCCEEDED **                                             # 8 SwiftCompile lines

# the destination the task file still names
$ xcodebuild test airplay-2-receiver AirPlayReceiver 'platform=iOS Simulator,name=iPhone 16'   # exit 1
xcodebuild: error: Unable to find a device matching the provided destination specifier:

# static checks
$ grep -n 'iOS: "15.0"' airplay-2-receiver/project.yml            # 14:    iOS: "15.0"
$ grep -n 'AirPlayReceiverTests' airplay-2-receiver/project.yml   # 34, 54, 60
$ grep -c 'packages:' airplay-2-receiver/project.yml              # 0 (exit 1)
$ grep -nE 'packages?\b' airplay-2-receiver/project.yml           # no match
$ grep -c 'DEVELOPMENT_TEAM' airplay-2-receiver/project.yml       # 0
$ grep -n -A2 '^schemes:' airplay-2-receiver/project.yml          # 49:schemes: / 50-  AirPlayReceiver:
$ python3 -c 'yaml.safe_load(project.yml) …'
top keys: ['name', 'options', 'targets', 'schemes']
options.deploymentTarget: {'iOS': '15.0'}
targets: {'AirPlayReceiver': ('application','iOS',['src']), 'AirPlayReceiverTests': ('bundle.unit-test','iOS',['test'])}
schemes: ['AirPlayReceiver']
packages key present: False
scheme test targets: ['AirPlayReceiverTests']
$ grep -rnE 'XCTSkip|\.skip' airplay-2-receiver/test || echo 'no skips'
no skips
$ grep -nE 'xcodeproj|build/' airplay-2-receiver/.gitignore       # 2:*.xcodeproj/ / 5:build/
$ git check-ignore -v …/AirPlayReceiver.xcodeproj/project.pbxproj …/build/…/Info.plist
airplay-2-receiver/.gitignore:2:*.xcodeproj/	…
airplay-2-receiver/.gitignore:5:build/	…
$ git ls-files airplay-2-receiver | grep -E 'xcodeproj|Info\.plist|(^|/)build/' || echo 'none tracked'
none tracked

$ git status --porcelain --untracked-files=all                     # empty
```

## Scope

The task's start commit is `218749d`. `git log --format='--- %h %s' --name-status 218749d..HEAD`:

| Commit | Files | Owner / verdict |
| --- | --- | --- |
| `dd15fbb` TASK-001: implement the XcodeGen scaffold | `project.yml`, `.gitignore`, `src/AirPlayReceiverApp.swift`, `src/ContentView.swift`, `test/AppInfoTests.swift`, `journal/<role>.md` | exactly the five in-scope files plus the developer journal (PROCESS §5 step 10 requires it). Also `backlog/BOARD.md` and `backlog/tasks/TASK-001-scaffold.md` — the `in-progress → in-review` transition, BA bookkeeping (finding 5). |
| `3d99f81` TASK-001: record the BLOCKED verdict | `qa/reports/TASK-001-review.md`, `qa/TEST-PLAN.md`, `qa/REGRESSION.md`, `journal/{qa,ba}.md`, backlog, `docs/STATE.md` | BA commit of round 1's verdict; not the developer's deliverable. |
| `e5c3030`, `a2df4f3`, `f9028fc` `workspace/chore: …` | `docs/STATE.md`, the private build notes, the build bridge, the onboarding script, `airplay-2-receiver/docs/{STATE,DECISIONS}.md`, `journal/<role>.md` | workspace-level Mac-bridge work by the BA (`scripts/` and `docs/` are BA-owned). It changed the criterion-5 message text and made `remote_project_args` use `find`; both are covered by the evidence above. |

No `src/`, `test/`, `project.yml`, manifest or lockfile change exists outside
`dd15fbb`, and `dd15fbb` touches nothing outside the five files, the developer
journal and the two BA status lines. Working tree clean before and after this
review; the only writes this round were inside `airplay-2-receiver/qa/` and
`journal/<role>.md`.

## Findings

1. **MINOR (documentation lag) — `backlog/tasks/TASK-001-scaffold.md:69`** still
   names `platform=iOS Simulator,name=iPhone 16`; that destination does not exist
   on the Mac and the command fails with `Unable to find a device matching the
   provided destination specifier`. `DEC-005` replaces it with `iPhone 16e`, which
   is what criteria 2 and 3 were verified with. Owner: PM (task file). I fixed
   `qa/TEST-PLAN.md` A3/A4 and `qa/REGRESSION.md` R2 in this turn.
   Reproduce: `xcodebuild test airplay-2-receiver AirPlayReceiver 'platform=iOS Simulator,name=iPhone 16'`.

2. **MINOR (quoting) — `TASK-001:50-52` and `FEAT-001-discoverable.md:117-118`**
   quote the criterion-5 message as `no .xcodeproj or .xcworkspace`;
   `scripts/mac-build.sh:183` prints `no .xcworkspace or .xcodeproj in <dir> — run:
   … xcodegen generate`. Same condition, same fix, word order and suffix differ.
   The criterion is met on meaning; the task text is the thing to tidy. Owner: PM/
   BA; the message is workspace-owned and not TASK-001's to change.

3. **MINOR (criterion wording overstates the check) — `TASK-001:50-53`.** Taken
   literally, "`project.yml` is edited without regenerating on the Mac, when
   `build` runs, then it fails" is false: with a generated project still present,
   editing `project.yml` on the Mac copy and building exits 0 against the stale
   project (probe: `MARKETING_VERSION: "9.9"` in `project.yml`, build exit 0, the
   app's `CFBundleShortVersionString` stayed `1.0`). The failure that the criterion
   observes comes from `sync` deleting the `.xcodeproj` (`rsync --delete`), which is
   the mechanism `FEAT-001` Notes describes. Behaviour matches the documented
   process; the wording implies staleness detection that build does not
   do. Owner: PM/BA. If detection is wanted, the script owner adds a `project.yml`
   newer-than-`.xcodeproj` check — a workspace change, not TASK-001.

4. **MINOR — `airplay-2-receiver/.gitignore:1-5`** does not ignore the two
   plists `xcodegen` writes inside the tree (`src/Info.plist`, `test/Info.plist`;
   `project.yml:28,46`). Confirmed today: `git check-ignore -q` → `NOT ignored`
   for both. They exist only on the Mac copy and the repo is clean
   (`git ls-files` → `none tracked`), so nothing leaks by itself; the exposure is
   an agent running `xcodegen generate` inside the repo and then `git add -A`.
   Smallest fix: add the two paths to `.gitignore` in TASK-002. Owner: developer.

5. **MINOR — `project.yml:30` vs `src/AirPlayReceiverApp.swift:9`** — the display
   name `AirPlay Receiver` is written twice (`CFBundleDisplayName` and
   `AppInfo.displayName`). They agree today (built product's plist reads
   `AirPlay Receiver`) and the test pins only the Swift constant, so the home-screen
   name could drift while the suite stays green. Not a criterion. Owner: decide in
   TASK-002 (one source, or a check that the two agree).

6. **MINOR — `dd15fbb` also moves TASK-001 to `in-review` in `backlog/BOARD.md`
   and `backlog/tasks/TASK-001-scaffold.md`**, which the task reserves for the BA.
   Carried unchanged from round 1: the commit message and `journal/<role>.md` show this
   is the BA committing its own bookkeeping next to the developer's files, not a
   developer scope breach. Not a code or config violation. Also note `journal/` is
   in the task's "do not touch" list while PROCESS §5 step 10 requires a developer
   journal entry — the task text and the process disagree; the journal entry is
   correct behaviour. Owner: PM/BA.

Round-1 findings re-checked: finding 2 (`sync --delete` removes the generated
project and both plists) is now **observed**, not just read — after `sync`,
`ls -d *.xcodeproj` → `no matches found` and both plists missing. The TEST-PLAN
preamble already says to regenerate after every sync; `qa/REGRESSION.md` R1's
command does. Finding 3 (R3's scheme grep) stayed fixed: `grep -A1 '^schemes:'`
is what R3 uses and it finds `AirPlayReceiver:` at `project.yml:49-50`, now
cross-checked with `xcodebuild -list`.

None of the six findings is blocking and none contradicts a criterion.

## Regressions

From `qa/REGRESSION.md`, run today on this host and the Mac:

- **R1** (simulator build) — **PASS**: `sync` → `xcodegen generate` → `build
  … iphonesimulator`, exit 0, `Created project at …`, `** BUILD SUCCEEDED **`,
  `ok — log: …/20261116T151710Z-build.log`, app bundle printed. Also green from an
  emptied derived-data directory.
- **R2** (unit tests, count ≥ 1) — **PASS**: exit 0, `Executed 1 test, with 0
  failures` (`…/20261116T151716Z-test.log`; the cold-bundle run
  `…/20261116T152024Z-test.log` repeats it). High-water mark stays **1**;
  TASK-002 must raise it.
- **R3** (`project.yml` contract) — **PASS**, now static **and** on the generated
  project: `packages:` 0 (and the word absent), `iOS: "15.0"` at `:14`, scheme
  `AirPlayReceiver` at `:49-50`, `DEVELOPMENT_TEAM` 0, `xcodebuild -list` lists
  both targets and the scheme, `project.pbxproj` has
  `IPHONEOS_DEPLOYMENT_TARGET = 15.0`.
- **R4** (port 7000 answers twice) — **not applicable yet**: the behaviour is
  TASK-003's deliverable and does not exist in this tree. The Mac prerequisite is
  now green, so R4 can be run when TASK-003 lands.
- **R5** (no skipped tests, generated project out of version control) — **PASS**:
  `no skips`; `.gitignore:2` `*.xcodeproj/`, `.gitignore:5` `build/`;
  `git check-ignore` attributes both; no generated file tracked.
- **R6** (new — the scaffold test is not vacuous) — **PASS**: the mutation run
  above. Added to `qa/REGRESSION.md` this turn.

No regression failed. R1/R2 moved from `BLOCKED` to green, which is the only
status change.

## Unverifiable here

- **Device behaviour.** No iPhone 6s is connected to this Mac (`xcrun devicectl
  list devices` shows a paired iPhone 14 Pro and two unavailable iPhones; no 6s).
  Nothing in TASK-001 is device-only — criteria 1-5 are simulator and file checks,
  all proven — but `FEAT-001` S1b/S1c/S5 remain unverifiable until the human runs
  O1-O5.
- **iOS 15.0 *runtime* behaviour.** The only iPhone-shaped iOS 26.5 simulator is
  `iPhone 16e`; 15.0 is proven as a compile-time target
  (`-target arm64-apple-ios15.0-simulator` in the test log) and as the built
  `MinimumOSVersion`, not by running on iOS 15.
- **The Apple TV speaker list.** Human only; not part of TASK-001.

## Verdict

Every criterion has evidence produced on the Mac today: `check` exit 0 with Xcode
26.6, `xcodegen generate` creating the project from a synced tree, a clean
simulator build and a real `Executed 1 test, with 0 failures` that was proven to
fail when the asserted constant changes, the `project.yml` contract confirmed in
the generated project, and the documented `no .xcworkspace or .xcodeproj` failure
when the generated project is absent. The regression list is green (R4 pending by
design). The six findings are MINOR and none is a criterion failure.

**Verdict:** PASS

**Next:** the BA can take TASK-001 to `done`. Raise `qa/REGRESSION.md` R2's
high-water mark to 1 when TASK-002 adds tests (expected 6), and send findings 1-3
to the PM/BA for the task texts and 4-5 to the developer for TASK-002.
