# WORKSPACE STATE — resume point

> Workspace-level only. Each project has its own `docs/STATE.md`. Under 40 lines.

**Updated:** 2026-11-20 · **Active project:** `play-two`
**Mode:** maintenance — increment 1 shipped; PM breaking down increment 2 (pairable)
**Shared toolchain:** git under `.tooling/`

## Status

One project, in maintenance. Increment 1 (discoverable) shipped 2026-11-20
(all ten tasks done, O1-O6 observed, release note written, human accepted).
PM breaking down increment 2 (pairable): HAP pairing so the phone can be added
in the Home app on iOS 15.3 (S2). Increments 3 (audible) and 4 (useful) stay
unspecified until increment 2 is demonstrated. Agents on `opencode/beam-free`.

## Next action

1. Feature close: human performs O1-O6 observations on the 6s / simulator
   (screen read, discovery browse, `nc :7000`, AirPlay picker on a second
   iPhone, restart log line, Export Log share sheet) and reports them.
2. BA records the release note in play-two/docs/STATE.md and checks the
   definition of done; PM breaks down increment 2 (pairable) only after the
   human accepts increment 1. No new features start before acceptance.
3. Publication: `lorandignat/smallapps` holds the scrubbed history (12 commits),
   remote `main` = `6eb6155`. No pending push; the human pushes when ready.

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
- 2026-11-20 — `DEC-015`: GUI-session helper runs via `sh`; no `chmod +x` on the
  Mac anymore (detail: the GUI-session runner, `the build bridge:123`).
