# BOARD — AirPlay 2 Receiver

Owner: `pm`. The single place to see what is happening in this project. The BA
reads it every cycle.

**Updated:** 2026-11-15 · **Phase:** build · **Active feature:** FEAT-001
(approved, G2/G3) · **Active task:** TASK-002 next

## Features

| ID | Title | Slice (demoable outcome) | Status | Tasks |
| --- | --- | --- | --- | --- |
| FEAT-001 | Discoverable AirPlay 2 receiver | Launch the app: the Apple TV offers the phone as a speaker under the app's name, and port 7000 answers | approved | 9 |

Increments 2-4 of `DEC-002` (pairable, audible, useful) have no feature files yet.
They are specified only after increment 1 is demonstrated.

## Tasks

| ID | Feature | Title | Status | Attempts | Verdict |
| --- | --- | --- | --- | --- | --- |
| TASK-001 | FEAT-001 | Scaffold the XcodeGen app with one unit test | done | 1 | PASS 2026-11-16 |
| TASK-002 | FEAT-001 | Build the AirPlay TXT record from a stable device id | proposed | 0 | — |
| TASK-003 | FEAT-001 | Answer TCP connections on port 7000 | proposed | 0 | — |
| TASK-004 | FEAT-001 | Publish the `_airplay._tcp` service | proposed | 0 | — |
| TASK-005 | FEAT-001 | Show the receiver state on the main screen | proposed | 0 | — |
| TASK-006 | FEAT-001 | Keep the advertisement in step with the foreground state | proposed | 0 | — |
| TASK-007 | FEAT-001 | Record advertisement events in a diagnostic log | proposed | 0 | — |
| TASK-008 | FEAT-001 | Export the diagnostic log to a file | proposed | 0 | — |
| TASK-009 | FEAT-001 | Install a signed build on the device | blocked | 0 | — |

Dependency order for the build loop: 001 → 002 → 003 → 004 → 005 → 006 → 007 →
008 → 009. Tasks 002 and 003 both depend only on 001. TASK-009 is last because it
needs the whole tree and the exported log for the S5 observation.

## Blockers

- `QQ-005` resolved 2026-11-16: the bridge builds and tests on the Mac
  (Xcode 26.6, iOS 26.5 SDK). QQ-008 (signing team) still blocks TASK-009.
- The iPhone 6s is not connected to the Mac, so S1b/S1c/S5 stay unverifiable.
- `QQ-008` — no signing team named, so no team id may be written anywhere. TASK-009
  (signed `iphoneos` build, install, launch on the 6s) is `blocked` until the
  human answers which Apple ID / development team signs and whether it is the free
  7-day or paid 1-year account. Without it S1b, S1c and S5 cannot be observed.
  Default if unanswered: free account, 7-day profile, re-sign routine.
- `QQ-006` resolved by `DEC-003`: increment 1 uses the default name, the rename
  UI is increment-2 work.
- `QQ-007` resolved by `DEC-004`: verify graceful withdrawal; post-kill expiry is
  Bonjour's cache and is measured, not asserted.
- `rsync -a <project> <build-host>:<build-dir>/` does not run `xcodegen`; regenerate on the Mac
  after any `project.yml` change (see FEAT-001 Notes).

## Legend

`proposed → approved → in-progress → in-review → done`, plus `rework`,
`blocked`, `dropped`. A task is `done` only after a `PASS` from `qa` and BA gate
G4. `Attempts` counts developer launches; three means escalate.

## Counts

- features: 0 done / 1 total
- tasks: 1 done / 9 total
- blocked: 1 (TASK-009, `QQ-008`); QQ-005 will block verification of the rest, not
  authoring

## Recent changes

- 2026-11-15 — post-G3 gaps closed: TASK-007 gained the `Restart` launch marker
  that S5's log half needs (criterion 4, `EventLogTests` 4 → 5); TASK-009 added
  for the signed device build/install/launch that S1b, S1c and S5 require, and
  marked `blocked` on `QQ-008`.
