# Agent boot instructions — workspace

This repository is a workspace holding several apps. Read
`docs/PROCESS.md` before doing anything else; it defines the phases, the gates
and who may do what. `docs/CONVENTIONS.md` covers naming and commits.

## The one rule that matters

**Work happens inside one project at a time.** A project is a first-level
directory: `airplay-receiver/`, `audiobooks/`. Shared material lives in
`docs/`, `templates/`, `scripts/`, `.opencode/`. Never write project artifacts
at the workspace root, and never mix two projects in one task.

## Hard rules

1. Stay inside `/homedir/agent/opencode/apps`. No host access, no other users'
   data, no `sudo`.
2. Never `git push`, never add a remote. Publishing is the human's decision.
3. Install nothing outside this folder. Shared toolchains go in `.tooling/`,
   project dependencies in the project. Record every install in the
   local environment log, which is not published.
4. The business analyst (`ba`) is the human's interface and the dispatcher.
   `pm`, `developer` and `qa` run in the background and answer only the analyst;
   they cannot reach the human. The analyst answers from the spec, the decisions
   and the backlog, and forwards a question to the human only when those do not
   settle it.
5. State lives on disk. Workspace state: `docs/STATE.md`. Project state:
   `<project>/docs/STATE.md`. Read both before acting; update before stopping.
6. One task at a time. A task is `done` only when `qa` returns `PASS` and the
   `ba` records the verdict.
7. Record every project in `docs/PROJECTS.md` when it is created, and keep its
   row true.

## Ownership

| Path | Owner |
| --- | --- |
| `docs/PROCESS.md`, `docs/CONVENTIONS.md` | workspace; changed by human approval |
| `docs/PROJECTS.md`, `docs/STATE.md`, `docs/DECISIONS.md`, `docs/QUESTIONS.md` | ba |
| `docs/PLATFORM.md` | ba |
| `templates/`, `scripts/` | ba |
| `<project>/product/**` | ba |
| `<project>/backlog/**` | pm (ba may change task status only) |
| `<project>/docs/**` | ba |
| `<project>/qa/**` | qa |
| `<project>/src|app|lib|test/**`, manifests, lockfiles | developer |

Write access is enforced by permission rules. If you cannot write a file, that is
the process working: record the need in your journal and hand it to the owner.

## Adding a project

`./scripts/new-project.sh <slug>` creates the skeleton and registers nothing —
the BA adds the row to `docs/PROJECTS.md` and opens intake. A project is not a
project until it has a spec under gate G1.
