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

## The team

| Role | Responsibility |
| --- | --- |
| Business analyst | Product definition, scope, priorities, and the four gates. The only role a person talks to. |
| Project manager | Turns the approved spec into features and atomic tasks; owns the backlog. |
| Developer | Builds one task per pass, sets up and maintains the codebase, fixes failed work. |
| Tester | Verifies against acceptance criteria with evidence, owns the regression list. |

These are AI agents operating under [`.opencode/`](.opencode) with a fixed
process; the human owns the product and every irreversible decision. Model
details live in `opencode.jsonc`. The intent is not autonomy for its own sake:
the agents do the routine work so the human spends attention on what the app
should be.

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
project name (`airplay2/TASK-014: …`). No remote is configured and agents cannot
push; publishing is a human decision, made when a project is ready for it.

## Where to start

- New here? `docs/PROCESS.md`, then the README of the project you care about.
- Starting something new? `docs/CONVENTIONS.md`, then `scripts/new-project.sh`.
- Wondering what is blocked? `docs/QUESTIONS.md`.
- Journals, install logs and per-task QA transcripts are kept locally and are
  not published.
