# apps — an agent team that ships apps

A self-contained OpenCode project where four agents build an app: a business
analyst you talk to, a project manager who plans, a developer who builds, and a
tester who decides what is actually done.

Read `docs/PROCESS.md` for the loop and `AGENTS.md` for the hard rules.

## Use it

```sh
cd /homedir/agent/opencode/apps
opencode
```

You talk to `ba` only. Useful commands: `/idea`, `/status`, `/resume`,
`/next-task`.

## What is here

| Path | What |
| --- | --- |
| `docs/PROCESS.md` | The process: roles, gates, loop, autonomy rules |
| `docs/PROJECT-STATE.md` | Where we are right now — the resume point |
| `docs/PLATFORM.md` | iOS toolchain options and the Mac problem |
| `docs/DECISIONS.md` | Why things are the way they are |
| the local environment log | Every install and change on this host |
| `docs/QUESTIONS.md` | Things waiting on the human |
| `product/` | Idea notes and the approved spec |
| `backlog/` | Features, atomic tasks, board |
| `qa/` | Test plan, regression list, per-task verdicts |
| `journal/` | One running log per agent |
| `.opencode/` | Agents, commands, skills |

## Git

Local only. One commit per passing task. No remote, and `git push` is denied by
policy until you add a remote and choose to publish.

```sh
git log --oneline
git remote add origin <your repo>   # when you want to publish
git push -u origin main             # you, not an agent, unless you change policy
```

## Status

Phase 0 — waiting for the first idea. See `docs/PROJECT-STATE.md`.
