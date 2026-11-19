# STATE — AirPlay 2 Receiver

> Project resume point. Updated by the BA after every meaningful step. Keep under
> 40 lines; history belongs in `journal/<role>.md`.

**Updated:** 2026-11-15
**Phase:** build
**Active feature:** FEAT-001
**Active task:** TASK-001
**v1:** increment 4 of DEC-002 (discoverable → pairable → audible → useful)

## Status

G1 passed. FEAT-001 (discoverable) is approved at G2/G3 with eight atomic tasks,
TASK-001 to TASK-008. TASK-001 (scaffold) is in progress. The Mac bridge is
written but untested until local configuration exists and `xcodebuild -version` passes, so build/test criteria are expected to return BLOCKED.

## Next action

1. TASK-001: developer writes the scaffold, QA verifies what this host can show
   and records the build checks as BLOCKED.
2. Human configures the Mac (QQ-005). Then TASK-001 is re-verified and PASSed.
3. Only after TASK-001 passes does TASK-002 start.

## Approved gates

| Gate | Scope | Approved | Notes |
| --- | --- | --- | --- |
| G1 | SPEC v1.0 + stack | 2026-11-15 | Human approved; four-increment ladder accepted |
| G2 | FEAT-001 (discoverable) | 2026-11-15 | Vertical slice, traces to S1/S5; increments 2-4 have no features yet |
| G3 | TASK-001 to TASK-008 | 2026-11-15 | All eight pass the atomicity checklist; only TASK-001 approved to run |

## Open questions

`docs/QUESTIONS.md` — QQ-003 (personal use, default assumed), QQ-005 (Mac
config: host, user, key), QQ-008 (signing team for device builds). QQ-006 and
QQ-007 answered by DEC-003 and DEC-004.

## Blockers

Builds and device checks wait on `xcodebuild -version` (QQ-005). Spec work
does not.
