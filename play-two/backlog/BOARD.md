# BOARD — PlayTwo

Owner: `pm`. The single place to see what is happening in this project. The BA
reads it every cycle.

**Updated:** 2026-11-18 · **Phase:** build · **Active feature:** FEAT-001
(approved, G2/G3) · **Active task:** TASK-004 (approved)

## Features

| ID | Title | Slice (demoable outcome) | Status | Tasks |
| --- | --- | --- | --- | --- |
| FEAT-001 | Discoverable AirPlay 2 receiver | Launch the app: the Apple TV offers the phone as a speaker under the app's name, and port 7000 answers | approved | 10 |

Increments 2-4 of `DEC-002` (pairable, audible, useful) have no feature files yet.
They are specified only after increment 1 is demonstrated.

## Tasks

| ID | Feature | Title | Status | Attempts | Verdict |
| --- | --- | --- | --- | --- | --- |
| TASK-001 | FEAT-001 | Scaffold the XcodeGen app with one unit test | done | 1 | PASS 2026-11-16 |
| TASK-010 | FEAT-001 | Rename the Xcode project to PlayTwo | done | 1 | PASS 2026-11-16 |
| TASK-002 | FEAT-001 | Build the AirPlay TXT record from a stable device id | done | 2 | PASS 2026-11-16 |
| TASK-003 | FEAT-001 | Answer TCP connections on port 7000 | done | 3 | PASS 2026-11-18 (6/6, 2 MINOR); attempts 1-2 BLOCKED |
| TASK-004 | FEAT-001 | Publish the `_airplay._tcp` service | approved | 0 | — |
| TASK-005 | FEAT-001 | Show the receiver state on the main screen | proposed | 0 | — |
| TASK-006 | FEAT-001 | Keep the advertisement in step with the foreground state | proposed | 0 | — |
| TASK-007 | FEAT-001 | Record advertisement events in a diagnostic log | proposed | 0 | — |
| TASK-008 | FEAT-001 | Export the diagnostic log to a file | proposed | 0 | — |
| TASK-009 | FEAT-001 | Install a signed build on the device | approved | 0 | — |

Dependency order for the build loop: 001 → 010 → 002 → 003 → 004 → 005 → 006 →
007 → 008 → 009. Tasks 002, 003 and 010 all depended only on 001; TASK-010 ran
first among them because every later command names the `PlayTwo` scheme, then
TASK-002 (`done`, `PASS` 2026-11-16), and TASK-003 is `done` (`PASS` 2026-11-18).
TASK-004 is next and is the first task with a visible outcome. TASK-009 is
last because it needs the whole tree and the
exported log for the S5 observation.

## Blockers

- **TASK-003 is re-cut, not blocked.** `DEC-011` makes the listener port
  injectable (default 7000), so the unit tests bind a free port on the simulator
  and the real 7000 becomes an app-level observation once TASK-004 gives the
  listener a caller. Two `BLOCKED` runs changed no source.

- `QQ-005` resolved 2026-11-16: the bridge builds and tests on the Mac
  (Xcode 26.6, iOS 26.5 SDK).
- `QQ-008` resolved by `DEC-008` (2026-11-16): the free Apple ID
  `<apple-id>` (team in local configuration as `MAC_TEAM_ID`, never
  committed) signs device builds; profile expires 2026-11-23. TASK-009 is no
  longer blocked.
- The iPhone 6s **is** connected: "<device>", iOS 15.8.8, UDID
  `<udid>`. Build, install and launch were
  proven by hand on 2026-11-16; S1b/S1c/S5 stay the human's observations at
  feature close, not a blocker.
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
- tasks: 4 done (TASK-001, TASK-002, TASK-003, TASK-010; `PASS` 2026-11-16 and
  2026-11-18) / 10 total
- approved and next: TASK-004; TASK-009 is approved but ordered last
- blocked: 0 — `QQ-005` and `QQ-008` are resolved and the 6s is connected

## Recent changes

- 2026-11-18 — TASK-003 `done` on attempt 3 (`PASS` 6/6, 2 MINOR), so FEAT-001
  S1d stays open: nothing constructed the listener yet. TASK-004 is `approved`
  and its scope now includes `src/PlayTwoApp.swift`, which starts the advertiser
  once at launch — without a caller, criterion 4 (the `dns-sd` browse) could not
  be reached, the same trap that blocked TASK-003 twice. Its journal exclusion is
  narrowed to journals other than `journal/<role>.md` (`PROCESS.md` §5 step 10).

- 2026-11-16 — TASK-002 `done` on attempt 2 (`PASS`, 5/5). The rework narrowed
  device-id validation to ASCII `0-9A-F`; the suite is 7 tests in
  `AirPlayTXTRecordTests` and 8 overall. Known minor, unscheduled: the
  fullwidth-letters case at `AirPlayTXTRecordTests.swift:114` is rejected by the
  shape check rather than by the character guard, so it does not pin the guard
  on its own.

- 2026-11-16 — `DEC-008` applied: `QQ-008` answered, so TASK-009 is rewritten as
  one `small` approved task with no `Signing.xcconfig` design. It documents the
  proven device path in `play-two/README.md` only (the four commands, the UDID,
  `ios-deploy` because `devicectl` needs iOS 17, the 2026-11-23 profile expiry);
  the team lives in local configuration as `MAC_TEAM_ID` and is never committed.
  The 6s is connected (iOS 15.8.8). TASK-010 is `done` (`PASS`), so TASK-002 is
  next.
- 2026-11-16 — `DEC-005` and `DEC-007` applied to the backlog; `DEC-006` (Relay)
  is superseded. TASK-010 renamed to `TASK-010-rename-to-playtwo.md` and rewritten
  as one coherent task for the code/manifest half (`depends_on: [TASK-001]`,
  `approved`, `small`): target/scheme `PlayTwo`, tests `PlayTwoTests`, bundle ids
  `com.lorand.playtwo` / `com.lorand.playtwo.tests`, no `CFBundleDisplayName`.
  TASK-002..009 swept: project argument `play-two`, scheme `PlayTwo`, simulator
  `iPhone 16e`, Mac path
  `<build-dir>` — no `Relay` and no
  hyphenated `com.lorand.play-two` remained. TASK-001 is `done` (`PASS`,
  2026-11-16).
- 2026-11-15 — post-G3 gaps closed: TASK-007 gained the `Restart` launch marker
  that S5's log half needs (criterion 4, `EventLogTests` 4 → 5); TASK-009 added
  for the signed device build/install/launch that S1b, S1c and S5 require, and
  marked `blocked` on `QQ-008`.
