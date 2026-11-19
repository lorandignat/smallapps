---
name: BA Project Routing
description: Decide which project a request belongs to, keep the registry and per-project state straight, and choose what to work on when several projects compete. Use at session start and whenever the human mentions a project, idea or priority.
---

# Projects

The workspace holds several apps. Routing is your job, and getting it wrong is
expensive because artifacts land in the wrong directory.

## Where things live

| Thing | Path |
| --- | --- |
| Registry | `docs/PROJECTS.md` |
| Workspace state | `docs/STATE.md` |
| Project artifacts | `<project>/product|docs|backlog|qa|journal` |
| Project rules | `<project>/AGENTS.md` |
| Shared process, conventions | `docs/` |
| Template for new projects | `templates/project/` |

## Routing a request

1. If it names a project (slug, or an obvious match), that is the project.
2. If it fits exactly one existing project's spec, use it and say so.
3. If it clearly belongs to a project that has not been specified yet, create it
   (skill `ba-new-project`).
4. If two projects could claim it, ask once with your recommendation, then record
   the answer in `docs/DECISIONS.md`.
5. If it is not a product request at all (process change, tooling, docs), it is a
   workspace change: handle it in `docs/` and say that no project is involved.

Never let a request move silently from one project to another mid-task. If the
human changes their mind, close the current task cleanly (`blocked` with the
reason), update state, then switch.

## Choosing what to work on

The human decides priorities. When they have not, pick in this order and say
which you picked in one line:

1. A project with an unanswered question that blocks its release.
2. A project nearest to its release gate.
3. The project worked most recently, to preserve momentum.

Never interleave tasks from two projects in one run, even when they are "one
small fix" each.

## Reporting across projects

A cross-project answer is one line per project, not a merged narrative:

```text
airplay-receiver  build    14/22 tasks   next TASK-015
audiobooks        intake   spec draft    waiting on QQ-002
```

## Housekeeping

- Project directory names are stable. Renaming one is a workspace decision and
  needs a `DEC-###`, a git `mv`, and a registry update in the same change.
- Archived projects stay in the registry with their final state and a reason.
- Before starting work in a project after a gap, check `docs/STATE.md` there —
  another session may have moved it.
