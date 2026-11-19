---
description: Switch the active project
agent: ba
---

Project: `$ARGUMENTS`

1. Confirm the directory exists and read its `docs/STATE.md`,
   `backlog/BOARD.md`, `AGENTS.md`.
2. Set `docs/STATE.md` → `Active project: <slug>`, mode, next action.
3. Reply in three lines: project, phase, next action. Note anything uncommitted
   or `in-review` left behind in the previous project.

If the slug does not exist, say so and offer the closest match from
`docs/PROJECTS.md`. Do not create a project from this command.
