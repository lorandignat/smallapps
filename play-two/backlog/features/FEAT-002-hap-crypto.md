---
id: FEAT-002
title: HAP crypto primitives
status: approved
slice: An SRP-3072 handshake completes between the accessory and a test client and both sides agree on a session key; TLV8 round-trips; an Ed25519 identity key persists across launches.
spec_ref: product/SPEC.md#4-scope-v1
depends_on: [FEAT-001]
---

# FEAT-002 — HAP crypto primitives

**Demo:** 1. Run the unit suite: `SRPTests` shows a full SRP-3072 handshake
round-tripping and both sides deriving the same session key, `TLV8Tests` shows
encode/decode round-trips (including values over 255 bytes), and
`AccessoryIdentityTests` shows the Ed25519 key survives a reload. 2. Read the
state screen: it still reads `Advertising as PlayTwo` — this feature adds no
network behaviour and changes nothing the Apple TV sees.

This is the first slice of increment 2 (`DEC-002`). It exists to retire the
riskiest part of pairing before any Home app work: SRP-3072 big-integer
arithmetic on iOS 15, done in-project because the stack allows no crypto
dependency (`docs/STACK.md`, `DEC-001`). If SRP cannot be made to work here, the
endpoints in `FEAT-003` do not get written.

## User value

The owner wants the phone in the Home app. Before that can happen, the
protocol's cryptography has to be proven on the device's actual OS and toolchain.
This slice delivers that proof as runnable, repeatable tests, so a later
failure in the Home app is a protocol or transport bug, not a math bug.

## In scope

- [ ] TLV8 encode/decode, including the multi-fragment form for values over 255
      bytes (HAP message framing).
- [ ] SRP-3072: verifier derivation from a setup code and salt; server-side
      ephemeral generation (salt + B); client-proof verification (M1) and
      server-proof (M2) plus session-key (K) derivation.
- [ ] Ed25519 accessory identity key pair, generated on first run and persisted
      in the Keychain, reloaded on later runs (`SPEC` §7, "pairing keys are
      stored in the Keychain").
- [ ] Unit tests proving a complete SRP handshake round-trips and both sides
      agree on K, and that the Ed25519 key persists.

## Out of scope

- HTTP transport on port 7000, HAP endpoints (`/info`, `/pair-setup`,
  `/pair-verify`), pairing storage and restart survival — `FEAT-003`.
- The advertised-name settings screen — `FEAT-004`.
- Setup-code display or generation UI — `FEAT-003`/`FEAT-004`; this feature
  uses a fixed setup code constant for the tests.
- RTSP, FairPlay, audio — increment 3.

## Acceptance criteria (feature level)

- [ ] **Crypto (automated).** Given the unit suite, when it runs, then
      `TLV8Tests`, `SRPTests` and `AccessoryIdentityTests` all pass with 0
      failures, and `SRPTests` contains a case where a test client and the
      accessory derive the same session key K from a completed handshake.
- [ ] **Persistence (automated).** Given an Ed25519 key generated in one test
      run, when the identity is reloaded in a second test, then the public key
      bytes are identical (Keychain round-trip).
- [ ] **No new dependencies.** `project.yml` still declares no packages; SRP
      is in-project (`docs/STACK.md`).
- [ ] Every task in the table below is `done` with a `qa` verdict of `PASS`.

## Tasks

Dependency order, one at a time. Only this feature is broken down; `FEAT-003`
and `FEAT-004` stay at feature level until their turn (`DEC-002`).

| ID | Title | Status |
| --- | --- | --- |
| TASK-011 | TLV8 codec (encode and decode) | proposed |
| TASK-012 | Derive SRP-3072 verifier from setup code and salt | proposed |
| TASK-013 | SRP-3072 server: generate salt and ephemeral B | proposed |
| TASK-014 | SRP-3072 server: verify client proof and derive session key | proposed |
| TASK-015 | Ed25519 accessory identity key with Keychain persistence | proposed |

## Notes

**Setup code.** v1 uses a single fixed setup code constant (e.g. `00102003`)
for the SRP verifier and for the tests. Generating and displaying a per-install
code is a UX decision deferred to `FEAT-003`/`FEAT-004`; record the choice
with the BA before that work, since a fixed code weakens pairing security and
the Home app's "Add Accessory" flow shows the code to the user. (`QQ-006`-style
open question.)

**SRP constants.** SRP-3072 group (N, g) and the hash (SHA-512, per HAP) are
fixed by the protocol; they live as constants in `src/HAP/SRP.swift`. N is the
3072-bit RFC 3526 group. No configuration.

**Keychain on the simulator.** `AccessoryIdentityTests` run against the
simulator's default keychain; each test uses a unique service/label and
deletes its entry in teardown so runs do not leak state into each other or into
the device.

**Risk.** SRP-3072 big-integer modular exponentiation is the part most likely
to be slow or wrong on A9. If `TASK-013`/`TASK-014` cannot be kept under the
per-task time budget, split them further or record a `DEC-###` proposing a
different big-int approach before coding. Do not add a dependency without a
`DEC-###` (`docs/STACK.md`).

**Open questions for the BA.**

- Fixed vs. generated setup code (above) — needs a human preference before
  `FEAT-003`.
- Whether `FEAT-002` stays as crypto-only or is folded back into one
  pairing feature at G2. PM split it out to keep task sizes atomic and to
  retire the crypto risk first; the BA may re-merge.