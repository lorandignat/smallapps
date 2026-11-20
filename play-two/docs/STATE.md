# STATE — PlayTwo

> Resume point; history belongs in the role journals. Keep under 40 lines.

**Updated:** 2026-11-20 · **Phase:** build · **Active feature:** FEAT-002 (HAP crypto primitives)
**Active task:** none — G2/G3 approved, TASK-011 next (increment 2 / pairable)

## Status

FEAT-001 (discoverable) complete: all ten tasks done, committed through 1eb1170.
App builds as `PlayTwo`, bundle id `com.lorand.playtwo`, iOS 15.0 target; signed
device build installs and launches on the iPhone 6s (iOS 15.8.8) via `build …
iphoneos` + `install` + `ios-deploy --justlaunch` (DEC-008). Profile expires
2026-11-23. Suite at 33 tests, high-water mark 33; regressions R1-R11 pass.

## Release note (increment 1 — discoverable)

Human observations O1-O6 all reported 2026-11-20: screen reads
`PlayTwo` with status text; `dns-sd` shows one `PlayTwo` resolving to
`<device>.local.:7000`; `nc :7000` succeeds; a second iPhone lists
PlayTwo in its AirPlay picker; restart log line is `Restart`; `Export Log` opens
the share sheet with `airplay-receiver-log.txt`. No FAIL/BLOCKED tasks remain.
Definition of done met pending human acceptance.

## Next action

Increment 1 shipped and accepted. PM broke down increment 2 into FEAT-002
(crypto primitives, 5 tasks TASK-011..015), FEAT-003 (pairing endpoints,
feature level), FEAT-004 (configurable name, feature level). G2/G3 approved.
Build loop starts with TASK-011 (TLV8 codec, no dependencies). Open questions
before FEAT-003: fixed vs generated setup code; retirement of the fixed 38-byte
reply (R4) once HTTP handling lands.

## Approved gates

G1 (2026-11-15) · G2 (2026-11-15) · G3 (2026-11-16) · G4 for all ten tasks
(TASK-003 had 2 MINOR; TASK-008 crit. 4 relocated to O6). QQ-003, QQ-009 closed.