---
id: FEAT-004
title: Configurable advertised name
status: proposed
slice: The owner sets the advertised name in the app, and the Apple TV and Home app show that name instead of the default.
spec_ref: product/SPEC.md#4-scope-v1
depends_on: [FEAT-001]
---

# FEAT-004 — Configurable advertised name

**Demo:** 1. Open the app, change the advertised name from `PlayTwo` to a chosen
name, save. 2. On the Apple TV's AirPlay speaker list, the phone appears under
the new name within 30 seconds. 3. Relaunch the app: the chosen name is still in
use and still shown.

This is the settings screen listed under "Also in v1" in `SPEC` §4. It was
deliberately left out of `FEAT-001` (`DEC-003`): increment 1 advertises a
default name, and the rename UI belongs to increment 2, where pairing and the
Home app make a stable, human-chosen name matter. It is not a dependency of
pairing (`FEAT-003`); it is ordered after the pairing risk is retired.

## User value

Otherwise every phone in the house is "iPhone" (or "PlayTwo") in the Apple TV
list and in the Home app, and the owner cannot tell two receivers apart. This
slice lets the owner name the receiver once and have that name stick.

## In scope

- [ ] A settings screen reachable from the main screen, with a text field for
      the advertised name and a save action.
- [ ] Persist the chosen name (survives relaunch).
- [ ] The advertiser uses the persisted name instead of `AppInfo.displayName`
      when one is set.
- [ ] Validation: reject an empty name and a name over 63 UTF-8 bytes (the
      Bonjour limit, `ServiceAdvertiser.maximumNameBytes`), showing the error.
- [ ] The state screen shows the active name.

## Out of scope

- Renaming an already-paired accessory in the Home app — that is the Home
  app's job, not this app's.
- Multiple profiles or per-sender names.
- Editing the HAP accessory name independently of the advertised name —
  `FEAT-003` owns the HAP `/info` name; this feature keeps them in sync by
  using one stored value for both.

## Acceptance criteria (feature level)

- [ ] **Rename (human).** Given the app is foregrounded on the iPhone 6s, when
      the owner changes the name and saves, then the Apple TV list shows the
      new name within 30 seconds.
- [ ] **Persist (automated).** Given a saved name, when the app is relaunched,
      then the advertiser uses the saved name and the state screen shows it.
- [ ] **Validation (automated).** Given an empty name or one over 63 UTF-8
      bytes, when save is tapped, then the name is not changed and an error
      message names the limit.
- [ ] Every task in this feature is `done` with a `qa` verdict of `PASS`.

## Tasks

Not broken down yet. Broken down only when this feature's turn arrives
(`DEC-002`).

## Notes

**Placement decision.** Increment 1 is shipped and accepted, so the settings
screen cannot be added to `FEAT-001`; it belongs to increment 2. PM records
this choice here and in `journal/<role>.md`. No new `DEC-###` is needed because
`DEC-003` already assigns the rename UI to increment 2; this feature file
makes that assignment concrete.

**Single stored value.** One persisted string drives both the Bonjour service
instance name (increment 1) and the HAP `/info` name (`FEAT-003`). If the
owner renames after pairing, the Home app may still show the old name until
re-paired; that is expected and is not a defect of this feature.