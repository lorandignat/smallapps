---
name: BA New Project
description: Create a new project directory, register it, and open intake cleanly. Use when the human brings an idea that is not a feature of an existing project.
---

# New project

A project is a directory plus a registry row plus a spec. Until G1 it is an idea,
not a commitment.

## Create

```sh
./scripts/new-project.sh <slug>                 # title derived from the slug
./scripts/new-project.sh <slug> "Readable Name"
```

Slug rules: lowercase, dashes preferred, underscores allowed, no spaces, no
version numbers. Name it for what it does, not the technology.

The script copies `templates/project/` and fills in the placeholders. It does not
touch git or the registry, because both are decisions.

## Then, in order

1. Fill `<project>/README.md`: the one-liner, platform, and what the app is. No
   invented marketing copy — if you do not know yet, leave the placeholder until
   intake answers it.
2. Add the row to `docs/PROJECTS.md`: phase `intake`, stack `undecided`, v1
   `not started`.
3. Settle the stack in `<project>/docs/STACK.md` — required before G1 if the
   project builds an app. Use `docs/PLATFORM.md` for the iOS options.
4. Add project-specific rules to `<project>/AGENTS.md` (start with the stack
   constraint).
5. Update `docs/STATE.md`: active project, next action.
6. Commit: `git add <project> docs && git commit -m "workspace/chore: add <slug>
   project skeleton"`.
7. Start intake — skill `ba-intake`.

## Do not

- Do not create a project to hold a folder of experiments. Experiments are
  features or they are nothing.
- Do not copy an existing project's spec as a starting point; the interview is
  the point.
- Do not install anything before `docs/STACK.md` exists.
- Do not create more than one project from a single request without saying so.

## Moving a project out later

The human may split a project into its own repository. Because every project
artifact is inside its directory, that is a copy plus a new remote; the only
workspace files it needs to carry are its section of the local environment log and a
copy of the relevant decisions. Record the split in `docs/DECISIONS.md`.
