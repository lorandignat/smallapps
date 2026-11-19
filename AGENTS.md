# /homedir/agent/opencode/apps — agent boot instructions

This project builds apps end to end with a team of agents. Read
`docs/PROCESS.md` before doing anything else: it defines the loop, the gates,
and who is allowed to do what.

## Hard rules for every agent

1. Stay inside `/homedir/agent/opencode/apps`. Never read, write, or execute
   anything outside it. No access to the host, other projects, or other users'
   data. No `sudo`.
2. Never `git push`. The remote is added when the human asks for it, and only
   the human triggers a push.
3. Never install anything outside this folder. Downloads and installs go under
   `.tooling/` (or the project's own package manager directory) as this user.
   Every install, download, and config change is logged in
   the local environment log.
4. Only the **business-analyst** (`ba`) talks to the human. `pm`, `developer`
   and `tester` only ever respond to the agent that launched them.
5. State lives on disk, not in context. Start every session by reading
   `docs/PROJECT-STATE.md`. End every unit of work by updating it.
6. One task at a time. A task is `done` only when `tester` has passed it and the
   `ba` has recorded the verdict.
7. Never edit files another role owns (see the ownership table in
   `docs/PROCESS.md`).

## Layout

| Path | Owner | Purpose |
| --- | --- | --- |
| `docs/PROCESS.md` | ba | The loop, gates, handoffs (read-only for everyone) |
| `docs/PROJECT-STATE.md` | ba | Resume point: where we are, next action |
| `docs/DECISIONS.md` | ba | Decisions with rationale |
| `docs/QUESTIONS.md` | ba | Open questions for the human |
| the local environment log | developer | Installs, downloads, host changes |
| `docs/PLATFORM.md` | ba | Target platforms and toolchain decisions |
| `product/SPEC.md` | ba | Approved product definition |
| `product/IDEA.md` | ba | Raw intake notes |
| `backlog/BOARD.md` | pm | Status of every feature and task |
| `backlog/features/*.md` | pm | Feature definitions |
| `backlog/tasks/*.md` | pm | Atomic tasks with acceptance criteria |
| `qa/TEST-PLAN.md` | tester | Test strategy per feature |
| `qa/REGRESSION.md` | tester | Checks that must keep passing |
| `qa/reports/*.md` | tester | Per-task verdicts with evidence |
| `journal/*.md` | per agent | What each role did and why |
| `src/`, `app/`, `test/` | developer | The actual project |

Agents carry their own skills under `.opencode/skills/` (`ba-*`, `pm-*`,
`dev-*`, `qa-*`). Only load skills matching your role.
