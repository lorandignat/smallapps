---
id: TASK-008-review
task: TASK-008
feature: FEAT-001
verdict: PASS
date: 2026-11-20
attempt: 2
---

# Review — TASK-008 Export the diagnostic log to a file

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Given two log entries, `export()` writes `airplay-receiver-log.txt` in the temporary directory with the two entry strings, same order, joined by `\n`, one trailing `\n` | **PASS** | Code: `fileName = "airplay-receiver-log.txt"` (`play-two/src/Diagnostics/EventLogExport.swift:16`); `directory.appendingPathComponent(fileName)` (`:28`); `Data(entries.map { $0 + "\n" }.joined(separator: "").utf8)` (`:31`). Test `testExportWritesTheTwoEntriesAsLinesInOrder` asserts the literal name (`play-two/test/EventLogExportTests.swift:30`), the file exists (`:31`) and the exact bytes `entries[0] + "\n" + entries[1] + "\n"` (`:35-39`); it passed (`/tmp/opencode/task-008-test.log:207`). The assertion is load-bearing: dropping `+ "\n"` on the Mac copy failed it with `XCTAssertEqual failed: ("…Restart…Advertising…") is not equal to ("…Restart\n…Advertising…\n")` (`20261120T004008Z-test.log:260`, suite failed `:260-262`, `Executed 33 tests, with 1 failure` `:321`, `** TEST FAILED **` `:323`); restored by `sync` + `xcodegen generate`, sha256 `e0bdcfd0…c493` = repo. |
| 2 | Given an empty log, `export()` still returns a 0-byte file and the screen's export control stays enabled | **PASS** | `Data("".utf8)` writes 0 bytes (`EventLogExport.swift:31`); `testExportOfAnEmptyLogReturnsAZeroByteFile` asserts `.success`, the file exists and `contents?.count == 0` (`EventLogExportTests.swift:44-52`) and passed (`/tmp/opencode/task-008-test.log:205`). The control is unconditional: `Button("Export Log") { didTapExport() }` has no `.disabled(...)` (`play-two/src/ContentView.swift:30-32`); my screenshot of the launched app shows the button blue/enabled (`.tooling/qa-scratch/task-008-screen-qa.png`, pid `com.lorand.playtwo: 89444`, `20261120T003540Z-run.log`). |
| 3 | Given an unwritable directory, `export()` returns `.failure` with the underlying message; the screen shows exactly `Export failed: <message>` and the status text is unchanged | **PASS** | `testExportFailsWhenTheDirectoryCannotBeWritten` creates a `0o500` directory and asserts `.failure` with a non-empty message (`EventLogExportTests.swift:56-70`); it passed (`/tmp/opencode/task-008-test.log:203`). The message is the underlying one: `EventLogExportError(message: (error as NSError).localizedDescription)` (`EventLogExport.swift:35-36`). The screen renders it in its own red `Text(exportError)` (`ContentView.swift:26-29`) as `"Export failed: \(error.message)"` (`:50-52`); `didTapExport` never touches `status`, and the status line reads `status.statusText(name: AppInfo.displayName)` (`:24`), so the status text is unchanged. Test-strength gap recorded as finding 3. |
| 4 | Given the simulator, when the export control is tapped, the iOS share sheet opens showing `airplay-receiver-log.txt` | **N/A — relocated to O6 human observation at feature close** | Not an acceptance criterion of TASK-008 after the PM re-cut (2026-11-20): the tap is deferred to `qa/TEST-PLAN.md` O6 and reported at FEAT-001 close. Wiring verified here: button present and enabled (screenshot `.tooling/qa-scratch/task-008-screen-qa.png`, run log `20261120T003540Z-run.log`, pid `com.lorand.playtwo: 89444`); success sets `exportedFile = ExportedFile(url: url)` (`play-two/src/ContentView.swift:49`), `.sheet(item: $exportedFile) { ShareSheet(fileURL: file.url) }` (`:35-37`), and `ShareSheet` is `UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)` (`:68-70`). The exported URL is proven by criteria 1-2. The tap itself — simulator presenting the sheet on a tap and showing `airplay-receiver-log.txt` — is deferred to O6 (`Export: share sheet opened, file "airplay-receiver-log.txt", N lines` or `Export: FAIL — <what appeared>`). |
| 5 | `EventLogExportTests` passes: `Executed 3 tests, with 0 failures` | **PASS** | `/tmp/opencode/task-008-test.log:208-209`: `Test Suite 'EventLogExportTests' passed at 2026-11-20 02:41:13.211.` · `Executed 3 tests, with 0 failures (0 unexpected) in 0.019 (0.020) seconds`; whole run `Executed 33 tests, with 0 failures` (`:267,269`), `** TEST SUCCEEDED **` (`:277`); mirror `20261120T004105Z-test.log:210,269,271,279`. |

## What I ran

Host (static), from the workspace root — all green:

```sh
ls -l play-two/src/Diagnostics/EventLogExport.swift                 # present, 1848 bytes
grep -n 'airplay-receiver-log.txt' play-two/src/Diagnostics/EventLogExport.swift   # 16
grep -c 'packages:' play-two/project.yml                            # 0
grep -n 'iOS: "15.0"' play-two/project.yml                          # 13
grep -A1 '^schemes:' play-two/project.yml                           # "PlayTwo:"
grep -c 'DEVELOPMENT_TEAM' play-two/project.yml                     # 0
grep -rnE 'XCTSkip|\.skip' play-two/test || echo 'no skips'         # no skips
grep -nE 'xcodeproj|build/' play-two/.gitignore                     # :2, :5
grep -rn 'AirPlayReceiver' play-two/project.yml play-two/src play-two/test   # none
grep -c 'bundleIdPrefix' play-two/project.yml                       # 0
grep -c 'CFBundleDisplayName' play-two/project.yml                  # 0
git check-ignore -v play-two/src/Info.plist play-two/test/Info.plist # both .gitignore:8, :9
grep -n 'static let features: UInt64 = 0x3C356BD04A7FCA00' play-two/src/AirPlay/AirPlayTXTRecord.swift  # :23; bit 38 True
grep -n 'static let response = "RTSP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n"' play-two/src/Net/ReceiverListener.swift  # :17
grep -n 'status.statusText(name: AppInfo.displayName)' play-two/src/ContentView.swift  # :24
grep -nF 'Advertising as \(name)' play-two/src/AppState.swift        # :15
grep -nF 'Error: \(message)' play-two/src/AppState.swift             # :17
grep -n 'case .inactive' play-two/src/AppState.swift                 # :108
grep -n 'handleScenePhase' play-two/src/PlayTwoApp.swift             # :36
```

Mac bridge (exit codes in the log names/paths):

```sh
xcodebuild -version                                         # exit 0 — Xcode 27.2, 27B52, iPhone 16e connected (OS 26.5); 20261120T003418Z-check.log
rsync -a <project> <build-host>:<build-dir>/                                 # exit 0 — …003422Z-sync.log
xcodegen generate   # exit 0 — …003424Z-run.log
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.5' | tee /tmp/opencode/task-008-test.log   # exit 0
xcodebuild build -scheme PlayTwo -sdk iphonesimulator        # exit 0 — …003434Z-build.log
xcodebuild -list …  # exit 0 — …003533Z-run.log
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e'   # exit 1, the task's literal command
```

The task's literal destination (no `,OS=26.5`) fails before building: `xcodebuild: error: Unable to find a device matching the provided destination specifier` (`20261120T003845Z-test.log:11`). The `,OS=26.5` qualifier is the same one already used by R10 and TASK-004..007; the canonical run above uses it.

Mutation probe (Mac copy only, restored): replaced ` $0 + "\n"` with ` $0` in `src/Diagnostics/EventLogExport.swift`, ran the suite → exit 1, `EventLogExportTests` 1 failure (`/tmp/opencode/task-008-mutant-content.log:258-262`, `…321,323`; mirror `20261120T004008Z-test.log`), then `sync` + `xcodegen generate`; `sha256sum` on both sides now `e0bdcfd0…c493` / `7c0a7ccc…d1b6` / `b96c0ba6…e434` / `73a4aead…89fc`, identical to the repo, and the restored suite is green (canonical log). No repo file changed.

UI presence: installed and launched the built app on `iPhone 16e`, screenshot `xcrun simctl io booted screenshot` (`.tooling/qa-scratch/task-008-screen-qa.png`, run log `20261120T003540Z-run.log`). It shows `PlayTwo`, the status line and the blue, enabled `Export Log` button. The status happens to read `Error: the listener failed: POSIXErrorCode(rawValue: 48): Address already in use` — the Mac's ControlCenter holds port 7000 in the simulator (`DEC-010`), unrelated to this task.

Tap attempt: `osascript` + System Events against the Simulator was tried through the Aqua session; it hung on the Mac's TCC/accessibility gate (`…003608Z-gui.log`). The process and `/tmp/macbuild-gui` were killed/removed (`…003811Z-run.log`, `…003813Z-run.log`). No click was delivered.

## Findings

1. **MAJOR (scope / task definition — needs a BA or PM decision, not code rework)** — `play-two/src/PlayTwoApp.swift:33` (commit `2c4c0b0`) adds `eventLog: appState.eventLog`, although the task's "Files in scope (3)" and its "Explicitly do not touch" list both exclude that file. The line is required: `ContentView.eventLog` otherwise defaults to a fresh empty `EventLog()` (`src/ContentView.swift:11`), so every export would be a 0-byte file and the task goal ("export the diagnostic log") would not be met; every alternative (environment object, singleton) also needs this file or `src/AppState.swift`, which is likewise forbidden. Repro: `git show --stat 2c4c0b0` → `play-two/src/PlayTwoApp.swift | 2 +-`; `git show 2c4c0b0 -- play-two/src/PlayTwoApp.swift`. Smallest acceptable fix: amend TASK-008's file list to include the one-line `PlayTwoApp.swift` wiring (or record acceptance at G4). Do **not** revert the line — the code is correct and necessary; the task text is what is wrong.

2. **MINOR (task file, PM-owned)** — `backlog/tasks/TASK-008-export-log.md:61` uses the bare destination `'platform=iOS Simulator,name=iPhone 16e'`. On the current Mac (Xcode 27.2; the only 16e is OS 26.5 while the newest runtime is 27.2) that command exits 1 with `xcodebuild: error: Unable to find a device matching the provided destination specifier` (`20261120T003845Z-test.log:11`), before any code is built. Repro: run the task's command verbatim from the workspace root. Fix: add `,OS=26.5` to the command, as R10 already does; `docs/STACK.md:17` has the same stale command (BA-owned — hand it over, do not edit here). I updated `qa/TEST-PLAN.md` A3 in this turn.

3. **MINOR (test strength, criterion 3)** — `play-two/test/EventLogExportTests.swift:69` asserts only that `error.message` is non-empty; it does not pin "the underlying message" that criterion 3 names. A regression at `EventLogExport.swift:36` replacing `(error as NSError).localizedDescription` with a constant (e.g. `"error"`) would leave the suite 3/3 green. Repro: make that one-word change on the Mac copy, regenerate, run `EventLogExportTests`; all three still pass. Fix: assert the returned message equals or contains the error obtained by attempting the same `Data.write` into the unwritable directory in the test, or at least contains the file name / permission wording.

4. **OBSERVATION (outside TASK-008's files)** — the log line is `timestamp + message` with no separator (`play-two/src/Diagnostics/EventLog.swift:23`), so the exported evidence reads `2026-11-20 00:33:03.578Restart` rather than `…578 Restart`. Criterion 1 is met line-for-line; this is TASK-007's format contract and not this task's call, but the human-facing evidence is harder to scan. Carry it to feature close / TASK-007 if the BA wants a space.

## Regressions

From `qa/REGRESSION.md`, run in full on this host and through the Mac bridge:

- **R1 pass** — build exit 0, `** BUILD SUCCEEDED **` (`20261120T003434Z-build.log:199`), app at `build/Build/Products/Debug-iphonesimulator/PlayTwo.app`.
- **R2 pass** — `Executed 33 tests, with 0 failures` (`/tmp/opencode/task-008-test.log:267,269`), `** TEST SUCCEEDED **` (`:277`). Suite split: AirPlayTXTRecordTests 7 + AppInfoTests 1 + AppStateTests 4 + EventLogExportTests 3 + EventLogTests 5 + ReceiverListenerTests 5 + ReceiverStatusTests 4 + ServiceAdvertiserTests 4. High-water mark raised **30 → 33** in `qa/REGRESSION.md` (new row R11).
- **R3 pass** — static: `packages:` 0, `iOS: "15.0"` at `project.yml:13`, scheme `PlayTwo`, `DEVELOPMENT_TEAM` 0. Mac: `xcodebuild -list -project PlayTwo.xcodeproj` → targets `PlayTwo`/`PlayTwoTests`, scheme `PlayTwo`; `IPHONEOS_DEPLOYMENT_TARGET = 15.0;` twice (`20261120T003533Z-run.log`).
- **R4 pass (unit half)** — `ReceiverListenerTests` 5/5 (`/tmp/opencode/task-008-test.log:240`); the 38-byte literal is still at `play-two/src/Net/ReceiverListener.swift:17`. The app-level port-7000 half was verified on the device in TASK-004's review (`nc … 7000`); unchanged here.
- **R5 pass** — `no skips`; `.gitignore` has `*.xcodeproj/` (:2) and `build/` (:5).
- **R6 not applicable** — the scaffold test and the display-name contract are unchanged by TASK-008; per the row this one-off probe runs only when those change.
- **R7 pass** — no `AirPlayReceiver`; `bundleIdPrefix` 0; `CFBundleDisplayName` 0; both generated plists ignored (`.gitignore:8-9`).
- **R8 pass** — `AirPlayTXTRecordTests` 7/7 (`/tmp/opencode/task-008-test.log:183`); constant at `AirPlayTXTRecord.swift:23`; bit 38 `True`.
- **R9 pass** — `ReceiverStatusTests` 4/4 (`/tmp/opencode/task-008-test.log:251`); statics at `ContentView.swift:24`, `AppState.swift:15,17`.
- **R10 pass** — `AppStateTests` 4/4 (`/tmp/opencode/task-008-test.log:199`); `case .inactive` at `AppState.swift:108`; `handleScenePhase` at `PlayTwoApp.swift:36`. The real-app active-restart half retains TASK-006's caveat, unchanged.

## Unverifiable on this host

- **Criterion 4's tap.** The Mac bridge can install, launch and screenshot the simulator, but it cannot deliver a touch. `simctl` has no tap/click subcommand; a System Events AppleScript click is blocked by the Mac's TCC gate (attempt hung, killed, logs above). Missing: a person at the Mac to open the launched app on the `iPhone 16e` simulator and tap `Export Log`, then report the exact `qa/TEST-PLAN.md` O6 result — `Export: share sheet opened, file "airplay-receiver-log.txt", N lines` — or the failure. Everything up to the tap is verified above.
- Device/Apple TV observations O1-O5 are human-only and not part of TASK-008.
- R3's Mac half and all build/test results are quoted from build output on this host's bridge, not from a local toolchain.

## Verdict

**PASS** — criteria 1, 2, 3 and 5 are verified on this host and on the Mac (`EventLogExportTests` 3/3, whole run 33/33), regressions R1-R5, R7-R10 (and R11) pass, and criterion 4 (share sheet on tap) is no longer an acceptance criterion of TASK-008: it is relocated to `qa/TEST-PLAN.md` O6, a human observation at FEAT-001 close, with its wiring verified here. No code changed in this reconciliation.

**Next:** O6 is reported at FEAT-001 close (`Export: share sheet opened, file "airplay-receiver-log.txt", N lines` or `Export: FAIL — <what appeared>`); the BA/PM amends TASK-008's file list for the `PlayTwoApp.swift` wiring (finding 1) and puts `,OS=26.5` in the task's verification command (finding 2) before commit. Findings 3-4 carry to feature close.

## Reconciliation

Re-cut 2026-11-20 (PM): acceptance criterion 4 (share sheet opens on tap showing
`airplay-receiver-log.txt`) is no longer a criterion of TASK-008; it is relocated
to `qa/TEST-PLAN.md` O6 as a human observation at FEAT-001 close. Criteria 1, 2,
3 and 5 are unchanged and were already verified in attempt 2 (all PASS; suite
33/33; regressions R1-R5, R7-R10 pass; R2 high-water 30 → 33). No code, test,
backlog or regression-list file changed in this reconciliation — only this report's
verdict and the criterion-4 row. The wiring (button present and enabled,
`.sheet` → `UIActivityViewController` over the exported URL) was verified and is
recorded above; the tap itself is deferred to O6.
