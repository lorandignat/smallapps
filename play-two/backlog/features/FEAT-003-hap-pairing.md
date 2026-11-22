---
id: FEAT-003
title: HAP pairing endpoints and persistence
status: done
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

**Close (2026-11-22).** `status: done` records the code/task close only: all six
tasks are `done` with QA `PASS` and the feature-close review is `PASS`
(`qa/reports/FEAT-003-feature-review.md`). **S2a and S2b remain pending human
observations on the iPhone 6s** and are not claimed as demonstrated here. The
demo above is complete only once the human reports the exact `S2a:` / `S2b:`
strings from `qa/TEST-PLAN.md`; until then this feature is closed at the
code/task level and is not fully demonstrated.

## User value

The owner wants the phone to show up as a real HomeKit speaker, not just an
AirPlay entry. This slice makes "Add Accessory" succeed and keeps the pairing
across the 7-day re-signing cycle (`SPEC` §7), so the owner does not re-pair
every week.

## In scope

- [x] HTTP request handling on the AirPlay port (7000), replacing the fixed
      reply from increment 1.
- [x] `GET /info` returning HAP accessory info (name, category: speaker,
      pairing state).
- [x] `POST /pair-setup` (SRP M1–M6) using `FEAT-002`'s primitives.
- [x] `POST /pair-verify` establishing an encrypted session.
- [x] Pairing stored in the Keychain; advertised pairing state (status flags)
      in the AirPlay TXT record.
- [x] Restart survival: a paired accessory is still paired after relaunch.
- [x] Setup code displayed on the state screen.

## Out of scope

- The crypto primitives themselves — `FEAT-002`.
- Configurable advertised name — `FEAT-004`.
- RTSP, FairPlay, audio — increment 3.
- Volume/playback control from the Home app — non-goal (`SPEC` §5).

## Acceptance criteria (feature level)

- [ ] **S2a (human) — PENDING, not demonstrated.** Given the app is foregrounded
      on the iPhone 6s, when the human runs Home app "Add Accessory" and enters
      the setup code, then it completes without error and the phone is listed as
      a speaker. Only the human on the iPhone 6s can observe this; no agent
      verified it at feature close (`qa/reports/FEAT-003-feature-review.md`).
- [ ] **S2b (human) — PENDING, not demonstrated.** Given the phone is paired,
      when the app is killed and relaunched, then the Home app still shows it as
      paired (no re-pair prompt) and the app's state screen shows the paired
      state. Only the human on the iPhone 6s can observe this; no agent verified
      it at feature close.
- [x] **Regression.** The increment-1 behaviours that still apply (discovery,
      state screen, log export) keep passing; the fixed 38-byte reply on
      port 7000 is superseded by HTTP handling and `qa/REGRESSION.md` R4 is
      retired/updated accordingly (reworded per `DEC-018`, row retained).
- [x] Every task in this feature is `done` with a `qa` verdict of `PASS`.

## Tasks

(G3 at 2026-11-22; broken down per the `pm-atomic` checklist. `FEAT-002`
shipped first, so the tasks are not held by `DEC-002`. The developer owns
`test/`; `qa/` and journals other than `journal/<role>.md` stay out of scope.)

- [x] **TASK-016** — Serve `GET /info` on port 7000, replacing the fixed reply.
- [x] **TASK-017** — Expose the pairing state in the pairing store
  (`HAPPairingStore`, `GET /info` reads it).
- [x] **TASK-018** — Complete `POST /pair-setup` (SRP M1–M6).
- [x] **TASK-019** — Establish an encrypted session with `POST /pair-verify`.
- [x] **TASK-020** — Advertise the paired status in the AirPlay TXT record
  (`sf`).
- [x] **TASK-021** — Restart survival: show the setup code and the paired
  state on the state screen.

Each is `small` (one behaviour, one commit). Order is the dependency order:
017 needs 016, 018 needs 016+017, 020 needs 017, 021 needs 018+020.

## Notes

**Regression note.** Increment 2 replaces the fixed reply on port 7000 with
HTTP handling: TASK-016 does the replacement. `qa/REGRESSION.md` R4 (fixed
38-byte reply) is therefore obsolete from TASK-016 on; it is retired or
reworded by QA/BA with a `DEC-###` reference — the BA note of 2026-11-21 says
exactly this, so the expectation at feature close is a reworded R4 row, not a
deleted one. The `ReceiverListener.response` constant goes away with the
replacement.

**Status flags.** The AirPlay TXT record gains a `sf` (status flags) field
reflecting paired/unpaired state. `FEAT-002` does not touch the TXT record;
this feature owns that change, in the same task as pairing persistence.