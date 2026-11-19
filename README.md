# apps

This repository holds the apps we build. Each one lives in its own directory with
its own requirements, decisions, design notes, backlog, tests and source. They
share a written process, a small set of AI agents that execute it, and one
toolchain. Nothing is assumed to be throwaway: a project here is expected to be
readable by someone who joins six months from now.

It is a working monorepo, not a scaffold. Projects may be split into their own
repositories later; the layout is chosen so that moving one out is a directory
move plus a fresh remote, not a rewrite.

This published copy carries the repository as it grew on its own machine.
Where a document names the build host, the phone or the signing account, the
value has been replaced with a placeholder such as `<build-host>`, `<udid>` or
`<apple-id>`; the journals, the install log and the per-task QA transcripts
stay private.

## How work happens

Every project moves through the same four gates, and nothing passes a gate on a
summary alone:

1. **Specification.** The problem, one primary user, the core flow, what is
   deliberately out of scope, and success criteria that can be tested.
2. **Feature map.** The spec becomes vertical slices — each one demonstrable on
   its own, ordered by dependency.
3. **Task breakdown.** The current slice becomes small tasks: one behaviour, one
   commit, acceptance criteria a tester can verify with a command.
4. **Build.** One task at a time: implement, verify independently, commit only on
   a passing verdict. Failed verification sends the same task back with the
   findings attached.

The process is written down in [`docs/PROCESS.md`](docs/PROCESS.md) and is
enforced by the roles below, not by good intentions.

## The agents

Four AI agents do the work. A person talks to one of them, the business analyst,
which drives the process and dispatches the rest. The others run as subagents in
the background and answer the analyst only. When one of them needs a decision it
asks the analyst, which answers from the product definition and the decisions on
record, and takes the question to the person when those do not settle it.

| Agent | Mode | Responsibility |
| --- | --- | --- |
| Business analyst | primary | Product definition, scope, priorities and the four gates. Owns the spec and the state. |
| Project manager | subagent | Turns the approved spec into features and atomic tasks; owns the backlog. |
| Developer | subagent | Builds one task per invocation, sets up and maintains the codebase, answers rework. |
| Tester | subagent | Verifies acceptance criteria with evidence, owns the regression list. |

The human owns the product and every irreversible decision. The agents absorb the
routine work so attention goes to what the app should be. Model settings live in
`opencode.jsonc`; the rules they follow are in [`docs/PROCESS.md`](docs/PROCESS.md).

## How a task moves

```
human  ⇄  ba                 idea, priority, gate approvals
           │
           ├──▶ pm           approved spec → features → atomic tasks
           ├──▶ developer    one task ID → code, tests, report
           └──▶ qa           task ID + report → verdict and evidence
                     │
                     ▼
                   ba            PASS  → commit, close the task, take the next
                                 FAIL  → same task back to the developer
                                 BLOCKED → fix the cause, re-cut, or record it
```

One task at a time, in dependency order. A task is closed only on a passing
verdict, and the commit is made by the analyst, never by the agent that wrote the
code.

Each subagent starts with fresh context and returns a summary — what changed,
which checks ran, what needs a decision. Implementation detail stays in the files
and the journals, so the analyst carries the loop, not the code.

## State, not a transcript

This is a stripped-down workflow for ideas, prototypes and fast iteration, and
the shape follows from that. Requirements, decisions, the backlog and the progress
of every task are written to markdown as the work happens:

| Question | File |
| --- | --- |
| What are we building, and how do we know it works? | `<project>/product/SPEC.md` |
| Why is it built this way? | `<project>/docs/DECISIONS.md` |
| What is left, and what is in flight? | `<project>/backlog/BOARD.md` |
| Where did we stop? | `docs/STATE.md` and `<project>/docs/STATE.md` |
| What has actually been tried? | `<project>/journal/` (private) |

A session begins by reading those files instead of replaying a conversation. That
keeps the working context small and the cost low, and it is what makes a handoff
possible: a new chat, a different model or a person resumes at the same task,
under the same constraints, because the constraints are on disk.

## Repository layout

```
apps/
├── README.md               this file
├── AGENTS.md               rules every agent follows
├── opencode.jsonc          agents, permissions, model
├── docs/                   how the workspace is run
│   ├── PROCESS.md          the process and its gates
│   ├── PROJECTS.md         registry: every project and its state
│   ├── STATE.md            workspace resume point
│   ├── CONVENTIONS.md      naming, commits, structure
│   ├── DECISIONS.md        workspace-level decisions
│   ├── QUESTIONS.md        decisions waiting on the human
│   ├── PLATFORM.md         iOS on Linux, and the Mac problem
├── templates/project/      skeleton copied for a new project
├── scripts/                new-project
└── <project>/              one directory per app
```

Each project follows the same shape — `product/`, `docs/`, `backlog/`, `qa/`,
`journal/`, source and tests. The project README explains that project; the
process explains how it is built.

## Projects

See [`docs/PROJECTS.md`](docs/PROJECTS.md) for the registry and current state.
Projects are added with:

```sh
./scripts/new-project.sh airplay-receiver
```

## Running a project

```sh
cd apps/<project>
opencode            # talk to the business analyst
```

Inside a session: `/projects`, `/project <slug>`, `/status`, `/resume`,
`/next-task`, `/new-project <slug>`, `/idea <idea>`.

## Version control

One repository, branch `main`, one commit per passing task, prefixed with the
project name (`play-two/TASK-014: …`). Agents cannot push; publishing is a human
decision, made when a project is ready for it.

## Where to start

- New here? `docs/PROCESS.md`, then the README of the project you care about.
- Starting something new? `docs/CONVENTIONS.md`, then `scripts/new-project.sh`.
- Wondering what is blocked? `docs/QUESTIONS.md`.
- Journals, install logs and per-task QA transcripts are kept locally and are
  not published.
