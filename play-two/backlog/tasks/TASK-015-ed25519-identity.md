---
id: TASK-015
title: Ed25519 accessory identity key with Keychain persistence
feature: FEAT-002
status: in-progress
attempts: 1
owner: null
depends_on: []
estimate: small
---

# TASK-015 — Ed25519 accessory identity key with Keychain persistence

## Goal

Generate an Ed25519 key pair on first run, persist the private key in the
Keychain, and reload the same key pair on later runs, exposing the 32-byte
public key. This is the HAP long-term identity used by pairing (`FEAT-003`),
distinct from the AirPlay device id in `UserDefaults`.

## Context for the developer

- Where it lives: `src/HAP/AccessoryIdentity.swift` (new),
  `test/AccessoryIdentityTests.swift` (new).
- Interfaces it may touch: `CryptoKit` (Curve25519.Signing) and the Security
  framework (Keychain). No new dependency.
- Files in scope (2): the two above.
- Explicitly **do not** touch: `project.yml`, `src/PlayTwoApp.swift`,
  `src/ContentView.swift`, `src/Net/`, `src/AirPlay/`, `docs/`, `qa/`,
  journals other than `journal/<role>.md`, `scripts/`, `.opencode/`.
- Keychain: service `com.lorand.playtwo.hap-identity`, account `accessory`,
  `kSecClassGenericPassword` (or `kSecClassKey`), accessible
  `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. Store the raw 32-byte
  private key (seed) as the password data.

## Acceptance criteria

1. [ ] Given no stored key, when `loadOrCreate()` is called, then it generates
       a new Ed25519 key pair and returns a public key of exactly 32 bytes.
2. [ ] Given a stored key, when `loadOrCreate()` is called again in the same
       process, then the returned public key bytes are identical to the first
       call.
3. [ ] Given a key stored in a previous (simulated) run, when `loadOrCreate()`
       is called with the Keychain entry present, then it returns that same
       public key rather than generating a new one.
4. [ ] Given the Keychain entry is deleted, when `loadOrCreate()` is called,
       then a new key pair is generated and stored, and the public key differs
       from the deleted one.
5. [ ] `AccessoryIdentityTests` passes: `Executed N tests, with 0 failures`,
       including the four cases above.

## Verification commands

```sh
# on this host
ls play-two/src/HAP play-two/test

# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.5' | tee /tmp/opencode/task-015-test.log
grep -E "Test Suite 'AccessoryIdentityTests' (passed|failed)" /tmp/opencode/task-015-test.log
```

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-015-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes
- [ ] One commit `play-two/TASK-015: Ed25519 accessory identity key with Keychain persistence` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- Tests must use a unique Keychain service string (e.g. append a UUID) per
  test case and delete the entry in teardown, so they do not collide with each
  other or with a real install.
- `CryptoKit`'s `Curve25519.Signing.PrivateKey` is created from a 32-byte seed;
  store the seed. Regenerate the private key from the stored seed on load.
- Do not store the private key in `UserDefaults` or a file — Keychain only
  (`SPEC` §7).