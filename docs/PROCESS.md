# PROCESS — how apps get built here

Version 2. Owner: `ba`. Applies to every project in this workspace. Only the
human changes the priorities in it; the BA enforces it.

## 0. Workspace and projects

- The workspace is `/homedir/agent/opencode/apps`. Shared materials: `docs/`,
  `templates/`, `scripts/`, `.opencode/`, `.tooling/`.
- A **project** is a first-level directory with its own `product/`, `docs/`,
  `backlog/`, `qa/`, `journal/` and source. Registry: `docs/PROJECTS.md`.
- One project per unit of work. No task, commit or decision spans two projects.
- Shared agents, skills and process are deliberately not duplicated per project.
  Project-specific guidance goes in `<project>/AGENTS.md`.

## 1. Roles

| Agent | ID | Mode | Talks to | Owns |
| --- | --- | --- | --- | --- |
| Business analyst | `ba` | primary (default) | the human; dispatches the rest | spec, scope, gates, registry, workspace state |
| Project manager | `pm` | subagent | `ba` | `<project>/backlog/` |
| Developer | `developer` | subagent | `ba` | `<project>/` source, tests, toolchain |
| Tester | `qa` | subagent | `ba` | `<project>/qa/` |

The BA is the only dispatcher. PM never launches Developer or Tester; that keeps
one auditable chain of custody and one accountable owner per moment.

## 2. Project lifecycle

```
idea → intake → G1 spec → G2 features → G3 tasks → build loop → release → maintenance
```

A project sits in exactly one phase, recorded in `docs/PROJECTS.md` and in its
own `docs/STATE.md`:

| Phase | Meaning |
| --- | --- |
| `idea` | directory exists, nothing approved |
| `intake` | BA interviewing, writing the spec |
| `breakdown` | PM slicing features and tasks |
| `build` | task loop running |
| `release` | v1 criteria met, awaiting human acceptance |
| `maintenance` | shipped; changes arrive as new features |
| `paused` / `archived` | deliberately stopped; reason recorded |

### Creating a project

```sh
./scripts/new-project.sh <slug>     # lowercase, dashes or underscores
```

Then: add the row to `docs/PROJECTS.md`, fill `<project>/README.md`, and start
intake. A project with no approved spec is not real work — do not staff it.

### Spikes

Some questions can only be answered by investigation: a protocol, a licensed
capability, a platform limit. Those are spikes, not features, and they happen
before G1.

- One spike = one question, one file: `<project>/docs/SPIKE-###-<topic>.md`, from
  `templates/spike.md`.
- Timeboxed to two working sessions. It ends with a `DEC-###`, not with code.
- No product code, no backlog tasks, no installation beyond what the spike needs.
- A spike may conclude "cannot be answered on this host" — that is a valid,
  useful result when it names what is missing.
- Do not let a spike grow into the product. When it is answered, the decision
  goes to the user and the work either becomes a spec or stops.

### Priorities across projects

The human decides. When nothing is specified, the BA works the project with the
oldest unanswered question or the nearest release, in that order, and says which
it picked. Never interleave tasks from two projects in one run.

## 3. Artifacts

Per project, all paths relative to `<project>/`:

| File | Written by | Read by |
| --- | --- | --- |
| `README.md` | ba, developer fills run instructions | everyone |
| `AGENTS.md` | ba | everyone working in that project |
| `product/IDEA.md` | ba | all |
| `product/SPEC.md` | ba | all |
| `backlog/BOARD.md` | pm | all |
| `backlog/features/FEAT-###.md` | pm | all |
| `backlog/tasks/TASK-###.md` | pm (ba changes `status` only) | all |
| `qa/TEST-PLAN.md`, `qa/REGRESSION.md` | qa | all |
| `qa/reports/TASK-###-review.md` | qa | all |
| `docs/STATE.md` | ba | all |
| `docs/DESIGN.md` | ba | all |
| `docs/STACK.md` | ba | all |
| `docs/DECISIONS.md`, `docs/QUESTIONS.md` | ba | all |
| `journal/<role>.md` | that role | all |
| `src|app|lib|test/**`, manifests, lockfiles | developer | all |

Workspace files: `docs/PROJECTS.md`, `docs/STATE.md` (ba), the local environment log
(developer), everything else in `docs/` by human approval.

## 4. Identifiers and states

IDs are per project, zero-padded, never reused: `FEAT-001`, `TASK-001`,
`DEC-001`, `QQ-001`. Reference them with the project prefix when writing at
workspace level: `airplay2/TASK-014`.

```
proposed → approved → in-progress → in-review → done
              ↑                        │
              └──────── rework ────────┘
blocked / dropped are terminal-ish and always carry a reason.
```

`done` requires: `qa` verdict `PASS`, BA gate G4, commit made, board updated.
Not "it compiles", not "the developer says so".

## 5. The loop

### Phase 0 — Intake (human ⇄ ba)

1. Human describes the idea. BA records it in `<project>/product/IDEA.md`.
2. BA interviews one question at a time: problem, primary user, core flow,
   non-goals, success criteria, constraints, stack.
3. BA writes `<project>/product/SPEC.md` and asks for approval.
4. **G1:** human approves. Recorded in the project's `docs/STATE.md` and, if
   anything was contested, `docs/DECISIONS.md`.

### Phase 1 — Breakdown (ba → pm)

5. BA sends PM the approved spec, the stack decision, and the definition of v1.
6. PM writes vertical features, then splits **only the first feature** into
   atomic tasks.
7. **G2:** features are demoable, dependency-ordered, traceable to spec.
8. **G3:** every task passes the atomicity checklist (`pm-atomic`).

### Phase 2 — Build loop (ba → developer ⇄ qa)

For each task, in dependency order, exactly this:

9. Task → `in-progress`, board updated, `attempts` incremented; launch
   **developer** with the task ID only.
10. Developer implements that one task, runs the checks, appends to
    `<project>/journal/` (private), returns the report.
11. Task → `in-review`; launch **qa** with the task ID and the report verbatim.
12. Tester verifies each criterion with evidence, runs the regression list,
    writes `qa/reports/TASK-###-review.md`, returns `PASS`, `FAIL` or `BLOCKED`.
13. **G4:** BA reads the report and the diff.
    - `PASS` → commit, task `done`, board and state updated, next task.
    - `FAIL` → task `rework`; relaunch developer with the findings verbatim, same
      task ID.
    - `BLOCKED` → provide the missing thing, ask PM to re-cut the task, or log a
      question and move to the next independent task.
14. Two attempts per task. On the third `FAIL`, stop: PM splits the task or
    rewrites the criteria, `DEC-###` recorded.

### Phase 3 — Feature close and release

15. Feature done → tester verdict against `qa/TEST-PLAN.md`, PM breaks down the
    next feature.
16. All features done → release note in the project `docs/STATE.md`, definition
    of done checked, stop for human acceptance.

**Definition of done for a release:** spec success criteria true; core flow works
from a clean checkout by the documented commands; no `FAIL`/`BLOCKED` tasks; the
regression list passes; the human has accepted.

## 6. Gates

- **G1 spec:** problem, user, core flow, non-goals, success criteria, stack.
- **G2 features:** vertical slices, demoable, ordered, traceable.
- **G3 tasks:** atomicity checklist passes for every task; criteria testable.
- **G4 verdict:** report read in full, evidence per criterion, scope respected,
  regressions handled, commit only after `PASS`.

Checklists: skill `ba-gate`. A gate is never approved on a summary; open the file.

## 7. Git

- One repository for the workspace, branch `main`.
- Commit after every `PASS`, prefixed with the project:
  `airplay2/TASK-014: add save button`.
- Process commits are workspace-level: `workspace/chore: ...` or
  `<project>/chore: ...`.
- Developer may commit checkpoints: `airplay2/wip(TASK-014): ...`, and never
  rewords BA commits.
- No remote, no push, ever, by an agent.
- Never commit `.tooling/`, build output, or secrets.

## 8. Autonomy

When the human says "work overnight", the BA runs the build loop unattended:

1. **Scope:** only `approved` tasks in the named project (or in the
   highest-priority project if none is named). No new features.
2. **Order:** dependency order, one task at a time, verdict before the next.
3. **Commit:** after every `PASS`; never leave more than one task uncommitted.
4. **State:** update the project `docs/STATE.md` and `docs/STATE.md` after every
   task, so an interruption loses at most one task.
5. **Stop and write a question** instead of guessing:
   - a gate cannot be passed;
   - the same task has failed three times;
   - a requirement is ambiguous or contradicts the spec;
   - the decision costs money, needs an Apple account, a Mac, signing keys, or
     network credentials;
   - the approved backlog for the current feature is exhausted.
6. **Caps:** at most 12 task cycles per run, one project.
7. **Nothing destructive:** no history rewrites, no deleting project files, no
   touching another project.
8. **On waking:** the human reads `docs/STATE.md` and the project's
   `docs/STATE.md`; the BA's first message summarises both in five lines.

## 9. Session protocol

1. Read `docs/STATE.md` → which project is active and what is next.
2. Read that project's `docs/STATE.md` and `backlog/BOARD.md`.
3. Confirm with `git status` and `git log --oneline -5` that disk and history
   agree; if they do not, history wins, fix the state files, note it in the
   journal.
4. Do the one unit of work you were given. Nothing extra.
5. Append to your journal; update the files you own; report what changed.

If context is lost, nothing is lost: the disk is the truth.

## 10. Changing this process

Proposals go in `docs/DECISIONS.md` as `DEC-###` with `status: proposed`. The
human approves; then edit this file and bump the version at the top.
