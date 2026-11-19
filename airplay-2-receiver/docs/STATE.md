# STATE — AirPlay 2 Receiver

> Project resume point. Updated by the BA after every meaningful step. Keep under
> 40 lines; history belongs in `journal/<role>.md`.

**Updated:** 2026-11-15
**Phase:** breakdown
**Active feature:** none
**Active task:** none
**v1:** increment 4 of DEC-002 (discoverable → pairable → audible → useful)

## Status

G1 passed 2026-11-15: SPEC v1.0 and the stack (Swift 5, iOS 15.0, SwiftUI,
Network.framework, CryptoKit, XcodeGen, XCTest, no dependencies) approved.
DEC-001 and DEC-002 stand. PM is breaking increment 1 (discoverable) into atomic
tasks. The Mac bridge is written but untested until local configuration exists and
`xcodebuild -version` passes.

## Next action

1. PM produces FEAT-001 with atomic tasks; BA reviews at G3.
2. QA writes the increment-1 test plan.
3. First developer task (scaffold) needs `xcodebuild -version` to pass,
   otherwise it is written and left unverified.

## Approved gates

| Gate | Scope | Approved | Notes |
| --- | --- | --- | --- |
| G1 | SPEC v1.0 + stack | 2026-11-15 | Human approved; four-increment ladder accepted |

## Open questions

`docs/QUESTIONS.md` — QQ-003 (personal use, default assumed), QQ-005 (Mac
config: host, user, key).

## Blockers

Builds and device checks wait on `xcodebuild -version` (QQ-005). Spec work
does not.
