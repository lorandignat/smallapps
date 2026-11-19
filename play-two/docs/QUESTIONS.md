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
| QQ-009 | 2026-11-19 | **The Mac is unreachable** — ssh to `<build-host>:22` and `/dev/tcp` probes to it and to its Tailscale name `ro-w2kq9641jp.ts.net` have timed out since ~20:05 (developer: TASK-008, retries at 21:11, 21:13, 21:20). Is it off, the network down, or something else? | TASK-008, TASK-009 | Retry `xcodebuild -version`; when green, dev reruns the TASK-008 verification commands, QA verifies, BA commits `play-two/TASK-008: export the diagnostic log to a file` |
