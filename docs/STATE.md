# WORKSPACE STATE — resume point

> Workspace-level only. Each project has its own `docs/STATE.md`; this file says
> which one is active and what the workspace itself needs. Keep it under 40 lines.

**Updated:** 2026-11-15
**Active project:** `airplay-2-receiver`
**Mode:** intake — spec next
**Shared toolchain:** git under `.tooling/`

## Status

One project, past its spike: DEC-001 chooses a sideloaded iOS AirPlay 2 receiver
and DEC-002 splits it into four kill-switch increments. The build problem is
solved in principle — the build bridge drives the human's Mac over SSH
(DEC-007) — but it is untested until local configuration exists and
`xcodebuild -version` succeeds.

## Next action

1. Human fills local configuration (host, user), installs the key on the Mac from
   `ssh-copy-id <build-host>`, then `check` must print `xcodebuild -version`.
2. Write `airplay-2-receiver/product/SPEC.md` for increment 1 and settle the
   project stack; ask for G1.

## Open questions

Workspace `docs/QUESTIONS.md` QQ-002 (Mac reachability). Project questions in
`airplay-2-receiver/docs/QUESTIONS.md` (QQ-003, QQ-005).

## Blockers

None for planning. Device verification waits on QQ-002.

## Recent

- 2026-11-15 — scaffolded the agent team (v1, single project).
- 2026-11-15 — restructured into a multi-project workspace (v2).
- 2026-11-15 — spike closed; iOS AP2 attempt accepted; Mac bridge built.
