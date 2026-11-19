---
name: PM Decomposition
description: Slice an approved spec into vertical, demoable features and order them by dependency. Use when turning product/SPEC.md into backlog/features/.
---

# Decomposition

## Features are slices, not layers

Bad: "database schema", "API client", "design system", "tests".
Good: "add a photo and see it in the grid", "rename a photo", "share one photo".

A feature is valid when you can write one sentence starting with "the user can…"
and showing it takes under a minute.

## Procedure

1. Read the spec's core flow (§3). Each step that changes what the user can *do*
   is at least one feature.
2. Write the smallest set of slices that makes the core flow work end to end.
   Aim for 3-6 features for v1. More means the spec is too big — say so.
3. Order by dependency, then by risk: the slice that could invalidate the design
   comes early, even if it is not the most visible.
4. For each feature, write the feature-level acceptance criteria and a two-step
   demo.
5. Fill `depends_on` honestly. If A cannot be demoed before B, A depends on B.
6. Do **not** split future features into tasks yet.

## Sizing a feature

| Size | Symptom | Action |
| --- | --- | --- |
| too big | more than ~8 tasks, or two personas | split into two demoable slices |
| right | 3-8 tasks, one visible outcome | proceed |
| too small | a task in disguise, or no user-visible change | merge with a neighbour |

## Anti-patterns

- **Horizontal slices.** "Add persistence" is not demoable; "photos survive an
  app restart" is.
- **Hidden scope.** A feature that quietly includes onboarding, settings, and
  sync. Name them as separate features or non-goals.
- **Test/refactor features.** Testing is part of every task; refactoring belongs
  inside the task that needs it.
- **Speculative features.** If the spec does not ask for it, it does not go in.
  List it under "deferred" in your journal.

## Output

Feature files named `FEAT-001.md`, `FEAT-002.md`, … never renumber, never reuse.
Update `backlog/BOARD.md` features table in the same turn (status `proposed`
until the BA approves at G2).
