---
id: FEAT-006
title: Buffered ALAC playback on the phone speaker
status: proposed
slice: With the AES key from FEAT-005, a real Apple TV stream is buffered, ALAC-decoded and heard on the phone's own speaker for ten minutes without dropping.
spec_ref: product/SPEC.md#4-scope-v1
depends_on: [FEAT-005]
---

# FEAT-006 — Buffered ALAC playback on the phone speaker

**Demo:** 1. On the iPhone 6s with the app foregrounded, select the phone on the
Apple TV and play a track: the audio is heard from the phone's own speaker,
following the stream rather than drifting against it. 2. Let it play for 10
continuous minutes and export the log: it records decoded ALAC frames and zero
buffer underruns, and the human reports no drop across the whole listen.

This is the second slice of increment 3 of `DEC-002`, the "buffered audio +
ALAC decode — play through the phone speaker" phase of `SPIKE-001`, and the
owner of success criterion `S3`. It depends on `FEAT-005`: there is nothing to
buffer or decode until the RTSP exchange has yielded the AES stream key.

**Not broken down in this job.** `DEC-002` breaks down one feature at a time;
FEAT-005 is the first feature of this increment, so this file stays at feature
level until FEAT-005 closes (G2/G3 for this feature comes later).

## User value

The owner wants to hear the TV's audio. This is the first slice with sound: the
stream is decrypted, decoded and played on hardware they already own. The
phone's own speaker is the target here because it is the only output with the
timing needed for the increment's demonstration; Bluetooth output belongs to
the next increment (`DEC-002`, SPEC §7).

## In scope

- [ ] Consume the decrypted stream from `FEAT-005` into a bounded audio buffer
       that tolerates packet jitter (SPEC §4, "buffered audio").
- [ ] Decode ALAC frames to PCM in-project (SPEC §4, "ALAC decode"), proven by
       a known-answer unit test.
- [ ] Play the decoded PCM through `AVAudioSession` on the phone's **own**
       speaker, with no Bluetooth route selected (SPEC §4, increment 3; SPEC
       §3 step 3).
- [ ] Keep playback following the stream's own timeline for one continuous
       10-minute listen — `S3`; pause, resume and track changes during that
       listen do not stop the receiver (SPEC §3 step 4).
- [ ] Log buffer underruns, decode failures and output-route changes so the
       human's 10-minute observation has evidence (SPEC §4, "A log view
       exportable to a file").

## Out of scope

- RTSP setup, FairPlay v3 and key decryption — `FEAT-005`.
- Routing to the paired Bluetooth speaker and keeping the receiver alive with
  the screen off or the app backgrounded — increment 4 (`DEC-002`, `S4`).
- Home app volume/playback control — non-goal (SPEC §5).
- Multi-room grouping with the Apple TV's own output — non-goal, Bluetooth
  timing makes it impossible (`DEC-002`, SPEC §5).
- Screen mirroring, video, HLS, AirPlay 1 senders and multiple concurrent
  senders — non-goals (SPEC §5).
- The advertised-name settings screen — `FEAT-004` (not broken down in this
  job).
- Adding a framework, SDK, package or tool without a `DEC-###` and human
  approval (`docs/STACK.md`, SPEC §7).

## Acceptance criteria (feature level)

- [ ] **S3 (human).** Given the phone is paired and the app is foregrounded on
      the iPhone 6s with a stream key from `FEAT-005`, when the human selects
      the phone on the Apple TV and plays audio for 10 continuous minutes,
      then sound comes from the phone's own speaker without dropping, and the
      exported log records that session with zero underruns. Only the human on
      the iPhone 6s can observe the sound; no agent may claim PASS from a
      simulator run.
- [ ] **Decode (automated).** Given an ALAC fixture and its expected PCM, when
      the decoder runs on `platform=iOS Simulator,name=iPhone 14,OS=16.2`, then
      the output bytes equal the expected PCM, with 0 failures, and a corrupted
      frame produces a logged failure rather than partial audio.
- [ ] **Buffer (automated).** Given a fixture that introduces a delay within
      the buffer depth agreed at G3, when the consumer reads it, then no
      underrun is recorded; a gap beyond that depth produces a logged underrun.
- [ ] **Regression (automated).** `R2` is ≥ the high-water mark set by
      `FEAT-005`, and the `FEAT-005` RTSP/FairPlay checks still pass.
- [ ] **No new dependencies.** `grep -c 'packages:' play-two/project.yml` →
      `0` unless a `DEC-###` explicitly allows an audio-decode dependency.
- [ ] Every task in this feature is `done` with a `qa` verdict of `PASS`.

## Tasks

Not broken down until FEAT-005 closes (`DEC-002`: one feature broken down at a
time). No task IDs are reserved or created for this feature in this job.

| ID | Title | Status |
| --- | --- | --- |
| — | Not yet broken down | — |

## Notes

**Open question — ALAC decode route (`QQ-011`, DEC needed).** `docs/STACK.md`
lists Network.framework, CryptoKit, AVAudioSession and XCTest, but names no
audio-decode framework. The two candidates are an in-project ALAC decoder port
(reference implementations are named in `SPIKE-001`) and Apple's AudioToolbox
ALAC converter (not in the stack). The BA must record a `DEC-###`, with human
approval if the stack has to change, before this feature is broken down. PM is
not choosing either here.

**Open question — playback timeline.** The spec says "in sync with itself"
(SPEC §4) and tolerates ~100-300 ms of Bluetooth latency as out of scope
(SPEC §7); it gives no jitter or buffer-depth number. The buffer depth and the
underrun threshold are decided at G3 for this feature and pinned by a test, not
assumed in this file.

**`S3` is a 10-minute human observation.** Nothing on this host, and nothing on
the simulator, can claim it. The log is supporting evidence only. As with
`S2a`/`S2b` in FEAT-003, a code/task PASS does not close `S3` until the human
reports the observation.

**Kill-switch.** Increment 3 fails if ten minutes of drop-free audio cannot be
demonstrated; increment 4 is not written on a failed increment 3 (`DEC-002`).
