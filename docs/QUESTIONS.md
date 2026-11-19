# OPEN QUESTIONS — workspace level

Decisions that need the human and are not owned by a single project. Project
questions live in `<project>/docs/QUESTIONS.md`. The BA writes here instead of
guessing.

| ID | Date | Question | Blocks | Default if unanswered |
| --- | --- | --- | --- | --- |
| QQ-001 | 2026-11-15 | Which stack for the first iOS project. **Answered:** option D — Swift, built on the human's Mac over SSH (`DEC-007`, the private build notes). Flutter/React Native stay available for later projects. | — | — |
| QQ-002 | 2026-11-15 | Is the Mac reachable from this container, and does it have Xcode plus an Apple ID signed in? `xcodebuild -version` is the test; it needs `MAC_HOST`/`MAC_USER` in local configuration. | Every build, test and device install | None — without it increments 1-4 cannot be verified |
