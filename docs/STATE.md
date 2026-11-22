# WORKSPACE STATE — resume point

> Workspace-level only. Each project has its own `docs/STATE.md`. Under 40 lines.

**Updated:** 2026-11-22 · **Active project:** `play-two`
**Mode:** build — Mac bridge up (Xcode 14.2, iOS 16.2 simulator); public history pushed after each PASS
**Shared toolchain:** git under `.tooling/`

## Status

One project, in build. Increment 1 (discoverable) shipped and accepted. Increment
2 (pairable): FEAT-002 and all six FEAT-003 tasks are `done` — twenty-one tasks
total, last `play-two/TASK-021` (`a453eb9`), suite 81/0, R2 high-water 81.
FEAT-003 feature close is next; FEAT-004 (configurable name) is proposed but
unscoped. Increment 3 (audible) and 4 (useful) have no features yet.

## Next action

FEAT-003 feature close (QA feature verdict; reword stale R4; record S2a/S2b as
human observations), then PM breaks down FEAT-004 or scopes increment 3. All Mac
tests use `platform=iOS Simulator,name=iPhone 14,OS=16.2`. After every PASS:
commit, then rebuild and push the scrubbed `public-history` ref (DEC-014).

## Open questions and blockers

DEC-017 (SRP derivation perf / FrontBoard watchdog) is proposed, needs human
approval. QQ-003 (personal use) still carries its default. No active blockers;
the iPhone 6s provisioning profile expires 2026-11-23 — rebuild/reinstall if
launch fails after that date. Public history must stay scrubbed (DEC-014).

## Recent

- 2026-11-22 — FEAT-003 tasks all done: TASK-016..021 PASS, commits `f1e9cc5`,
  `119d964`, `cb1429e`, `4760239`, `ab7268c`, `a453eb9`; suite 81/0.
- 2026-11-20 — DEC-015: GUI-session helper runs via `sh`, no `chmod +x`.
- 2026-11-19 — DEC-013: the public repo is scrubbed history, not one snapshot;
  `make-history.sh` replays every commit (DEC-014 push rule).
- 2026-11-16 — renamed to PlayTwo; device build/install/launch proven.
- 2026-11-15 — scaffolded the team; spike closed, Mac bridge built.
