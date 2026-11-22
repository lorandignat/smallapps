---
id: TASK-021-review
task: TASK-021
feature: FEAT-003
verdict: PASS
date: 2026-11-22
attempt: 1
---

# Review — TASK-021 Restart survival — show the setup code and paired state on the state screen

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Stored `paired: true` → `AppState.status == .paired` at launch, `statusText(...) == "Paired"`, and `map(.advertising)` stays `.paired` while paired | PASS | `src/AppState.swift:77` `status = pairingStore.paired ? .paired : .idle`; `src/AppState.swift:142` `return pairingStore.paired ? .paired : .advertising`; `src/AppState.swift:17-18` `.paired → "Paired"`. `test/AppStateTests.swift:121-145` seeds a fresh Keychain store with `paired: true`, asserts launch `.paired`, the `"Paired"` render, and that `.advertising` mapping keeps `.paired`. Log: `Test Case '-[PlayTwoTests.AppStateTests testStatusIsPairedWhenThePairingIsStored]' passed (0.010 seconds)` (`20261122T140413Z-test.log:351`). The unpaired path (`freshService()`, no record) asserts `.idle` at `:127`, so the flag, not mere store presence, drives it. |
| 2 | Same stored pairing, `scenePhaseChanged(.active)` (advertiser reports `.advertising`) → status stays `.paired` | PASS | `test/AppStateTests.swift:149-152`: forces `pairedSpy.state = .stopped`, calls `pairedState.scenePhaseChanged(.active)`, then asserts `startCount == 1` and `status == .paired`. This drives the real path `handleScenePhase(.active)` → `advertiser.start()` → `onStateChange(.advertising)` → `handleAdvertiserState` → `map(.advertising)` → `.paired`; if `map` returned `.advertising` the assertion would fail. Same passing test at log `:351`. |
| 3 | State screen shows the setup code: `ContentView` displays `HAPServer.setupCode`; constant `= "00102003"` | PASS | `grep -c 'Setup code' play-two/src/ContentView.swift` → `1`: `:26` `Text("Setup code: \(HAPServer.setupCode)")`. `grep -rn 'static let setupCode = "00102003"' play-two/src/` → `src/HAP/HAPServer.swift:22:    static let setupCode = "00102003"`. The task-text grep path `src/HAPServer.swift` does not exist (see finding 1); intent checked at the real path. |
| 4 | `AppStateTests` passes `Executed 5 tests, with 0 failures` | PASS | Log `Test Suite 'AppStateTests' passed` (`:354`) / `Executed 5 tests, with 0 failures (0 unexpected)` (`:355`); per-case `testStatusIsPairedWhenThePairingIsStored` passed (`:351`). Five = four pre-existing lifecycle tests (TASK-006) + the new paired test. No test removed or skipped (`grep -rnE 'XCTSkip|\.skip' play-two/test` → `no skips`). |
| 5 | `ReceiverStatusTests` passes `Executed 5 tests, with 0 failures`, incl. `testPaired` (`"Paired"`) | PASS | Log `Test Suite 'ReceiverStatusTests' passed` (`:468`) / `Executed 5 tests, with 0 failures (0 unexpected)` (`:469`); `Test Case '-[PlayTwoTests.ReceiverStatusTests testPaired]' passed (0.001 seconds)` (`:465`). `test/ReceiverStatusTests.swift:32-38` asserts `ReceiverStatus.paired.statusText(name: AppInfo.displayName) == "Paired"`. |
| 6 | Regression: R2 count ≥ 81 (≈81 after run) | PASS | Bundle `Executed 81 tests, with 0 failures (0 unexpected)` (`20261122T140413Z-test.log:528,530`) and `** TEST SUCCEEDED **` (`:538`); exit 0. High-water raised 79 → 81 in `qa/REGRESSION.md` this turn. |

## What I ran

```sh
# host / static verification (this host)
$ git diff --stat
 play-two/backlog/BOARD.md                          |  2 +-
 play-two/backlog/tasks/TASK-021-screen-survival.md |  2 +-
 play-two/journal/<role>.md                            | 77 ++++++++++++++++++++++
 play-two/src/AppState.swift                        | 24 +++++--
 play-two/src/ContentView.swift                     |  2 +
 play-two/test/AppStateTests.swift                  | 49 ++++++++++++++
 play-two/test/ReceiverStatusTests.swift            |  7 ++
 7 files changed, 156 insertions(+), 7 deletions(-)
# BOARD.md / TASK-021 .md diffs are BA workflow status edits (in-progress -> in-review),
# not developer changes. Developer diff is exactly the 4 allowed source/test files + journal/<role>.md.

$ xcodebuild -version     # exit 0
== xcode ==
Xcode 14.2
Build version 14C18
log: 20261122T142145Z-check.log

$ grep -c 'Setup code' play-two/src/ContentView.swift
1
$ grep -rn 'static let setupCode = "00102003"' play-two/src/
play-two/src/HAP/HAPServer.swift:22:    static let setupCode = "00102003"

$ (grep -rnE 'XCTSkip|\.skip' play-two/test || echo 'no skips')
no skips
$ grep -c 'packages:' play-two/project.yml; grep -n 'iOS: "15.0"' play-two/project.yml; grep -A1 '^schemes:' play-two/project.yml; grep -c 'DEVELOPMENT_TEAM' play-two/project.yml
0
13:    iOS: "15.0"
schemes:
  PlayTwo:
0
$ git check-ignore -v play-two/src/Info.plist play-two/test/Info.plist   # both ignored by play-two/.gitignore

# Mac test (developer's completed full run — quoted from the mirror of the brief's log)
$ grep -nE '\*\* TEST SUCCEEDED \*\*|Executed 81 tests|Test Suite .(AppStateTests|ReceiverStatusTests). passed' 20261122T140413Z-test.log
354:Test Suite 'AppStateTests' passed at 2026-11-22 16:04:22.070.
468:Test Suite 'ReceiverStatusTests' passed at 2026-11-22 16:10:40.619.
528:	 Executed 81 tests, with 0 failures (0 unexpected) in 841.306 (841.354) seconds
538:** TEST SUCCEEDED **

# QA's own independent re-run (sync -> xcodegen generate -> same test destination), exit 0
$ grep -nE "testStatusIsPairedWhenThePairingIsStored.*passed|ReceiverStatusTests testPaired.*passed|Test Suite '(AppStateTests|ReceiverStatusTests)' passed|Executed 81 tests|\*\* TEST SUCCEEDED \*\*" 20261122T142159Z-test.log
153:Test Case '-[PlayTwoTests.AppStateTests testStatusIsPairedWhenThePairingIsStored]' passed (0.014 seconds).
156:Test Suite 'AppStateTests' passed at 2026-11-22 16:22:05.894.
267:Test Case '-[PlayTwoTests.ReceiverStatusTests testPaired]' passed (0.001 seconds).
270:Test Suite 'ReceiverStatusTests' passed at 2026-11-22 16:28:26.864.
330:	 Executed 81 tests, with 0 failures (0 unexpected) in 840.019 (840.067) seconds
340:** TEST SUCCEEDED **
```

QA re-ran the full suite independently from a fresh `sync` + `xcodegen generate` on the same destination; it completed with `** TEST SUCCEEDED **`, AppStateTests 5/0 (`:156-157`), ReceiverStatusTests 5/0 (`:270-271`), and bundle `Executed 81 tests, with 0 failures` (`:330,332`). This independently reproduces the developer's run — the criteria rest on two independent green runs plus static inspection of the changed code.

## Findings

1. **LOW** — task text, verification command at `TASK-021-screen-survival.md:47,67` — the grep path `play-two/src/HAPServer.swift` does not exist; the constant is at `src/HAP/HAPServer.swift:22`. Repro: run the brief's grep → `grep: play-two/src/HAPServer.swift: No such file or directory` (exit 1). This is a task-text defect, not a code defect — the `ContentView` reference `HAPServer.setupCode` resolves correctly in-module and the constant is present. Fix: BA corrects the verification command path in the task text.
2. **LOW** — task text, criterion 4 at `TASK-021-screen-survival.md:49-50` — "the four from TASK-020" mislabels the four pre-existing `AppStateTests` (introduced by TASK-006); TASK-020 added an AirPlay TXT test, not AppState tests. Repro: `git log` on `test/AppStateTests.swift` shows the four lifecycle tests predating TASK-020. No test was removed; 4 + 1 new = 5. Fix: BA rewords to "the four existing AppStateTests (TASK-006)".

Both findings are documentation typos outside the implemented behaviour; they do not fail any criterion. No MAJOR/BLOCKER findings.

## Regressions

From `qa/REGRESSION.md` R1–R15: all green in the 81/0 bundle (`20261122T140413Z-test.log`) — R1 build, R2 (`Executed 81 tests, with 0 failures`, high-water 79 → 81 updated this turn), R4 `ReceiverListenerTests`, R8 `AirPlayTXTRecordTests` 7 tests, R9 `ReceiverStatusTests` now 5 (incl. `testPaired`), R10 `AppStateTests` now 5 (incl. `testStatusIsPairedWhenThePairingIsStored`), R11 `EventLogExportTests` 3, R12/R13/R14 `SRPTests` 14, R15 `HAPPairVerifyTests`/`HAPServerTests`. Static R3, R5, R7 re-run on this host this turn: all pass (no packages, iOS 15.0, scheme `PlayTwo`, no signing team, no skips, no old product name, generated plists ignored). R6 is a one-off mutation probe; last passed TASK-002 and is not due here (display-name contract unchanged). No regression row deleted or failing.

`qa/REGRESSION.md` updated this turn: R2 high-water 79 → 81 with run citation; R9 per-suite count 4 → 5 with `testPaired`; R10 per-suite count 4 → 5 with `testStatusIsPairedWhenThePairingIsStored`.

## Unverifiable on this host

- Genuine app relaunch with the Home app showing no re-pair prompt and the state screen reading `Paired` is S2b — a human observation at feature close, not a unit test. Unit tests cover the launch state and advertising mapping only.
- The setup-code `Text` line is verified statically (grep), not by rendering the view. Both limitations are by design of criteria 1–3 and the task's Notes; they are not gaps against the acceptance criteria.

## Verdict

All 6 criteria have evidence, the full suite is green at 81/0 in two independent runs (developer's and QA's own re-run), scope is respected, and the regression list passes. Two LOW task-text typos are recorded for the BA but fail no criterion.

**Verdict:** PASS

**Next:** BA G4 — commit `play-two/TASK-021: restart survival — show the setup code and paired state on the state screen`, mark TASK-021 done, and hand the two LOW task-text corrections to the PM/BA for the task file. S2b remains a human observation at feature close.
