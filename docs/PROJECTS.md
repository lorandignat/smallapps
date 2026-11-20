# PROJECTS

Registry of everything in this workspace. Owner: `ba`. One row per project, kept
true; the project's own `docs/STATE.md` has the detail.

| Project | What it is | Phase | Stack | v1 status | Last worked |
| --- | --- | --- | --- | --- | --- |
| `play-two` | iPhone 6s as an AirPlay 2 receiver for an Apple TV, out to Bluetooth | release | Swift / iOS 15 | release candidate — increment 1 (discoverable) complete, awaiting human acceptance | 2026-11-20 |

**Counts:** 1 active · 0 in build · 0 shipped · 0 paused

## Phases

`idea → intake → breakdown → build → release → maintenance`, with `paused` and
`archived` for anything deliberately stopped. Definitions in
`docs/PROCESS.md` §2.

## Adding a project

1. `./scripts/new-project.sh <slug>`
2. Fill the new `README.md` header and the `docs/STACK.md` decision.
3. Add the row above, phase `intake`.
4. Start intake (`/idea`).

## Rules

- A row is added at creation and removed only when archived; archived rows keep
  their history and link to the final state.
- "v1 status" is one of: `not started`, `spec approved`, `n/m tasks`,
  `release candidate`, `shipped <date>`.
- If two projects claim the same priority, the human decides; the BA asks once
  and records the answer.
