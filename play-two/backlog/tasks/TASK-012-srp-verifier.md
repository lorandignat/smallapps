---
id: TASK-012
title: Derive SRP-3072 verifier from setup code and salt
feature: FEAT-002
status: blocked
attempts: 2
owner: null
depends_on: []
estimate: small
---

# TASK-012 — Derive SRP-3072 verifier from setup code and salt

## Goal

A pure function that, given an 8-digit HAP setup code and a salt, derives the
SRP-3072 password verifier `v = g^x mod N` where `x = SHA512(salt || setupCode)`
interpreted as a big integer, using the RFC 3526 3072-bit group (N, g).

## Context for the developer

- Where it lives: `src/HAP/SRP.swift` (new), `test/SRPTests.swift` (new).
- Interfaces it may touch: `CryptoKit` (SHA512) and `Foundation` only. Big
  integers are handled in-project (no dependency) — use `Data` plus manual
  modular exponentiation; do not add a package.
- Files in scope (2): the two above.
- Explicitly **do not** touch: `project.yml`, `src/PlayTwoApp.swift`,
  `src/ContentView.swift`, `src/Net/`, `src/AirPlay/`, `docs/`, `qa/`,
  journals other than `journal/<role>.md`, `scripts/`, `.opencode/`.
- Constants: N and g are the RFC 3526 3072-bit group parameters; hash is SHA-512
  (HAP). Define them as `static let` in `SRP`. `k = H(N || g)` (SRP-6a) or
  the HAP-specified multiplier — check the HAP spec; HAP uses SRP with the
  standard multiplier. Document which in a comment.

## Acceptance criteria

1. [ ] Given setup code `"00102003"` and a fixed salt, when the verifier is
       derived twice, then both results are byte-identical (deterministic).
2. [ ] Given the same setup code but two different salts, when derived, then
       the two verifiers differ.
3. [ ] Given any valid input, when derived, then the verifier `v` satisfies
       `1 <= v < N` (never 0, never N).
4. [ ] Given setup code `"00102003"`, when derived, then `x` is computed as
       `SHA512(salt || utf8(setupCode))` reduced per SRP (document the exact
       byte order in a comment).
5. [ ] `SRPTests` passes: `Executed N tests, with 0 failures`, including the
       four cases above.

## Verification commands

```sh
# on this host
ls play-two/src/HAP play-two/test

# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.5' | tee /tmp/opencode/task-012-test.log
grep -E "Test Suite 'SRPTests' (passed|failed)" /tmp/opencode/task-012-test.log
```

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-012-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes
- [ ] One commit `play-two/TASK-012: derive SRP-3072 verifier from setup code and salt` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- This task owns the big-int helpers (`modExp`, byte<->int conversion) that
  `TASK-013` and `TASK-014` reuse; put them in `SRP` as internal static
  methods.
- Performance: modular exponentiation of 3072-bit numbers on A9 may take
  hundreds of ms. Measure in the test; if a single derivation exceeds ~2 s,
  record a `DEC-###` before optimising, do not silently change the algorithm.
- Setup code handling: strip dashes, validate 8 digits. If invalid, return nil.