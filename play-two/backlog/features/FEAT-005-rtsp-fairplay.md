---
id: FEAT-005
title: RTSP setup and FairPlay v3 key decryption
status: approved
slice: An Apple TV's RTSP setup completes against the phone and the FairPlay v3 handshake yields the AES stream key; the phone speaker is still silent.
spec_ref: product/SPEC.md#4-scope-v1
depends_on: [FEAT-003]
---

# FEAT-005 — RTSP setup and FairPlay v3 key decryption

**Demo:** 1. Run the unit suite: RTSP request parsing, the `OPTIONS` 200 reply,
the FairPlay field parsing, `Apple-Response` generation and stream-key
decryption all pass against recorded fixtures, including their failure cases.
2. On the iPhone 6s with the app foregrounded, select the phone on the Apple TV
and export the log: it contains the `RTSP OPTIONS` and `RTSP SETUP` lines and a
`FairPlay key decrypted` line for that stream, and the phone's own speaker
produces no audio (there is no audio path yet).

This is the first slice of increment 3 of `DEC-002`, the "RTSP setup + FairPlay
v3 — get an AES key and decrypt a stream, no audio output yet" phase of
`SPIKE-001`. It is the kill-switch for the audible increment: if a sideloaded
app cannot complete the RTSP/FairPlay exchange and recover the AES key on iOS
15, `FEAT-006` has no stream to decode. It depends on `FEAT-003` at the code and
task level: the RTSP request arrives on the same AirPlay port whose HTTP routing
and encrypted HAP session that feature built.

**Caveat carried in, not a blocker.** FEAT-003 closed at code/task level on
2026-11-22, but `S2a` and `S2b` (Home app "Add Accessory" and pairing survival)
are still pending human observations on the iPhone 6s. The human has explicitly
asked to proceed into increment 3. This breakdown therefore treats FEAT-003's
code as the dependency and records the pending observations here and in
`qa/TEST-PLAN.md`; they are not a gate on starting FEAT-005.

**G2 approved 2026-11-22 (BA).** Vertical slice, demoable, dependency-ordered
after FEAT-003, traces to SPEC §4 increment 3 / §6 S3 path, not infra-only;
FEAT-006 remains proposed at feature level.

## User value

The owner wants the TV's audio out of the phone. Before anything can be heard,
the phone has to complete the exchange a real Apple TV performs when it selects
a speaker and recover the key that unlocks the stream. Proving that first makes
every later silence attributable to audio decode or output, not to the
handshake.

## In scope

- [ ] Parse an RTSP request (request line and headers) received on the AirPlay
       port (SPEC §4, "RTSP setup"; SPEC §3 step 3).
- [ ] Answer an `OPTIONS * RTSP/1.0` request with a valid `RTSP/1.0 200 OK`
       response echoing its `CSeq`.
- [ ] Route `RTSP/1.0` requests to the RTSP handler while the existing HAP HTTP
       routes keep answering `HTTP/1.1` requests (`DEC-018` behaviour retained).
- [ ] Parse the FairPlay fields of a `SETUP` request (the `Apple-Challenge` and
       the encrypted stream-key material) into a model, with failure paths.
- [ ] Complete the FairPlay v3 handshake: generate `Apple-Response` from a
       challenge using an injected key table (SPEC §4, "FairPlay v3 handshake").
- [ ] Decrypt the AES stream key with FairPlay v3 using an injected key table,
       proven against a known-answer fixture (SPEC §4, "key decryption").
- [ ] Log the RTSP and FairPlay milestones so the human's device observation is
       backed by evidence (SPEC §4, "A log view exportable to a file").

## Out of scope

- Audio buffering, ALAC decode, `AVAudioSession` and any sound from the phone
  speaker or a Bluetooth speaker — `FEAT-006` and increment 4.
- Playing, timing or PTP synchronisation of the stream; this feature stops once
  the AES key is in hand.
- Changing HAP pairing, the stored pairing or the setup code — `FEAT-003`.
- The advertised-name settings screen — `FEAT-004` (stays proposed, not broken
  down in this job).
- Home app control beyond adding the accessory — non-goal (SPEC §5).
- Screen mirroring, video, HLS, AirPlay 1 senders and multiple concurrent
  senders — non-goals (SPEC §5).
- Adding a Swift package, SDK or tool, or committing real FairPlay key tables —
  `docs/STACK.md`, SPEC §7, `DEC-001`.

## Acceptance criteria (feature level)

- [ ] **Protocol (automated).** Given the unit suite, when it runs on
      `platform=iOS Simulator,name=iPhone 14,OS=16.2`, then
      `RTSPRequestTests`, `RTSPResponseTests`, `RTSPRouteTests`,
      `FairPlayFieldTests` and `FairPlayTests` all pass with 0 failures, and
      each named task below records its own `Executed N tests, with 0 failures`
      line.
- [ ] **Key recovery (automated).** Given a recorded `SETUP` fixture and an
      injected *synthetic* key table, when the FairPlay layer runs, then it
      emits the fixture's `Apple-Response` and decrypts the fixture's encrypted
      key to the fixture's known AES key bytes. No real Apple DRM table is used
      in a test.
- [ ] **Regression (automated).** The HAP HTTP routes still answer: `R4` shows
      `HAPServerTests` 10/10 and `ReceiverListenerTests` 4/4, and `R2` is ≥ 81,
      the high-water mark after TASK-021, raising as each task below adds tests.
- [ ] **Device (human).** Given the app is foregrounded on the iPhone 6s and
      the Apple TV selects it, when the human exports the log after the
      exchange, then it shows the `RTSP OPTIONS`, `RTSP SETUP` and
      `FairPlay key decrypted` lines for that session and the phone speaker is
      silent.
- [ ] **No new dependencies or key material.** `grep -c 'packages:'
      play-two/project.yml` → `0`; no FairPlay key table, binary resource or
      credential appears in the repository (`SPEC` §7, `DEC-001`).
- [ ] Every task in the table below is `done` with a `qa` verdict of `PASS`.

## Tasks

Dependency order, one at a time. Only this feature is broken down; `FEAT-006`
and increment 4 stay at feature level until their turn (`DEC-002`). TASK-025 is
a decision brief: TASK-027 and TASK-028 must not start until the BA has
recorded the resulting `DEC-###` and the key-table boundary is settled.

| ID | Title | Status |
| --- | --- | --- |
| TASK-022 | Parse an RTSP request line and headers | proposed |
| TASK-023 | Answer an RTSP OPTIONS request with 200 OK | proposed |
| TASK-024 | Route RTSP requests on the AirPlay port | proposed |
| TASK-025 | Decide how FairPlay key tables enter the app | proposed |
| TASK-026 | Parse the FairPlay fields of a SETUP request | proposed |
| TASK-027 | Generate Apple-Response from a challenge and test key table | proposed |
| TASK-028 | Decrypt the stream key with FairPlay v3 and a test key table | proposed |

R2 high-water is **81** after TASK-021 (`qa/REGRESSION.md` R2). Planned counts,
recorded in each task: 84 after TASK-022, 87 after 023, 89 after 024, unchanged
by the decision task 025, 92 after 026, 94 after 027 and 96 after 028. QA/BA
record the actual counts; these are expectations, not evidence.

## Notes

**Open question — FairPlay key-table supply (`QQ-010`, DEC needed).** SPEC §7
and `docs/STACK.md` say increment 3 needs the extracted key tables from the
openairplay receiver and that this is personal, sideload-only material, but
neither says how those tables enter the app, what format they take, who supplies
them, or how they stay out of version control. That cannot be settled from the
spec/stack, and no dependency may be added to resolve it (`docs/STACK.md`).
TASK-025 produces a decision brief for the BA; the BA records a `DEC-###`
(involving the human: DRM material and a credential-equivalent asset). The
implementation tasks use only an injected synthetic table and a known-answer
fixture, so they can be written and tested without guessing the real source.

**Open question — FairPlay v3 algorithm source (DEC needed).** The spec names
the handshake and decryption but not the algorithm's in-project shape. Porting
it from the reference receiver is a protocol port, not a new dependency; if the
developer finds that Apple's on-device FairPlay APIs would be needed instead,
that is a `DEC-###` and human approval, not a silent substitution. TASK-027 and
TASK-028 must stay within one sitting each; if either cannot, stop and ask for
a further split rather than growing the task.

**Open question — ALAC decode route (`QQ-011`, DEC needed).** Recorded in
`FEAT-006`, not here: the stack lists Network.framework, CryptoKit,
AVAudioSession and XCTest but no audio-decode framework. Using AudioToolbox's
ALAC converter, or porting a decoder in-project, is a decision for the BA before
FEAT-006 is broken down. It does not block this feature.

**No simulator-only behaviour.** Every command uses
`platform=iOS Simulator,name=iPhone 14,OS=16.2` (Xcode 14.2 on this host).
Simulator runs prove parsing, framing and known-answer crypto only. The RTSP
and FairPlay exchange with a real Apple TV is the human's observation on the
iPhone 6s, as in FEAT-001..003.

**Wire-level fixtures.** The RTSP and FairPlay fixtures are recorded from the
reference receiver behaviour named in `SPIKE-001` or from a real Apple TV on
the 6s; the task files state which. No header is invented to make a test pass.
If a required response header is discovered only on the device, that is a
re-cut of TASK-023, not a silent edit at feature close.

**Kill-switch.** Per `DEC-002`, a failure that prevents key recovery ends
increment 3; `FEAT-006` is not written on a failed increment 3.
