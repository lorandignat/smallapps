# BOARD — PlayTwo

Owner: `pm`. The single place to see what is happening in this project. The BA
reads it every cycle.

**Updated:** 2026-11-22 · **Phase:** build · **Active feature:** FEAT-003 (HAP pairing endpoints)
· **Active task:** TASK-018 (FEAT-003, in-progress, attempt 1)

## Features

| ID | Title | Slice (demoable outcome) | Status | Tasks |
| --- | --- | --- | --- | --- |
| FEAT-001 | Discoverable AirPlay 2 receiver | Launch the app: the Apple TV offers the phone as a speaker under the app's name, and port 7000 answers | approved | 10 |
| FEAT-002 (done) | HAP crypto primitives | An SRP-3072 handshake completes between the accessory and a test client and both sides agree on a session key; TLV8 round-trips; an Ed25519 identity key persists across launches | approved | 5 |
| FEAT-003 | HAP pairing endpoints and persistence | The Home app completes "Add Accessory" with the phone and lists it as a speaker, and the pairing survives an app restart | approved | 2 done, 4 proposed |
| FEAT-004 | Configurable advertised name | The owner sets the advertised name in the app, and the Apple TV and Home app show that name instead of the default | proposed | 0 |

FEAT-002/003 are increment 2 (`DEC-002`, pairable); FEAT-004 is the settings
screen listed under "Also in v1" (`SPEC` §4), assigned to increment 2 by
`DEC-003`. FEAT-003 depends on FEAT-002; FEAT-004 depends on FEAT-001. Only
FEAT-002 and FEAT-003 are broken down into tasks; the rest stay at feature
level until their turn. Increments 3 (audible) and 4 (useful) have no feature
files yet.

## Tasks

| ID | Feature | Title | Status | Attempts | Verdict |
| --- | --- | --- | --- | --- | --- |
| TASK-001 | FEAT-001 | Scaffold the XcodeGen app with one unit test | done | 1 | PASS 2026-11-16 |
| TASK-010 | FEAT-001 | Rename the Xcode project to PlayTwo | done | 1 | PASS 2026-11-16 |
| TASK-002 | FEAT-001 | Build the AirPlay TXT record from a stable device id | done | 2 | PASS 2026-11-16 |
| TASK-003 | FEAT-001 | Answer TCP connections on port 7000 | done | 3 | PASS 2026-11-18 (6/6, 2 MINOR); attempts 1-2 BLOCKED |
| TASK-004 | FEAT-001 | Publish the `_airplay._tcp` service | done | 2 | PASS 2026-11-19 — 17/17 simulator, device-proven, R2 high-water 13→17 |
| TASK-005 | FEAT-001 | Show the receiver state on the main screen | done | 1 | PASS 2026-11-19 — 21/21, R9 added |
| TASK-006 | FEAT-001 | Keep the advertisement in step with the foreground state | done | 2 | PASS 2026-11-19 (5/5, attempt 2) |
| TASK-007 | FEAT-001 | Record advertisement events in a diagnostic log | done | 1 | PASS 2026-11-19 (6/6, attempt 1) |
| TASK-008 | FEAT-001 | Export the diagnostic log to a file | done | 2 | PASS 2026-11-20 (4/4, crit. 4 relocated to O6 human observation at FEAT-001 close) |
| TASK-009 | FEAT-001 | Install a signed build on the device | done | 1 | PASS 2026-11-20 (4/5, crit. 5 = O1 human observation) |
| TASK-011 | FEAT-002 | TLV8 codec (encode and decode) | done | 1 | PASS 2026-11-20 — `TLV8Tests` 5/5, suite 38/38 |
| TASK-012 | FEAT-002 | Derive SRP-3072 verifier from setup code and salt | done | 3 | PASS (qa/reports/TASK-012-review.md) |
| TASK-013 | FEAT-002 | SRP-3072 server generates salt and ephemeral B | done | 1 | PASS (qa/reports/TASK-013-review.md) |
| TASK-014 | FEAT-002 | SRP-3072 server verifies client proof and derives session key | done | 1 | PASS (qa/reports/TASK-014-review.md) |
| TASK-015 | FEAT-002 | Ed25519 accessory identity key with Keychain persistence | done | 1 | PASS (qa/reports/TASK-015-review.md) |
| TASK-016 | FEAT-003 | Serve `GET /info` on port 7000, replacing the fixed reply | done | 1 | PASS 2026-11-22 — qa/reports/TASK-016-review.md |
| TASK-017 | FEAT-003 | Expose the pairing state in the pairing store | done | 1 | PASS 2026-11-22 — qa/reports/TASK-017-review.md |
| TASK-018 | FEAT-003 | Complete `POST /pair-setup` (SRP M1–M6) | proposed | 0 | |
| TASK-019 | FEAT-003 | Establish an encrypted session with `POST /pair-verify` | proposed | 0 | |
| TASK-020 | FEAT-003 | Advertise the paired status in the AirPlay TXT record | proposed | 0 | |
| TASK-021 | FEAT-003 | Restart survival — show the setup code and paired state on the state screen | proposed | 0 | |

Dependency order for the build loop: 001 → 010 → 002 → 003 → 004 → 005 → 006 →
007 → 008 → 009. Tasks 002, 003 and 010 all depended only on 001; TASK-010 ran
first among them because every later command names the `PlayTwo` scheme, then
TASK-002 (`done`, `PASS` 2026-11-16), and TASK-003 is `done` (`PASS` 2026-11-18).
TASK-004 is next and is the first task with a visible outcome. TASK-009 is
last because it needs the whole tree and the
exported log for the S5 observation.

Dependency order for FEAT-003: 016 → 017 → 018 → 019 → 020 → 021
(017 needs 016; 018 needs 016+017; 020 needs 017; 021 needs 018+020). All six
are `proposed` until the BA approves them at G3 — already done at 2026-11-22 —
and `attempts` is 0: the build loop runs one task at a time, BA → developer →
qa per task.

## Blockers

- **Scripted launch works again.** Xcode 27 ships no iOS 15 developer disk image,
  so `ios-deploy --justlaunch` refused until a 15.7 image was placed in the
  user's `DeviceSupport` directory; it now launches and reports `success`.
- **TASK-004 criterion 4 is proven on the device.** After adding the local-network
  declarations and tapping Allow, `dns-sd -B _airplay._tcp` shows exactly one
  `PlayTwo`, resolving to `<device>.local.:7000`; `nc <device-ip>
  7000` succeeds; a second iPhone offers PlayTwo in its AirPlay picker. The
  simulator suite for the rework still needs a Mac run; the `policyDenied` unit
  test is in the tree. QA is the next step.
- **Agents run on Tidepool Alpha.** The free pool is exhausted; all launches use
  `opencode/tidepool-alpha-free` (`opencode.jsonc`, `.opencode/agents/ba.md`).
- **The Mac is offline.** ssh to `<build-host>` and `/dev/tcp` probes to it
  and to the Tailscale name `ro-w2kq9641jp.ts.net` time out since ~20:05. TASK-008
  is `blocked` (`QQ-009`); nothing Mac-dependent runs until it is back.

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

- features: 1 done (FEAT-001), 2 approved (FEAT-002, FEAT-003); 4 total; FEAT-004 proposed
- tasks: 17 done (TASK-001..TASK-010, TASK-011..TASK-017) / 21 total; TASK-018..021 proposed, next
- blocked: 0 (profile expires 2026-11-23)

## Recent changes

- 2026-11-22 — PM breakdown of FEAT-003: six tasks added (TASK-016..021,
  `proposed`); FEAT-003 approved (G3 done); feature file updated (Tasks
  section, R4 note names TASK-016). R2 high-water expectations: 62 → 68 → 73 →
  78 → 79 → 81 after TASK-016..021; QA/BA record the actuals.
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

- 2026-11-19 — TASK-006 `done` on attempt 2 (`PASS`, 5/5, 2026-11-19): the
  rework clears `ServiceAdvertiser.listener` on `.cancelled`, so returning to
  the foreground republishes the advertisement. Board, project state and journal
  updated; commit `play-two/TASK-006: keep the advertisement in step with the
  foreground state`.

- 2026-11-20 — PM breakdown of increment 2: added FEAT-002 (HAP crypto primitives,
  5 tasks TASK-011..015), FEAT-003 (HAP pairing endpoints and persistence, feature
  level), FEAT-004 (configurable advertised name, feature level). Settings screen
  placed in increment 2, not increment 1, per DEC-003 (increment 1 is shipped).
  FEAT-002 is the first feature broken down; FEAT-003/004 stay at feature level.
  Phase → breakdown.

- 2026-11-19 — TASK-007 `done` (`PASS`, 6/6, attempt 1, 2026-11-19): `EventLog`
  records one timestamped line per advertisement event (`Advertising as
  PlayTwo`, `Stopped`, `Advertiser failed`); `AppState.init` records `Restart`
  as the first entry of every launch; storage is in-memory, bounded at 2000
  entries (drop-oldest), appended under `NSLock`; `EventLogTests` grows to 5.
  Board, state and journal updated; regression high-water mark raised 25 → 30
  (`qa/REGRESSION.md` R2, per `qa/reports/TASK-007-review.md`); commit
  `play-two/TASK-007: record advertisement events in a diagnostic log` (wip
  commit `55ca41b`).
