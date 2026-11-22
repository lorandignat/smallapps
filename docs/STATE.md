# WORKSPACE STATE — resume point

> Workspace-level only. Each project has its own `docs/STATE.md`. Under 40 lines.

**Updated:** 2026-11-22 · **Active project:** `play-two`
**Mode:** build — FEAT-005 G2/G3 approved; running increment 3 task loop
**Shared toolchain:** git under `.tooling/`

## Status

One project, in build. FEAT-003 closed at code/task level (S2a/S2b pending human
observation). FEAT-005 G2/G3 approved; TASK-022..024,026 PASS (bundle 93/0).
play-two DEC-015 accepted 2026-11-22 (FairPlay key-table boundary, QQ-010);
TASK-027 next, TASK-028 after. No real DRM in repo. FEAT-006 feature-level;
FEAT-004 proposed.

## Next action

Run TASK-027 dev→QA→G4 (FEAT-005), then TASK-028. Keep FairPlay fixtures
synthetic/injected only; never obtain/commit/bundle/upload/log real key material.
Mac tests: `platform=iOS Simulator,name=iPhone 14,OS=16.2`. After each PASS:
commit, then push scrubbed `public-history` (DEC-014).

## Open questions and blockers

DEC-017 (SRP perf/watchdog) proposed. play-two DEC-015 accepted; QQ-010 closed —
TASK-027/028 unblocked but **no real DRM** may enter repo/logs/artifacts. QQ-011
(ALAC decode route) needs DEC before FEAT-006 G3. S2a/S2b pending human Home-app
observation. iPhone 6s provisioning profile expires 2026-11-23. Public history
must stay scrubbed (DEC-014).

## Recent

- 2026-11-22 — Human approved play-two DEC-015 (QQ-010 closed); leak guard added
  (`play-two/local-secrets/` gitignored). TASK-027 next.
- 2026-11-22 — TASK-026 PASS (FEAT-005, attempt 2, 93/0, R2 93).
- 2026-11-22 — TASK-022..025 done; FEAT-005 in progress.