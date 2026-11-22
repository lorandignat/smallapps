# WORKSPACE STATE — resume point

> Workspace-level only. Each project has its own `docs/STATE.md`. Under 40 lines.

**Updated:** 2026-11-22 · **Active project:** `play-two`
**Mode:** build — FEAT-005 G2/G3 approved; running increment 3 task loop
**Shared toolchain:** git under `.tooling/`

## Status

One project, in build. FEAT-003 closed at code/task level (S2a/S2b pending human
observation). FEAT-005 G2/G3 approved; TASK-022..024 PASS (bundle 89/0). TASK-025
BA decision done: DEC-015 proposed (FairPlay key-table boundary, QQ-010) — human
approval required before TASK-027/028. TASK-026 next. FEAT-006 feature-level only;
FEAT-004 proposed.

## Next action

Run TASK-026 dev→QA→G4 (FEAT-005). TASK-027/028 gated until human approves
DEC-015 (QQ-010, no real DRM). All Mac tests: `platform=iOS Simulator,name=iPhone
14,OS=16.2`. After each PASS: commit, then rebuild/push scrubbed
`public-history` (DEC-014).

## Open questions and blockers

DEC-017 (SRP perf/watchdog) proposed. play-two DEC-015 (FairPlay key-table
boundary, QQ-010) proposed — human approval required before TASK-027/028; no
real DRM. QQ-011 (ALAC decode route) needs DEC before FEAT-006 G3. S2a/S2b
pending human Home-app observation. iPhone 6s provisioning profile expires
2026-11-23. Public history must stay scrubbed (DEC-014).

## Recent

- 2026-11-22 — TASK-022..024 PASS (FEAT-005). TASK-025 BA done: play-two DEC-015
  proposed for FairPlay key-table boundary (QQ-010), human approval gates 027/028.
- 2026-11-22 — FEAT-003 closed (code/task PASS, S2a/S2b pending); DEC-018
  retired R4; increment 3 broken down (FEAT-005/006).
- 2026-11-19 — DEC-013/014: scrubbed history publish path.