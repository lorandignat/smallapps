# WORKSPACE STATE — resume point

> Workspace-level only. Each project has its own `docs/STATE.md`. Under 40 lines.

**Updated:** 2026-11-22 · **Active project:** `play-two`
**Mode:** build — FEAT-005 G2/G3 approved; running increment 3 task loop
**Shared toolchain:** git under `.tooling/`

## Status

One project, in build. Increment 1 shipped/accepted. Increment 2: FEAT-002 done;
FEAT-003 closed at code/task level (21 tasks total, bundle 81/0) — **S2a/S2b
pending human observation** on iPhone 6s. FEAT-005 (RTSP/FairPlay) G2/G3
approved; TASK-022 in-progress (attempt 1). FEAT-006 feature-level only;
FEAT-004 proposed.

## Next action

Run TASK-022 dev→QA→G4 (FEAT-005). After 024, handle TASK-025 (BA DEC, QQ-010,
gates 027/028) and TASK-026. All Mac tests: `platform=iOS Simulator,name=iPhone
14,OS=16.2`. After each PASS: commit, then rebuild/push scrubbed
`public-history` (DEC-014).

## Open questions and blockers

DEC-017 (SRP perf/watchdog) proposed. QQ-003 (personal use) default.
QQ-010/TASK-025 (FairPlay key-table supply/injection boundary) and QQ-011 (ALAC
decode route) need DEC + human approval where noted. S2a/S2b pending human
Home-app observation. iPhone 6s provisioning profile expires 2026-11-23.
Public history must stay scrubbed (DEC-014).

## Recent

- 2026-11-22 — FEAT-003 closed (code/task PASS, S2a/S2b pending); DEC-018
  retired R4; PM broke down increment 3 (FEAT-005/006, TASK-022..028 proposed).
- 2026-11-20 — DEC-015: GUI-session helper runs via `sh`.
- 2026-11-19 — DEC-013/014: scrubbed history publish path.