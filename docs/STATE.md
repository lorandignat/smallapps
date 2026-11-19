# WORKSPACE STATE — resume point

> Workspace-level only. Each project has its own `docs/STATE.md`; this file says
> which one is active and what the workspace itself needs. Keep it under 40 lines.

**Updated:** 2026-11-15
**Active project:** `play-two`
**Mode:** build — paused on the Mac
**Shared toolchain:** git under `.tooling/`

## Status

One project, in build. G1/G2/G3 passed; FEAT-001 (discoverable) has nine tasks.
TASK-001 (scaffold) is implemented and QA returns BLOCKED because no Mac is
configured. Everything else is paused behind it deliberately.

## Next action

1. Human fills local configuration (host, user), installs the key on the Mac from
   `ssh-copy-id <build-host>`, installs XcodeGen, then `check` must print
   `xcodebuild -version`.
2. Re-verify TASK-001, then TASK-002 through TASK-009 in order.

## Open questions

Workspace `docs/QUESTIONS.md` QQ-002 (Mac reachability). Project questions in
`play-two/docs/QUESTIONS.md` (QQ-003, QQ-005).

## Blockers

QQ-002 — the Mac is unreachable; no iOS build, test or install is possible
anywhere. Everything else is unblocked.

## Recent

- 2026-11-15 — scaffolded the agent team (v1, single project).
- 2026-11-15 — restructured into a multi-project workspace (v2).
- 2026-11-15 — spike closed; iOS AP2 attempt accepted; Mac bridge built.
- 2026-11-15 — G1-G3 passed; TASK-001 implemented, BLOCKED on the Mac.
