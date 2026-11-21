---
id: TASK-014
title: SRP-3072 server verifies client proof and derives session key
feature: FEAT-002
status: in-progress
attempts: 1
owner: null
depends_on: [TASK-013]
estimate: small
---

# TASK-014 — SRP-3072 server verifies client proof and derives session key

## Goal

The completing step of the SRP-3072 handshake: given the client's public value
`A` and client proof `M1`, verify `M1`; on success derive the session key `K`
and the server proof `M2`; on failure return nil so the caller aborts the
pairing. A test client and the accessory must agree on `K`.

## Context for the developer

- Where it lives: `src/HAP/SRP.swift` (extend), `test/SRPTests.swift`.
- Interfaces it may touch: `TASK-013`'s `SRPServerSession`.
- Files in scope (2): the two above.
- Explicitly **do not** touch: `project.yml`, `src/PlayTwoApp.swift`,
  `src/ContentView.swift`, `src/Net/`, `src/AirPlay/`, `docs/`, `qa/`,
  journals other than `journal/<role>.md`, `scripts/`, `.opencode/`.
- Formulas (SRP-6a): `u = H(A || B)`; `S = (A * v^u)^a mod N`;
  `K = H(S)`; `M1 = H(A || B || K)` (client computes and sends this);
  `M2 = H(A || M1 || K)` (server computes and returns). Abort if the client's
  `M1` does not equal the recomputed `M1`.

## Acceptance criteria

1. [ ] Given a valid client proof `M1` from a matching test client, when
       `verify(session:clientA:clientM1:)` is called, then it returns `M2` and
       `K`, and the returned `M2` equals the value the test client computes
       independently.
2. [ ] Given a tampered `M1` (one bit flipped), when verify is called, then it
       returns nil and no `K` is exposed.
3. [ ] Given a completed handshake, when the accessory's `K` and the test
       client's `K` are compared, then they are byte-identical.
4. [ ] Given `A == 0` or `A % N == 0`, when verify is called, then it
       aborts (returns nil) rather than dividing by zero.
5. [ ] `SRPTests` passes: `Executed N tests, with 0 failures`, including a
       round-trip test exercising criteria 1 and 3.

## Verification commands

```sh
# on this host
ls play-two/src/HAP play-two/test

# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.5' | tee /tmp/opencode/task-014-test.log
grep -E "Test Suite 'SRPTests' (passed|failed)" /tmp/opencode/task-014-test.log
```

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-014-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes
- [ ] One commit `play-two/TASK-014: SRP-3072 server verifies client proof and derives session key` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- The test client in `SRPTests` implements the client side of SRP-6a using the
  same big-int helpers, so the round-trip exercises both sides with one codebase.
- Clear the session (`a`, `v`) from memory after verify returns, success or
  failure.
- Do not reuse `a` or `B` across handshakes.