---
name: PM Board
description: Keep backlog/BOARD.md and file frontmatter consistent so the BA and the human can read project status at a glance. Use on every backlog change.
---

# Board

`backlog/BOARD.md` is the only place that answers "what is left?". It must never
disagree with the files.

## Rules

- One row per feature and one per task, always in ID order.
- Status in the board must equal `status:` in the file's frontmatter. If they
  differ, the file wins and you fix the board in the same turn.
- Kebab-free, short titles: "Save draft on tap", not "Implement the draft saving
  functionality".
- Counts at the bottom: features done/total, tasks done/total, blocked.
- Update `**Updated:**`, `**Active feature:**`, `**Active task:**` every time.
- You may create tasks and features; you may **not** move a task to `done`. Only
  the BA does that after a tester `PASS`. If you find a file already `done`, leave
  it.

## Status vocabulary

`proposed → approved → in-progress → in-review → done`, plus `rework`,
`blocked`, `dropped`. `blocked` rows always carry a reason in the task file.

## Hygiene

- A title that changed after the developer started implies scope drift: do not
  rename an in-progress task; create a follow-up instead.
- Retire tasks only with `status: dropped` and a line in the task file saying why
  and which `DEC-###`.
- Do not delete files. History matters more than tidiness.
- When a feature closes, mark it `done` only if every one of its tasks is `done`
  or `dropped` with a reason.

## Adding to the board

Append rows in ID order, under the right table, and keep the legend intact. The
BA reads this file every cycle; a stale board wastes a cycle.
