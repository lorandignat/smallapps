---
id: TASK-013
title: SRP-3072 server generates salt and ephemeral B
feature: FEAT-002
status: done
attempts: 1
owner: null
depends_on: [TASK-012]
estimate: small
---

# TASK-013 — SRP-3072 server generates salt and ephemeral B

## Goal

A server-side step that, given a password verifier, generates a random salt and
a random ephemeral secret `a`, computes the public value `B = (k*v + g^a) mod N`,
and retains `a` and `v` so the later proof step (`TASK-014`) can complete the
handshake.

## Context for the developer

- Where it lives: `src/HAP/SRP.swift` (extend), `test/SRPTests.swift`.
- Interfaces it may touch: `TASK-012`'s `SRP` type and its big-int helpers.
  Use `CryptoKit` or `SecRandomCopyBytes` for randomness; do not add a
  dependency.
- Files in scope (2): the two above.
- Explicitly **do not** touch: `project.yml`, `src/PlayTwoApp.swift`,
  `src/ContentView.swift`, `src/Net/`, `src/AirPlay/`, `docs/`, `qa/`,
  journals other than `journal/<role>.md`, `scripts/`, `.opencode/`.
- State: this task introduces a small `SRPServerSession` (or equivalent) that
  holds `a`, `v`, `B`, `salt` between this step and `TASK-014`. Keep it an
  in-memory value type returned to the caller; do not persist it (pairing is
  `FEAT-003`).

## Acceptance criteria

1. [ ] Given a verifier `v`, when `generateEphemeral(v:)` is called, then it
       returns a salt (≥ 16 random bytes) and a public value `B` with
       `1 <= B < N`.
2. [ ] Given two calls with the same verifier, when compared, then the salts
       and `B` values differ (randomness).
3. [ ] Given the returned session, when inspected, then it retains the
       ephemeral secret `a` and the verifier `v` needed by `TASK-014`.
4. [ ] `SRPTests` passes: `Executed N tests, with 0 failures`, including the
       three cases above.

## Verification commands

```sh
# on this host
ls play-two/src/HAP play-two/test

# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.5' | tee /tmp/opencode/task-013-test.log
grep -E "Test Suite 'SRPTests' (passed|failed)" /tmp/opencode/task-013-test.log
```

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-013-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes
- [ ] One commit `play-two/TASK-013: SRP-3072 server generates salt and ephemeral B` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- `k = H(N || g)` (SRP-6a multiplier) is computed once and reused.
- The salt must be fresh per handshake (never reuse), even for the same
  verifier.
- Do not log or persist `a`, `v`, or the salt beyond the session object.