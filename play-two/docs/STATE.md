# STATE — PlayTwo

> Resume point; history belongs in the role journals. Keep under 40 lines.

**Updated:** 2026-11-21 · **Phase:** build · **Active feature:** FEAT-002 (HAP crypto primitives)
**Active task:** TASK-012 (in-review, attempt 3 — suite 46/46, QA running)

## Status

FEAT-001 (discoverable) complete: ten tasks done through 1eb1170. App builds as
`PlayTwo` (bundle `com.lorand.playtwo`, iOS 15.0) and installs on the iPhone 6s
via `build iphoneos` + `install` + `ios-deploy --justlaunch` (DEC-008); profile
expires 2026-11-23. Suite 38 tests, high-water 38; R1-R11 pass.

## Release note (increment 1 — discoverable)

Human observations O1-O6 reported 2026-11-20: screen shows `PlayTwo` + status;
`dns-sd` resolves one `PlayTwo` at `<device>.local.:7000`; `nc :7000`
succeeds; a second iPhone lists it; restart logs `Restart`; `Export Log` opens
the share sheet. Definition of done met pending human acceptance.

## Next action

TASK-011 done (2026-11-20): TLV8 codec, suite 38/38, R2 high-water 33 → 38.
TASK-012 attempt 3: suite 46/46 green (`SRPTests` 8/8) on `iPhone 14,OS=16.2`;
xcodegen 2.38.0 staged (DEC-016). Decision (a): full 384-byte `v = g^x mod N`.
Dev flags SRPTests at ~16-22 s per derivation in Debug; a DEC is needed before
optimising (candidate: -O test config).
Xcode 14.2: simulators are iOS 16.2 only (iPhone 14/14 Plus/14 Pro/SE 3rd gen);
use `platform=iOS Simulator,name=iPhone 14,OS=16.2`. Agents run
`opencode/deepseek-v4.1-flash-free#low`.
Next: unblock TASK-012 → QA → commit `play-two/TASK-012: derive SRP-3072 verifier
from setup code and salt`, then TASK-013 → 014 → 015, FEAT-003, FEAT-004,
increment 3 (Audible). Open questions before FEAT-003: fixed vs generated setup
code; retirement of the fixed 38-byte reply (R4) once HTTP handling lands.

## Approved gates

G1 (2026-11-15) · G2 (2026-11-15) · G3 (2026-11-16) · G4 for all ten tasks
(TASK-003 had 2 MINOR; TASK-008 crit. 4 relocated to O6). QQ-003, QQ-009 closed.