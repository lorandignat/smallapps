# WORKSPACE STATE — resume point

> Workspace-level only. Each project has its own `docs/STATE.md`; this file says
> which one is active and what the workspace itself needs. Keep it under 40 lines.

**Updated:** 2026-11-15
**Active project:** none
**Mode:** idle — waiting for the first project
**Shared toolchain:** git only (see the local environment log)

## Status

Workspace restructured for multiple projects. Agents, skills and process are
shared and smoke-tested. No project exists yet, so no spec, backlog or code.

## Next action

1. Human names the first project (or runs `/new-project <slug>`).
2. Create it with `scripts/new-project.sh`, add the registry row, start intake.
3. Settle the stack per `docs/PLATFORM.md` at the project's `docs/STACK.md`
   before any task requires building an app.

## Open questions

None. Workspace-level questions go in `docs/QUESTIONS.md`.

## Blockers

None.

## Recent

- 2026-11-15 — scaffolded the agent team (v1, single project).
- 2026-11-15 — restructured into a multi-project workspace (v2): per-project
  artifacts, shared process and agents, registry, project template and script.
