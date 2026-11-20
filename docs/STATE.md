# WORKSPACE STATE — resume point

> Workspace-level only. Each project has its own `docs/STATE.md`. Under 40 lines.

**Updated:** 2026-11-20 · **Active project:** `play-two`
**Mode:** build — task loop, TASK-008 in-review (BLOCKED on criterion 4, human tap)
**Shared toolchain:** git under `.tooling/`

## Status

One project, in build. G1/G2/G3 passed; FEAT-001 (discoverable) has ten tasks.
Done: TASK-001, TASK-010, TASK-002, TASK-003, TASK-004, TASK-005, TASK-006,
TASK-007 (device-proven: one `PlayTwo` resolves to
`<device>.local.:7000`). TASK-008 at G4 review: BLOCKED on criterion 4
(human tap at the simulator); criteria 1, 2, 3, 5 verified, suite 33/33.
TASK-009 approved, last. Mac reachable again (QQ-009 closed); agents now run on
`opencode/deepseek-v4.1-flash-free#high` (all four agent files + `opencode.jsonc`).

## Next action

1. TASK-008: human taps `Export Log` in the `iPhone 16e` simulator and reports
   whether the share sheet opens with `airplay-receiver-log.txt` (O6). On a clean
   report, BA records G4 PASS and commits `play-two/TASK-008: export the
   diagnostic log to a file`. Also needs the PM amendment for the file list and
   the build destination string (PM subagent blocked on quota).
2. TASK-009 last: document the device install path in `play-two/README.md`.
3. Publication: `lorandignat/smallapps` holds the scrubbed history (12 commits),
   remote `main` = `6eb6155`. No pending push.

## Open questions and blockers

Workspace `docs/QUESTIONS.md` and `play-two/docs/QUESTIONS.md`: QQ-003 (personal
use) still carries its default. No blockers; the Mac is reachable and the 6s is
attached. `xcrun xctrace list devices` never lists it — iOS 15 is below
devicectl's floor — so the device is found through `ios-deploy -c`.
## Recent

- 2026-11-15 — scaffolded the team; restructured into a multi-project workspace;
  spike closed, iOS AP2 attempt accepted, Mac bridge built.
- 2026-11-16 — renamed to PlayTwo; device build/install/launch proven.
- 2026-11-17 — `DEC-009`: the public tree is a sanitised one-commit snapshot,
  pushed from this host with a repository-scoped key.
- 2026-11-18 — TASK-003 PASS (6/6): the listener takes a port, defaults to 7000.
- 2026-11-19 — `DEC-013`: the public repository is the scrubbed history, not one
  commit; `make-history.sh` replays every commit through the same rules.
