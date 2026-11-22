# WORKSPACE STATE — resume point

> Workspace-level only. Each project has its own `docs/STATE.md`. Under 40 lines.

**Updated:** 2026-11-22 · **Active project:** `play-two`
**Mode:** build — FEAT-005 G2/G3 approved; running increment 3 task loop
**Shared toolchain:** git under `.tooling/`

## Status

One project, in build. FEAT-003 closed at code/task level (S2a/S2b pending human
observation). FEAT-005 G2/G3 approved; TASK-022..024,026 PASS (bundle 93/0).
DEC-015 accepted (QQ-010). **TASK-027 BLOCKED (QQ-012):** attempt 1 produced a
synthetic XOR stand-in, not real FairPlay v3; rejected, not committed. Human
decision needed. FEAT-006 feature-level; FEAT-004 proposed.

**Human decision needed (QQ-012):** TASK-027 attempt 1 was a synthetic XOR
stand-in, not real FairPlay v3; BA rejected it (not committed). Decide: (A)
accept boundary-only stand-in now and defer real interop (false-confidence risk);
(B) authorize a legitimate synthetic known-answer vector/source/approach with no
real DRM key tables; or (C) re-scope/park FEAT-005 FairPlay tasks. No real DRM
may be obtained/committed by agents.

## Open questions and blockers

**QQ-012 (blocking TASK-027/028/FEAT-005):** FairPlay v3 implementation/vector
provenance without real DRM leakage. DEC-017 proposed. QQ-011 (ALAC decode route)
needs DEC before FEAT-006 G3. S2a/S2b pending human Home-app observation. iPhone
6s provisioning profile expires 2026-11-23. Public history scrubbed (DEC-014).

## Recent

- 2026-11-22 — TASK-027 attempt 1 BLOCKED (QQ-012): synthetic XOR stand-in
  rejected as not real FairPlay v3; not committed. Human decision needed.
- 2026-11-22 — Human approved play-two DEC-015 (QQ-010 closed); leak guard added
  (`play-two/local-secrets/` gitignored).
- 2026-11-22 — TASK-026 PASS (FEAT-005, attempt 2, 93/0, R2 93).