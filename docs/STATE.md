# WORKSPACE STATE — resume point

> Workspace-level only. Each project has its own `docs/STATE.md`. Under 40 lines.

**Updated:** 2026-11-20 · **Active project:** `play-two`
**Mode:** build, paused — Mac disconnected; no builds until the old MacBook is up
**Shared toolchain:** git under `.tooling/`

## Status

One project, in build. Increment 1 (discoverable) shipped and accepted.
Increment 2 (pairable) is mid-build: TASK-011 done (TLV8, `play-two/TASK-011:
TLV8 codec (encode and decode)`), TASK-012 blocked (Mac disconnected).

## Next action

Mac will be set up tomorrow (old MacBook). On resume: TASK-012 (SRP verifier)
→ QA → commit `play-two/TASK-012: derive SRP-3072 verifier from setup code and
salt` → TASK-013 → TASK-014 → TASK-015 → FEAT-003 → FEAT-004 → increment 3
(audible). No builds until the MacBook is up.

## Open questions and blockers

Workspace `docs/QUESTIONS.md` and `play-two/docs/QUESTIONS.md`: QQ-003 (personal
use) still carries its default. Blocker: Mac disconnected (user setting up the
old MacBook); TASK-012 blocked until it is set up (see project state).

## Recent

- 2026-11-20 — DEC-015: GUI-session helper runs via `sh`, no `chmod +x` on the
  Mac; increment 2 mid-build: TASK-011 done (2026-11-20, `6aee109`), TASK-012
  blocked (Mac disconnected).

- 2026-11-15 — scaffolded the team; restructured into a multi-project workspace;
  spike closed, iOS AP2 attempt accepted, Mac bridge built.
- 2026-11-16 — renamed to PlayTwo; device build/install/launch proven.
- 2026-11-17 — `DEC-009`: the public tree is a sanitised one-commit snapshot,
  pushed from this host with a repository-scoped key.
- 2026-11-18 — TASK-003 PASS (6/6): the listener takes a port, defaults to 7000.
- 2026-11-19 — `DEC-013`: the public repository is the scrubbed history, not one
  commit; `make-history.sh` replays every commit through the same rules.
- 2026-11-20 — `DEC-015`: GUI-session helper runs via `sh`; no `chmod +x` on the
  Mac anymore (detail: the GUI-session runner, `the build bridge:123`).
