---
id: FEAT-003
title: HAP pairing endpoints and persistence
status: proposed
slice: The Home app completes "Add Accessory" with the phone and lists it as a speaker, and the pairing survives an app restart.
spec_ref: product/SPEC.md#6-success-criteria
depends_on: [FEAT-002]
---

# FEAT-003 — HAP pairing endpoints and persistence

**Demo:** 1. On the iPhone, open the app and read the setup code on the state
screen. 2. In the Home app, tap "Add Accessory", enter the code, and watch it
complete; the phone appears as a speaker. 3. Kill the app and reopen it; the
Home app still shows the phone as paired (no re-pair prompt).

This is the user-facing half of increment 2 (`DEC-002`) and the owner of
success criterion `S2`. It depends on `FEAT-002`: the crypto primitives must
exist before the endpoints that use them.

## User value

The owner wants the phone to show up as a real HomeKit speaker, not just an
AirPlay entry. This slice makes "Add Accessory" succeed and keeps the pairing
across the 7-day re-signing cycle (`SPEC` §7), so the owner does not re-pair
every week.

## In scope

- [ ] HTTP request handling on the AirPlay port (7000), replacing the fixed
      reply from increment 1.
- [ ] `GET /info` returning HAP accessory info (name, category: speaker,
      pairing state).
- [ ] `POST /pair-setup` (SRP M1–M6) using `FEAT-002`'s primitives.
- [ ] `POST /pair-verify` establishing an encrypted session.
- [ ] Pairing stored in the Keychain; advertised pairing state (status flags)
      in the AirPlay TXT record.
- [ ] Restart survival: a paired accessory is still paired after relaunch.
- [ ] Setup code displayed on the state screen.

## Out of scope

- The crypto primitives themselves — `FEAT-002`.
- Configurable advertised name — `FEAT-004`.
- RTSP, FairPlay, audio — increment 3.
- Volume/playback control from the Home app — non-goal (`SPEC` §5).

## Acceptance criteria (feature level)

- [ ] **S2a (human).** Given the app is foregrounded on the iPhone 6s, when
      the human runs Home app "Add Accessory" and enters the setup code, then
      it completes without error and the phone is listed as a speaker.
- [ ] **S2b (human).** Given the phone is paired, when the app is killed and
      relaunched, then the Home app still shows it as paired (no re-pair
      prompt) and the app's state screen shows the paired state.
- [ ] **Regression.** The increment-1 behaviours that still apply (discovery,
      state screen, log export) keep passing; the fixed 38-byte reply on
      port 7000 is superseded by HTTP handling and `qa/REGRESSION.md` R4 is
      retired/updated accordingly.
- [ ] Every task in this feature is `done` with a `qa` verdict of `PASS`.

## Tasks

Not broken down yet. `FEAT-002` must ship first (`DEC-002`).

## Notes

**Regression note.** Increment 2 replaces the fixed reply on port 7000 with
HTTP handling. `qa/REGRESSION.md` R4 (fixed 38-byte reply) no longer applies
as written and should be retired or reworded by QA with a `DEC-###` reference
once HTTP handling lands. PM flags this now so it is not a surprise at feature
close.

**Status flags.** The AirPlay TXT record gains a `sf` (status flags) field
reflecting paired/unpaired state. `FEAT-002` does not touch the TXT record;
this feature owns that change, in the same task as pairing persistence.