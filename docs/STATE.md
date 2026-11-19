# WORKSPACE STATE — resume point

> Workspace-level only. Each project has its own `docs/STATE.md`; this file says
> which one is active and what the workspace itself needs. Keep it under 40 lines.

**Updated:** 2026-11-16
**Active project:** `play-two`
**Mode:** build — device path proven, task loop next
**Shared toolchain:** git under `.tooling/`

## Status

One project, in build. G1/G2/G3 passed; FEAT-001 (discoverable) has ten tasks,
TASK-001, TASK-002 and TASK-010 done. A signed device build installs and launches on
the reference iPhone 6s (iOS 15.8.8) end to end. Signing is the human's free
Apple ID (`DEC-008` in the project), so profiles expire after seven days.

## Next action

1. TASK-003 (TCP listener on 7000), then 004-008 in dependency order, one task per
   cycle.
2. TASK-009 last: it documents the device path in the project README.

## Open questions

Workspace `docs/QUESTIONS.md` and `play-two/docs/QUESTIONS.md`. QQ-008 (signing)
is answered; QQ-003 (personal use) still carries its default.

## Blockers

None. The Mac is reachable, Xcode 26.6 builds, and the 6s is paired.

## Recent

- 2026-11-15 — scaffolded the agent team (v1, single project).
- 2026-11-15 — restructured into a multi-project workspace (v2).
- 2026-11-15 — spike closed; iOS AP2 attempt accepted; Mac bridge built.
- 2026-11-16 — renamed to PlayTwo; device build/install/launch proven.
