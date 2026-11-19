# PROCESS — how this team builds an app

Version 1. Owner: `ba`. Everyone reads this; only the human may change the
priorities in it.

## 1. Roles

| Agent | OpenCode ID | Mode | Talks to | Authority |
| --- | --- | --- | --- | --- |
| Business Analyst | `ba` | primary (default) | the human, and dispatches the other three | Owns the product definition, the process, and every gate. Cannot write code. |
| Project Manager | `pm` | subagent | `ba` only | Owns `backlog/`. Turns a spec into features, features into atomic tasks with acceptance criteria. Cannot write code, cannot run commands. |
| Developer | `developer` | subagent | `ba` only | Owns the app source, its tests, and the toolchain. Works on exactly one task per invocation. |
| Tester | `qa` | subagent | `ba` only | Owns `qa/`. Verifies work against acceptance criteria. Cannot edit source. |

**The BA is the only dispatcher.** PM never launches Developer or Tester; BA
does, one call at a time. That keeps a single, auditable chain of custody, keeps
the nesting shallow enough to be reliable on a small model, and gives the BA
line-of-sight on every handoff, which is what "oversee and approve" requires.

## 2. Artifacts and ownership

| File | Written by | Read by |
| --- | --- | --- |
| `product/IDEA.md` | ba | all |
| `product/SPEC.md` | ba | all |
| `backlog/BOARD.md` | pm | all |
| `backlog/features/FEAT-###.md` | pm | all |
| `backlog/tasks/TASK-###.md` | pm (ba may only change `status`) | all |
| `qa/reports/TASK-###-review.md` | qa | all |
| `qa/TEST-PLAN.md`, `qa/REGRESSION.md` | qa | all |
| `journal/<role>.md`, `journal/<role>.md`, `journal/<role>.md`, `journal/<role>.md` | that role | all |
| `docs/PROJECT-STATE.md`, `docs/DECISIONS.md`, `docs/QUESTIONS.md` | ba | all |
| the local environment log | developer | all |
| `src/**`, `app/**`, `test/**`, `*.lock`, manifests | developer | all |

Write access is enforced with permission rules. If you cannot write a file,
that is the process working — record the need in your journal and hand it to
the owner.

## 3. Identifiers and states

IDs are zero-padded and never reused: `FEAT-001`, `TASK-001`, `DEC-001`,
`QQ-001` (open question).

Task states, in order:

```
proposed → approved → in-progress → in-review → done
                ↑                      │
                └────── rework ────────┘
blocked / dropped are terminal-ish and always carry a reason.
```

`done` requires: tester verdict `PASS`, BA gate G4 recorded, commit made, board
updated. Nothing else counts as done — not "it compiles", not "developer says
so".

## 4. The loop

### Phase 0 — Intake (human ⇄ ba)

1. Human describes the idea. BA takes notes in `product/IDEA.md`.
2. BA interviews: one question at a time, never a wall of questions. Cover
   problem, primary user, the single core flow, what is explicitly out of scope
   for v1, and how we will know v1 is finished.
3. BA writes `product/SPEC.md` from the template and asks for approval.
4. **Gate G1 (spec):** human approves the spec. Recorded in
   `docs/PROJECT-STATE.md` and `docs/DECISIONS.md`.

No feature, task, or code exists before G1.

### Phase 1 — Breakdown (ba → pm)

5. BA sends PM one brief: the approved spec, the platform, and the definition
   of v1. (Brief template: skill `ba-handoff`.)
6. PM writes features as *vertical slices* (each one shippable and demoable),
   then splits the first feature only into atomic tasks. Later features stay at
   feature level until the current one is done — this prevents a 200-task
   backlog rotting while the product changes.
7. **Gate G2 (features):** BA checks each feature is independently demoable,
   ordered by dependency, and consistent with the spec.
8. **Gate G3 (tasks):** BA checks every task against the atomicity checklist
   (skill `pm-atomic`). Any task that fails goes back to PM once with a specific
   reason.

### Phase 2 — Build loop (ba → developer ⇄ qa)

For each task in dependency order, exactly this sequence:

9. BA sets the task file to `in-progress` and the board to `in-progress`, then
   launches **developer** with the task ID only (no paraphrasing of the task).
10. Developer does one task. It reads the task file, implements, runs the
    project's own checks, writes `journal/<role>.md`, and returns a short report:
    what changed, files touched, commands run, self-check results, anything the
    tester must know.
11. BA sets the task to `in-review`, then launches **tester** with the task ID
    and the developer's report.
12. Tester reads the task's acceptance criteria, verifies each one with real
    evidence, runs the regression list, writes
    `qa/reports/TASK-###-review.md`, and returns a verdict:
    - `PASS` — every criterion verified, no regressions.
    - `FAIL` — one or more criteria unmet or a regression; each finding has
      file/line and a reproduction.
    - `BLOCKED` — the criterion cannot be verified with the current environment.
13. **Gate G4 (verdict):** BA reads the report itself, not just the summary.
    - `PASS` → BA commits, sets task `done`, updates the board, appends to
      `docs/PROJECT-STATE.md`, moves to the next task.
    - `FAIL` → BA sets task `rework`, writes the tester's findings into the
      handoff, and relaunches **developer** with the same task ID plus the
      findings. Same task, new attempt. Developer does not start anything else.
    - `BLOCKED` → BA either provides the missing environment, asks PM to split
      the task, or escalates to the human via `docs/QUESTIONS.md`.
14. Failure budget per task: **2 rework rounds**. On the 3rd `FAIL`, BA stops
    this task, asks PM to split it into smaller tasks (or to rewrite the
    criteria if they are untestable), and records a `DEC-###`.

### Phase 3 — Feature close and release

15. When all tasks of a feature are `done`: BA asks **tester** for a feature
    verdict against `qa/TEST-PLAN.md`, and **pm** for the next feature's tasks.
16. When every feature for v1 is `done`, BA writes a release note in
    `docs/PROJECT-STATE.md`, checks the definition of done below, and stops for
    human acceptance. iOS packaging/device runs need a Mac or CI; see
    `docs/PLATFORM.md`.

**Definition of done for v1:** spec's success criteria are all true; the core
flow works from a clean checkout via the documented commands; no `FAIL` or
`BLOCKED` tasks remain; regression list passes; the human has accepted.

## 5. Gates (BA checklists)

- **G1 spec:** problem, user, core flow, non-goals, success criteria, platform.
- **G2 features:** vertical slices, demoable, dependency-ordered, traceable to
  spec lines.
- **G3 tasks:** atomicity checklist passes for every task; each has acceptance
  criteria that a tester could verify with a command or an observation.
- **G4 verdict:** tester report read in full; evidence present per criterion;
  regressions addressed; commit made only after `PASS`.

A gate is never approved on a summary alone. BA opens the file.

## 6. Git protocol

- One local repository at the project root. Branch `main`.
- Commit after every `PASS` (one task = one commit), message:
  `TASK-###: <task title>` — plus a body with the feature ID and the verdict.
- BA also commits process artifacts (spec, backlog, state, journals) either with
  the task commit or as `chore(process): ...` at phase boundaries.
- Developer may commit *within* a task only as a checkpoint (`wip(TASK-###):`),
  and must not squash BA's commits.
- **No remote, no push.** `git push` is denied by policy. The human adds a
  remote and pushes when they choose.
- Never commit `.tooling/`, build outputs, or secrets. See `.gitignore`.

## 7. Autonomy (unattended runs)

When the human says "work overnight", the BA runs Phase 2 autonomously under
these rules:

1. **Scope:** only tasks already `approved` in the backlog. Unattended runs do
   not add features. New ideas go to `docs/QUESTIONS.md`.
2. **Order:** dependency order, one task at a time, tester verdict before the
   next task starts.
3. **Commit:** after every PASS. Never leave more than one task uncommitted.
4. **State:** update `docs/PROJECT-STATE.md` after every task, so a crashed or
   interrupted run resumes cleanly.
5. **Stop conditions** — stop and write to `docs/QUESTIONS.md` instead of
   guessing:
   - a gate cannot be passed;
   - the same task fails 3 times;
   - a requirement is ambiguous or contradicts the spec;
   - a decision would cost money, require an Apple account, a Mac, a signing
     key, network credentials, or anything outside this folder;
   - the backlog for the current feature is exhausted.
6. **Caps:** at most 12 task cycles per unattended run unless the human raises
   it. Every cycle is bounded by the agents' step limits.
7. **No destructive actions:** no `git reset --hard` on someone else's commit,
   no deleting files outside `.tooling/` and build output, no rewriting history.
8. **On waking:** the human reads `docs/PROJECT-STATE.md` → "Status" and
   "Next action". The BA's first message summarizes it in five lines or fewer.

## 8. Session protocol (every agent, every time)

1. Read `docs/PROJECT-STATE.md` and `backlog/BOARD.md` before acting.
2. Read your own `journal/<role>.md` tail if you need recent history.
3. Do the one unit of work you were given. Do not pick up extra work.
4. Append to your journal: what you did, what you learned, what is next.
5. Update the file you own; tell the dispatcher exactly what changed.

If context is lost or a session dies: nothing is lost, the disk is the truth.

## 9. Changing this process

Proposals for a process change go in `docs/DECISIONS.md` as `DEC-###` with
`status: proposed`. The human approves; then edit this file and bump the
version at the top.
