---
description: Scaffold a new project and open intake
agent: ba
---

New project: `$ARGUMENTS`

Follow skill `ba-new-project`:

1. Validate the slug (lowercase, dashes or underscores). If it is missing or
   invalid, ask once for the name and what the app does.
2. Run `./scripts/new-project.sh <slug>`.
3. Fill the project `README.md` header and `docs/STACK.md` as far as the idea
   allows; leave anything unknown marked `undecided`.
4. Add the row to `docs/PROJECTS.md` (phase `intake`), update `docs/STATE.md`.
5. Commit `workspace/chore: add <slug> project skeleton`.
6. Start intake with skill `ba-intake`, one question at a time.

Do not install a toolchain from this command.
