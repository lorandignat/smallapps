# STATE — PlayTwo

> Resume point; history belongs in the role journals. Keep under 40 lines.

**Updated:** 2026-11-21 · **Phase:** build · **Active feature:** FEAT-002 (HAP crypto primitives)
**Active task:** TASK-013 (in-review, attempts 1)

## Status

FEAT-001 (discoverable) complete: ten tasks through 1eb1170. App builds as
`PlayTwo` (bundle `com.lorand.playtwo`, iOS 15.0) and installs on the iPhone 6s
via `build iphoneos` + `install` + `ios-deploy --justlaunch` (DEC-008); profile
expires 2026-11-23. Suite 38 tests; R1-R11 pass.

## Release note (increment 1 — discoverable)

Human observations O1-O6 reported 2026-11-20: screen shows `PlayTwo` + status;
`dns-sd` resolves one `PlayTwo` at `<device>.local.:7000`; `nc :7000`
succeeds; a second iPhone lists it; restart logs `Restart`; `Export Log` opens
the share sheet. Definition of done met pending human acceptance.

## Next action

TASK-011 done (2026-11-20): TLV8 codec, suite 38/38, R2 high-water 33 → 38.
TASK-012 done (2026-11-21): G4 PASS, commit `play-two/TASK-012: derive
SRP-3072 verifier from setup code and salt`, suite 46/46, R2 high-water 46, QA
report `qa/reports/TASK-012-review.md`. DEC-017 (proposed) records the
watchdog/perf finding. Next: TASK-013 (SRP ephemeral B), attempts 0, approved,
depends on TASK-012. Destination `platform=iOS Simulator,name=iPhone 14,OS=16.2`.
Agents run `opencode/beam-free`. Open questions before FEAT-003: fixed vs
generated setup code; retirement of the fixed 38-byte reply (R4).

## Approved gates

G1 (2026-11-15) · G2 (2026-11-15) · G3 (2026-11-16) · G4 for ten tasks
(TASK-003 2 MINOR; TASK-008 crit. 4 → O6). QQ-003, QQ-009 closed.