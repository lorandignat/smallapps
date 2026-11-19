# {{TITLE}}

{{one_liner}}

| | |
| --- | --- |
| **Status** | idea — not specified yet |
| **Phase** | intake |
| **Platform** | iOS (see `docs/STACK.md`) |
| **v1** | not defined |

## What it is

Two or three sentences: the problem, who has it, and what this app does about it.
Written for someone who has never heard of the product. Replace this placeholder
after intake; until then it is honest about being empty.

## Current state

Nothing built. The spec is being written in `product/SPEC.md`. The authoritative
status is `docs/STATE.md`; the backlog is `backlog/BOARD.md`.

## Stack

Recorded in `docs/STACK.md` once the intake decision is made. Nothing is
installed before that.

## Running it

Filled in by the developer with the first scaffold task:

```sh
# install
# run
# test
```

## Layout

```
product/    requirements: idea notes, approved spec
docs/       state, design, stack, decisions, questions
backlog/    board, features, atomic tasks
qa/         test plan, regression list, per-task verdicts
journal/    one log per role
```

Source directories are added by the first scaffold task, following the chosen
stack's conventions.

## Decisions and questions

- Decisions with consequences: `docs/DECISIONS.md`
- Anything waiting on the human: `docs/QUESTIONS.md`
- Architecture and data model, once they exist: `docs/DESIGN.md`

## Notes

This project is built inside a shared workspace; the process, agents and
conventions are described in the workspace `README.md` and `docs/PROCESS.md`.
Project-specific rules for the agents belong in `AGENTS.md` next to this file.
