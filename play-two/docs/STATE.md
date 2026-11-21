# STATE — PlayTwo

> Resume point; history belongs in the role journals. Keep under 40 lines.

**Updated:** 2026-11-21 · **Phase:** build · **Active feature:** FEAT-002 (HAP crypto primitives)
**Active task:** TASK-012 (in-progress, attempt 1, decision (a))

## Status

FEAT-001 (discoverable) complete: all ten tasks done, committed through 1eb1170.
App builds as `PlayTwo`, bundle id `com.lorand.playtwo`, iOS 15.0 target; signed
device build installs and launches on the iPhone 6s (iOS 15.8.8) via `build …
iphoneos` + `install` + `ios-deploy --justlaunch` (DEC-008). Profile expires
2026-11-23. Suite at 38 tests, high-water mark 38; regressions R1-R11 pass.

## Release note (increment 1 — discoverable)

Human observations O1-O6 all reported 2026-11-20: screen reads
`PlayTwo` with status text; `dns-sd` shows one `PlayTwo` resolving to
`<device>.local.:7000`; `nc :7000` succeeds; a second iPhone lists
PlayTwo in its AirPlay picker; restart log line is `Restart`; `Export Log` opens
the share sheet with `airplay-receiver-log.txt`. No FAIL/BLOCKED tasks remain.
Definition of done met pending human acceptance.

## Next action

TASK-011 done at G4 (PASS, 1/5, attempt 1, 2026-11-20): TLV8 codec written,
suite 38/38 (`TLV8Tests` 5/5), regressions R1/R2/R5 pass (R2 high-water 33 →
38, QA-closed R5 literal). Commit `play-two/TASK-011: TLV8 codec (encode and decode)`.
TASK-012 in-progress (attempt 1, decision (a): full 384-byte `v = g^x mod N`).
Mac is up: Xcode 14.2, simulators are iOS 16.2 only (iPhone 14 / 14 Plus / 14
Pro / SE 3rd gen), so the old `iPhone 16e,OS=26.5` destination must be replaced
with e.g. `platform=iOS Simulator,name=iPhone 14,OS=16.2`. All agents now run
`opencode/deepseek-v4.1-flash-free#low`.
Next: dev → QA → commit `play-two/TASK-012: derive SRP-3072 verifier from setup
code and salt`, then TASK-013 → 014 → 015, FEAT-003, FEAT-004, increment 3
(Audible). Open questions before FEAT-003: fixed vs generated setup code;
retirement of the fixed 38-byte reply (R4) once HTTP handling lands.

## Approved gates

G1 (2026-11-15) · G2 (2026-11-15) · G3 (2026-11-16) · G4 for all ten tasks
(TASK-003 had 2 MINOR; TASK-008 crit. 4 relocated to O6). QQ-003, QQ-009 closed.