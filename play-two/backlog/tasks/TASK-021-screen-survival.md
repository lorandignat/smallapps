---
id: TASK-021
title: Restart survival — show the setup code and paired state on the state screen
feature: FEAT-003
status: in-progress
attempts: 1
owner: null
depends_on: [TASK-020]
estimate: small
---

# TASK-021 — Restart survival — show the setup code and paired state on the state screen

## Goal

The state screen shows the setup code (`HAPServer.setupCode`, `00102003` — the
fixed constant of `TASK-016`) and the paired state: on launch with a stored
pairing the status reads `Paired`, and while advertising it stays `Paired`
(restart survival, half 2; the Home-app half is TASK-020's `sf`).

## Context for the developer

- Where it lives: `src/AppState.swift` (modified), `src/ContentView.swift`
  (modified).
- Interfaces it may touch: `ReceiverStatus` (new case `.paired`),
  `AppState.init(advertiser:pairingStore:)`, `AppState.handleAdvertiserState`,
  `HAPServer.setupCode`, `HAPPairingStore` (the injected store).
- Files in scope (4): `src/AppState.swift` (modified), `src/ContentView.swift`
  (modified), `test/AppStateTests.swift` (modified),
  `test/ReceiverStatusTests.swift` (modified).
- Explicitly **do not** touch: `project.yml`, `src/PlayTwoApp.swift`,
  `src/HAP/*`, `src/Net/`, `src/Diagnostics/`, `src/AirPlay/`, `docs/`, `qa/`,
  journals other than `journal/<role>.md`, `scripts/`, `.opencode/`.

## Acceptance criteria

1. [ ] Given `HAPPairingStore` records `paired: true`, when the app relaunches
       (`AppState(advertiser: SpyAdvertiser(), pairingStore: store)`), then
       `appState.status == .paired` and `appState.status.statusText(name:
       AppInfo.displayName) == "Paired"` — `AppState.status` starts as
       `.paired` and `AppState.map(.advertising)` returns `.paired` while
       `pairingStore.paired`.
2. [ ] Given the same stored pairing, when `appState.scenePhaseChanged(.active)`
       runs (the advertiser reports `.advertising`), then `appState.status == .paired`.
3. [ ] The state screen shows the setup code: `ContentView` displays
       `HAPServer.setupCode` — static: `grep -n 'Setup code' play-two/src/ContentView.swift`
       → found; `grep -n 'static let setupCode = "00102003"' play-two/src/HAPServer.swift`
       → found (TASK-016's constant; the pairing flow uses it via `HAPServer.setupCode`).
4. [ ] `AppStateTests` passes: `Executed 5 tests, with 0 failures` — the four
       from TASK-020 (default store reads `.idle`; `testStatusIsPairedWhenThePairingIsStored`).
5. [ ] `ReceiverStatusTests` passes: `Executed 5 tests, with 0 failures` — the
       four from TASK-019 plus `testPaired`
       (`ReceiverStatus.paired.statusText(name: AppInfo.displayName) == "Paired"`).
6. Regression: `R2` count ≥ 81 (expect ≈ 81 after the run; QA/BA update `qa/REGRESSION.md`).

## Verification commands

```sh
# on this host
ls play-two/src play-two/test
# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.2' | tee /tmp/opencode/task-021-test.log
grep -E "Test Suite '(AppStateTests|ReceiverStatusTests)' (passed|failed)" /tmp/opencode/task-021-test.log
grep -c 'Setup code' play-two/src/ContentView.swift        # expect 1
grep -n 'static let setupCode = "00102003"' play-two/src/HAPServer.swift
```

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-021-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes: `R2` count ≥ 81 (expect ≈ 81 after the run; QA/BA update `qa/REGRESSION.md`)
- [ ] One commit `play-two/TASK-021: restart survival — show the setup code and paired state on the state screen` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- S2b is the human observation at feature close: with the pairing stored, the
  Home app shows no re-pair prompt and the app's state screen reads `Paired`.
  The unit tests here cover the launch state and the advertising mapping.
- `AppState.map` changes signature (adds the store); the only caller is
  `handleAdvertiserState`.
- The status line renders through the existing `ContentView` status `Text`
  (TASK-005), so no new screen plumbing is needed — the new `Text` line for
  the setup code is the only screen change.
- TASK-017 (the store) must be done first — `AppState` reads
  `HAPPairingStore.shared.paired`.
