# OPEN QUESTIONS — AirPlay 2 Receiver

The BA writes here instead of guessing; nothing in an unattended run waits on
this file. If a question blocks a task, mark that task `blocked`, pick the next
independent task, and continue.

| ID | Date | Question | Blocks | Default if unanswered |
| --- | --- | --- | --- | --- |
| QQ-001 | 2026-11-15 | Receiving vs controlling. **Answered:** receiving — iPhone 6s as AirPlay receiver, forwarding to a Bluetooth speaker. | — | — |
| QQ-002 | 2026-11-15 | AirPlay 1 or 2 for v1. **Answered and closed:** spike run, see `docs/SPIKE-001-airplay2.md`. AP2 is software-feasible, iOS-feasible only in theory. | — | — |
| QQ-004 | 2026-11-15 | Disposition. **Answered:** A — attempt the iOS AP2 receiver, accepting the DRM exposure and sideload-only distribution (`DEC-001`). | — | — |
| QQ-005 | 2026-11-15 | Mac access. **Answered:** the human has a Mac; builds run over SSH via the build bridge (`DEC-007`). Still needs `MAC_HOST`/`MAC_USER` in local configuration, the agent key installed on the Mac, and Xcode opened once. | Every increment | None — `xcodebuild -version` must pass |
| QQ-003 | 2026-11-15 | Personal use on your own device, or something to distribute? **Assumed personal use** for now (that is what `DEC-001` accepted: no App Store, no distribution, DRM exposure only on your own hardware). Confirm before anything is shared. | Distribution and signing only | Personal use / sideload |
