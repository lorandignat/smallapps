# CONVENTIONS

Short, boring and enforced. Deviating needs a `DEC-###`, not a preference.

## Projects

- Slug: lowercase, dashes preferred (`airplay-receiver`), underscores tolerated
  (`airplay_2_app`). No spaces, no capitals, no version numbers in the name.
- One directory per project at the top level. Everything a project needs lives
  inside it; nothing project-specific lives outside it.
- A project is named for what it does, not for the technology.

## Files inside a project

```
<project>/
├── README.md           what it is, how to run it, current state
├── AGENTS.md           project-specific rules for the agents
├── product/            IDEA.md, SPEC.md
├── docs/               STATE.md, DESIGN.md, STACK.md, DECISIONS.md, QUESTIONS.md
├── backlog/            BOARD.md, features/, tasks/
├── qa/                 TEST-PLAN.md, REGRESSION.md, reports/
├── journal/            ba.md, pm.md, dev.md, qa.md
└── src|app|lib, test|tests, manifests, lockfiles
```

Lowercase filenames. Multi-word files use dashes: `TASK-014-review.md`. IDs are
zero-padded three digits and never reused.

## Commits

```
<project>/TASK-014: add save button that persists draft
<project>/chore: close FEAT-002
workspace/chore: update process for multi-project layout
```

One task, one commit on `main`. Body carries context that the diff cannot:
`Feature: FEAT-002 · Verdict: PASS · Attempt: 2`. No merge commits, no history
rewrites, no pushes.

## Markdown

- Sentence case headings, one `#` per file.
- Tables only for things with columns worth comparing; prose for reasoning.
- Keep `STATE.md` under 40 lines; history goes in journals.
- Reports are summaries; evidence lives in files and is cited by path. A report
  quotes the lines that prove a claim, never a whole log.
- Link relatively (`../docs/PROCESS.md`), never absolute paths.
- No emoji in repository documents. No badges that are not true.

## Code

- Follow the stack's own conventions and the existing file you are editing.
- Tests live with the code; a behaviour without a test is not implemented.
- Dependencies: one obvious choice each, pinned, lockfile committed. Adding a
  dependency requires saying why in the task or `DECISIONS.md`.
- No dead code, no commented-out blocks, no `TODO` without an owner and an ID.
- Configuration through environment or a single config module, never scattered
  literals.

## Documents that must stay true

`docs/PROJECTS.md`, `docs/STATE.md`, each project's `docs/STATE.md`,
`qa/REGRESSION.md`. If one of them drifts, fixing it is part of the task that
caused the drift.
