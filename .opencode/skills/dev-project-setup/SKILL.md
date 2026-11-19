---
name: Project Setup
description: How to bootstrap or extend the app project - layout, manifests, lockfiles, test runner, and stack rules pinned to docs/PLATFORM.md. Use when the repo has no app yet or a task needs new project scaffolding.
---

# Project setup

You are allowed to create the project. You are not allowed to pick a stack the
human has not approved.

## First, read

- `docs/PLATFORM.md` — the decided stack and what cannot be verified on Linux.
- `product/SPEC.md` §7 — constraints (offline, accessibility, data sensitivity).
- The task that asks for scaffolding. If no task asks, do not scaffold.

## Layout rules

Keep the app at the repository root so the process files stay visible:

```
src/            application code (or lib/ per the stack)
test/           tests next to the code they cover if the stack prefers it
docs/ backlog/ product/ qa/ journal/   process artifacts, never app code
.tooling/       user-local SDKs and CLIs (gitignored)
```

- One obvious entry point, one obvious test command, one obvious build command.
- No `src/` inside `src/`. No wrapper folders whose only purpose is tidiness.
- Everything the app needs must work from a clean checkout following the README.

## Required artifacts of the first scaffold task

- [ ] Manifest with pinned/deterministic versions (`package.json` + lockfile, or
      the stack's equivalent). Commit the lockfile.
- [ ] Test runner wired and **one passing test**, so the tester has a real
      command from day one.
- [ ] Lint/format command if the ecosystem has an obvious default.
- [ ] `README.md` section in the repo root with: install, run, test, build, and
      any platform caveat (e.g. "iOS build needs macOS — see docs/PLATFORM.md").
- [ ] `.gitignore` entries for build output, caches, and `.tooling/`.
- [ ] Everything installed and logged per skill `dev-tools`.

## Discipline

- **No framework tourism.** One HTTP client, one state solution, one test
  library. Add a dependency when a task needs it, not because it is standard in
  blog posts.
- **No speculative structure.** Create `features/auth/` when auth exists, not
  before. Empty scaffolding is noise the tester will flag as scope.
- **No CI, no Docker, no deployment config** unless a task asks. The host is this
  folder, and the human publishes later.
- **Platform caveat is a deliverable.** If a criterion says "works on iOS", write
  plainly which part cannot be run here, so the tester can return `BLOCKED`
  rather than guess.
