---
id: TASK-005
title: Show the receiver state on the main screen
feature: FEAT-001
status: proposed
attempts: 0
owner: null
depends_on: [TASK-004]
estimate: small
---

# TASK-005 — Show the receiver state on the main screen

## Goal

The one screen tells the owner what the receiver is doing right now: idle,
advertising under a named service, stopped, or failing with a message.

## Context for the developer

- Where it lives: `src/AppState.swift`, `src/ContentView.swift`
- Interfaces it may touch: `AppInfo.displayName` (TASK-001), the advertiser's
  published state (TASK-004). Read them; do not change them.
- Files in scope (3): the two sources above plus `test/ReceiverStatusTests.swift`
- SwiftUI only, iOS 15.0 APIs only (`docs/STACK.md`). No `.task`/`Task` modifiers
  that need iOS 15.5+, no `@Observable`.
- Explicitly **do not** touch: `project.yml`, `src/AirPlay/`, `src/Net/`,
  `src/AirPlayReceiverApp.swift` (TASK-006 changes it), `docs/`, `qa/`,
  `journal/`, `scripts/`, `.opencode/`.

## Acceptance criteria

1. [ ] Given status `.idle`, when the screen renders, then the status text is
       exactly `Idle`.
2. [ ] Given status `.advertising`, then the status text is exactly
       `Advertising as AirPlay Receiver` (name from `AppInfo.displayName`).
3. [ ] Given status `.failed("port 7000 in use")`, then the status text is
       exactly `Error: port 7000 in use` — the message is shown verbatim.
4. [ ] Given status `.stopped`, then the status text is exactly `Stopped` and
       the screen has no error text.
5. [ ] `ReceiverStatusTests` passes: `Executed 4 tests, with 0 failures`.

## Verification commands

```sh
# on this host
ls airplay-2-receiver/src/AppState.swift airplay-2-receiver/src/ContentView.swift
grep -n 'Advertising as' airplay-2-receiver/src/AppState.swift

# on the Mac (expected BLOCKED until QQ-005 resolves)
rsync -a <project> <build-host>:<build-dir>/ airplay-2-receiver
xcodegen generate
xcodebuild test airplay-2-receiver AirPlayReceiver 'platform=iOS Simulator,name=iPhone 16' | tee /tmp/opencode/task-005-test.log
grep -E "Test Suite 'ReceiverStatusTests' (passed|failed)" /tmp/opencode/task-005-test.log

# visual observation, once the Mac and simulator exist
xcodebuild build airplay-2-receiver AirPlayReceiver iphonesimulator
```

**Expected today:** criteria 1-3 and 5 need the Mac (`BLOCKED`, `QQ-005`);
criterion 4's visual part needs the simulator and is `BLOCKED` too. The `ls` and
`grep` checks show the work exists but are not a `PASS`.

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-005-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes
- [ ] One commit `airplay-2-receiver/TASK-005: show the receiver state on the main screen` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- The mapping lives in one place (`ReceiverStatus.statusText(name:)`) so the test
  never needs a UI test. The view reads it; it must not build strings inline.
- No buttons in this task. Start and stop wiring is TASK-006; a button here would
  be untestable code for a behaviour that does not exist yet.
- Exact strings are the contract. Do not add punctuation or capitalisation that
  the criteria do not state; the tester compares literally.
