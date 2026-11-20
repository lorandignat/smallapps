# STATE — PlayTwo

> Resume point; history belongs in the role journals. Keep under 40 lines.

**Updated:** 2026-11-20 · **Phase:** build · **Active feature:** FEAT-001
**Active task:** none — FEAT-001 complete (TASK-001..TASK-010 all done)
**v1:** increment 4 of DEC-002 (discoverable → pairable → audible → useful)

## Status

G1 passed. FEAT-001 has ten tasks; TASK-001 (scaffold), TASK-002 (TXT record),
TASK-003 (TCP listener), TASK-004 (publish service), TASK-005 (receiver state)
and TASK-010 (rename to PlayTwo) are **done**. The app
builds as `PlayTwo`, bundle id `com.lorand.playtwo`, iOS 15.0 deployment target.
A signed device build installs and launches on the iPhone 6s (iOS 15.8.8) via
`build … iphoneos` + `install` + `ios-deploy --justlaunch` (`DEC-008`); Xcode 27
needs an iOS 15.7 developer disk image for that last step, which is installed. The free-Apple-ID profile expires
2026-11-23, after which the app must be rebuilt.

## Next action

1. FEAT-001 complete: TASK-001..TASK-010 all done. TASK-009 committed
   `play-two/TASK-009: document the device install path`.
2. Feature close: human O1-O5 observations on the 6s (screen read, discovery
   browse, nc :7000, AirPlay picker on a second iPhone, restart log line) plus
   O6 (Export Log share sheet in the simulator). Then release note + human
   acceptance per PROCESS §5 phase 3.
3. Increments 2-4 of DEC-002 (pairable, audible, useful) get feature files
   only after increment 1 is demonstrated.

## Approved gates

G1 (SPEC v1.0 + stack, 2026-11-15) · G2 (FEAT-001, 2026-11-15) · G3 (TASK-001 to
TASK-010, 2026-11-16) · G4 for TASK-001, TASK-010, TASK-002, TASK-003 (6/6,
2026-11-18). Two MINOR TASK-003 findings: the reply assertion derives its
expectation from the constant under test; the simulator host fails to launch the
app about twice in twelve runs. Details in `qa/reports/TASK-003-review.md`.

## Open questions and blockers

`docs/QUESTIONS.md`: QQ-003 (personal use, default assumed) is the only open one;
QQ-009 closed 2026-11-20 (Mac back). One human-observation pending: TASK-008
criterion 4 (tap Export Log in the simulator, report O6). No other blockers.
Device observations S1b, S1c and S5 stay unverified until the app runs on the
phone with the advertisement in place.
