# STATE — PlayTwo

> Project resume point. Updated by the BA after every meaningful step. Keep under
> 40 lines; history belongs in the role journals.

**Updated:** 2026-11-16
**Phase:** build
**Active feature:** FEAT-001
**Active task:** TASK-003 next
**v1:** increment 4 of DEC-002 (discoverable → pairable → audible → useful)

## Status

G1 passed. FEAT-001 has ten tasks; TASK-001 (scaffold), TASK-002 (TXT record)
and TASK-010 (rename to PlayTwo) are **done**, all PASSed on the real Mac. The app builds as `PlayTwo`,
bundle id `com.lorand.playtwo`, iOS 15.0 deployment target. Since 2026-11-16 a
signed device build also installs and launches on the iPhone 6s (iOS 15.8.8) via
`xcodebuild build … iphoneos` and `ios-deploy`. Signing uses the free Apple ID,
so the profile expires 2026-11-23 and the app must be rebuilt then.

## Next action

1. TASK-003 (TCP listener on 7000), then 004-008 in dependency order.
2. TASK-009 last: the README "Running it on the iPhone" section.

## Approved gates

| Gate | Scope | Approved | Notes |
| --- | --- | --- | --- |
| G1 | SPEC v1.0 + stack | 2026-11-15 | Human approved; four-increment ladder accepted |
| G2 | FEAT-001 (discoverable) | 2026-11-15 | Vertical slice, traces to S1/S5; increments 2-4 have no features yet |
| G3 | TASK-001 to TASK-010 | 2026-11-16 | Ten tasks pass the atomicity checklist; TASK-009 re-cut after DEC-008 |
| G4 | TASK-001 | 2026-11-16 | PASS, 5/5 criteria; findings carried into later tasks |
| G4 | TASK-010 | 2026-11-16 | PASS, 7/7 criteria; README commands fixed at close |
| G4 | TASK-002 | 2026-11-16 | PASS, 5/5 criteria on attempt 2; three minor findings recorded |

## Open questions

`docs/QUESTIONS.md` — QQ-003 (personal use, default assumed). QQ-005, QQ-006,
QQ-007 and QQ-008 are answered.

## Blockers

None. Device observations S1b, S1c and S5 are unverified until the app runs on the
phone with the advertisement in place, but nothing is blocked on tooling.
