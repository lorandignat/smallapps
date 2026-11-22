# STATE — PlayTwo

> Resume point; history belongs in the role journals. Keep under 40 lines.

**Updated:** 2026-11-22 · **Phase:** build · **Active feature:** FEAT-003 (HAP pairing endpoints)
**Active task:** TASK-019 (FEAT-003, in-progress, attempt 1)

## Status

TASK-017 done (2026-11-22): G4 PASS, commit 119d964, HAPPairingStore Keychain
round-trip (service com.lorand.playtwo.hap-pairing, account pairing), suite
68/0, R2 high-water 68, `qa/reports/TASK-017-review.md`. FEAT-003: 2 of 6.
TASK-016 done (2026-11-22): G4 PASS, commit f1e9cc5, suite 62/0, R2 high-water
62, `qa/reports/TASK-016-review.md`. FEAT-003: 1 of 6.

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

TASK-019 done (2026-11-22): G4 PASS, commit 4760239, HAPPairVerify Session
(ephemeral keypair, proof = SRP.sha512(A_e ‖ B_e ‖ accessoryIdentityPublicKey ‖ T),
key armed, seal/open via CryptoKit); routes POST /pair-verify (req 1 → 200 + TLV 2;
req 2 → 200 + TLV 3, 400 on tamper). HAPPairVerifyTests 4/0, HAPServerTests 10/0,
bundle 78/0, R2 high-water 78, `qa/reports/TASK-019-review.md`. FEAT-003: 4 of 6.
TASK-020 done (2026-11-22): G4 PASS, commit ab7268c, AirPlayTXTRecord +
ServiceAdvertiser (`sf` in the dictionary, always present; `statusFlags`,
`statusFlagPaired`, `statusFlagString`); AirPlayTXTRecordTests 8/0,
ServiceAdvertiserTests 4/0, bundle 79/0, R2 high-water 79,
`qa/reports/TASK-020-review.md`. FEEST-003: 5 of 6.
TASK-018 done (2026-11-22): G4 PASS, commit cb1429e, HAPPairSetup + POST
/pair-setup route, HAPPairSetupTests 4/0, HAPServerTests 9/0, bundle 73/0,
R2 high-water 73, `qa/reports/TASK-018-review.md`. FEAT-003: 3 of 6.
TASK-017 done (2026-11-22): G4 PASS, commit 119d964, HAPPairingStore Keychain
round-trip, suite 68/0, R2 high-water 68, `qa/reports/TASK-017-review.md`.
FEAT-003: 2 of 6.
TASK-016 done (2026-11-22): G4 PASS, commit f1e9cc5, suite 62/0, R2
high-water 62, `qa/reports/TASK-016-review.md`. FEAT-003: 1 of 6.
TASK-011 done (2026-11-20): TLV8 codec, suite 38/38, R2 high-water 33 → 38.
TASK-012 done (2026-11-21): G4 PASS, suite 46/46, R2 high-water 46,
`qa/reports/TASK-012-review.md`. TASK-013 done: SRP-3072 server ephemeral B,
suite 11/11, R2 high-water 50 (`qa/reports/TASK-013-review.md`). TASK-014 done:
SRP verify M1, full bundle 52/0, R2 high-water 52
(`qa/reports/TASK-014-review.md`). DEC-017 (proposed) still pending for the
watchdog/perf finding. Next: TASK-021 — Restart survival — show the setup code and paired state on the
state screen. `ReceiverStatus.paired` case; `AppState(advertiser:pairingStore:)`
starts as `.paired` and `AppState.map(.advertising)` returns `.paired` while
`pairingStore.paired`; `ContentView` already displays `HAPServer.setupCode`
(static, `00102003`, TASK-016's constant — the grep checks are in the task
file). Destination `platform=iOS Simulator,name=iPhone 14,OS=16.2`. S2b
(human observation at feature close): with pairing stored, the Home app shows
no re-pair prompt and the state screen reads `Paired`. R4 reword at
FEEST-003 close (`qa/REGRESSION.md` row currently stale).

## Approved gates

G1 (2026-11-15) · G2 (2026-11-15) · G3 (2026-11-16) · G4 for fourteen tasks (TASK-003 2 MINOR; TASK-008 crit. 4 → O6; TASK-016; TASK-018; TASK-019; TASK-020). QQ-003, QQ-009 closed.