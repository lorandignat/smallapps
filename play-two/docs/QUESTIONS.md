# OPEN QUESTIONS — PlayTwo

The BA writes here instead of guessing; nothing in an unattended run waits on
this file. If a question blocks a task, mark that task `blocked`, pick the next
independent task, and continue.

| ID | Date | Question | Blocks | Default if unanswered |
| --- | --- | --- | --- | --- |
| QQ-001 | 2026-11-15 | Receiving vs controlling. **Answered:** receiving — iPhone 6s as AirPlay receiver, forwarding to a Bluetooth speaker. | — | — |
| QQ-002 | 2026-11-15 | AirPlay 1 or 2 for v1. **Answered and closed:** spike run, see `docs/SPIKE-001-airplay2.md`. AP2 is software-feasible, iOS-feasible only in theory. | — | — |
| QQ-004 | 2026-11-15 | Disposition. **Answered:** A — attempt the iOS AP2 receiver, accepting the DRM exposure and sideload-only distribution (`DEC-001`). | — | — |
| QQ-005 | 2026-11-15 | Mac access. **Answered:** the human has a Mac; builds run over SSH via the build bridge (`DEC-007`). Still needs `MAC_HOST`/`MAC_USER` in local configuration, the agent key installed on the Mac, and Xcode opened once. | Every increment | None — `xcodebuild -version` must pass |
| QQ-006 | 2026-11-15 | Who owns the advertised-name settings screen from SPEC §4? **Answered:** increment 2; increment 1 ships the default name (`DEC-003`). | — | — |
| QQ-007 | 2026-11-15 | Must the Apple TV entry vanish within 30 s of a kill, when the app cannot run after a kill? **Answered:** the app must withdraw on background/stop; after a kill, expiry is Bonjour's cache (`DEC-004`). | — | — |
| QQ-008 | 2026-11-15 | Which Apple ID / development team signs device builds, and is it the free (7-day) or paid (1-year) account? **Answered:** the free account `<apple-id>`, team `<team-id>`, 7-day profile expiring 2026-11-23 (`DEC-008`). | — | — |
| QQ-003 | 2026-11-15 | Personal use on your own device, or something to distribute? **Assumed personal use** for now (that is what `DEC-001` accepted: no App Store, no distribution, DRM exposure only on your own hardware). Confirm before anything is shared. | Distribution and signing only | Personal use / sideload |
| QQ-009 | 2026-11-19 | **CLOSED 2026-11-20 00:27** — the Mac was unreachable (ssh to `<build-host>:22` and the Tailscale name timed out since ~20:05). `xcodebuild -version` is green again (Xcode 27.2, iPhone 16e simulator booted). No answer needed; TASK-008 resumed. | TASK-008, TASK-009 | — |
| QQ-010 | 2026-11-22 | How do FairPlay v3 key tables enter the app (source/format, runtime injection boundary, git exclusion)? **Answered/accepted 2026-11-22: DEC-015**. Boundary: owner-supplied out-of-band opaque bytes injected as `Data` (no repo/bundle path, no committed DRM), synthetic fixtures only in tests, personal-use/sideload-only, no new dependency. Human approved proceeding; TASK-027/028 unblocked. Agents must not obtain/copy/commit/bundle/upload/log real key material. | — | — |
| QQ-011 | 2026-11-22 | Which ALAC decode route does FEAT-006 use (AudioToolbox/CoreAudio path on iOS 15, or another in-project route)? Needs a DEC before FEAT-006 G3; no dependency/SDK outside STACK.md without human approval. | FEAT-006 G3, TASKs TBD | — (DEC required) |
