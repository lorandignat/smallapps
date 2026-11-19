# WORKSPACE STATE — resume point

> Workspace-level only. Each project has its own `docs/STATE.md`. Under 40 lines.

**Updated:** 2026-11-18 · **Active project:** `play-two`
**Mode:** build — task loop, TASK-004 next
**Shared toolchain:** git under `.tooling/`

## Status

One project, in build. G1/G2/G3 passed; FEAT-001 (discoverable) has ten tasks,
TASK-001, TASK-002, TASK-003 and TASK-010 done. The Mac bridge signs, installs and
launches on the iPhone 6s (iOS 15.8.8) end to end: device builds run inside the
Mac's Aqua session so `codesign` reaches the login keychain, and `ios-deploy`
replaces `devicectl`, which does not support iOS 15. Signing is the human's free
Apple ID (`DEC-008`), so profiles expire after seven days.

## Next action

1. TASK-004 (publish `_airplay._tcp`) — the first visible milestone; then 005-008
   in dependency order, one task per cycle, TASK-009 last.
2. Publication is prepared but not pushed: `lorandignat/smallapps` exists empty,
   the key is on the account, and `public-snapshot` is one sanitised commit. The
   human adds `origin` and pushes; agents never push.

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
