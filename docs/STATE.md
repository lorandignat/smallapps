# WORKSPACE STATE — resume point

> Workspace-level only. Each project has its own `docs/STATE.md`. Under 40 lines.

**Updated:** 2026-11-22 · **Active project:** `play-two`
**Mode:** breakdown — increment 3 decomposed; awaiting G2/G3 human approval before build
**Shared toolchain:** git under `.tooling/`

## Status

One project, in build. Increment 1 shipped/accepted. Increment 2: FEAT-002 done;
FEAT-003 closed at code/task level (21 tasks total, bundle 81/0) — **S2a/S2b
pending human observation** on iPhone 6s. PM has decomposed increment 3 into
FEAT-005 (RTSP/FairPlay, 7 proposed tasks TASK-022..028) and FEAT-006 (ALAC
playback, feature-level only); FEAT-004 stays proposed. No task is in-progress.

## Next action

Human/BA approve G2 (FEAT-005) and G3 (TASK-022..028). Record the FairPlay
key-table injection DEC (TASK-025, BA-owned) before TASK-027/028 can start;
ALAC decode route needs a DEC before FEAT-006 G3. After G3, resume build loop
one task at a time (022→023→024→(025,026)→027→028). All Mac tests:
`platform=iOS Simulator,name=iPhone 14,OS=16.2`. After each PASS: commit, then
rebuild/push scrubbed `public-history` (DEC-014).

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