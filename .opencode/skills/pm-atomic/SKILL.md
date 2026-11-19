---
name: PM Atomic Tasks
description: Split a feature into tasks small enough that a developer can finish one in a single sitting and a tester can verify it in a few minutes. Use before creating any backlog/tasks file.
---

# Atomic tasks

The developer works on exactly one task per invocation and stops. If a task cannot
be finished and verified in one sitting, it will be half-done, and half-done work
is what breaks unattended runs.

## The atomicity test

A task is atomic when **all** of these hold:

- [ ] Exactly **one behaviour** changes. The title contains no "and".
- [ ] A reviewer can see the whole change in one `git diff` — roughly ≤ 5 files,
      ≤ ~150 changed lines.
- [ ] It takes a competent developer **≤ 30 minutes**, including its test.
- [ ] It has **one commit**.
- [ ] Every criterion can be checked by a command or a described observation.
- [ ] It does not require a second task to be useful or testable.
- [ ] It names the files in scope, and what must not be touched.

If two of these fail, split. If one fails, split anyway — the cost of a split is
minutes, the cost of a bloated task is a lost night.

## Splitting patterns

| Smell | Split by |
| --- | --- |
| "Add form with validation and submit" | render form → validate input → submit + error handling |
| "Support importing files" | happy path for one format → invalid-file errors → second format |
| "Make it work offline" | cache read path → queue writes → resolve conflicts |
| Task touches UI + data + network | one layer becomes its own task, chained by `depends_on` |
| Task needs a decision first | task = "decide X, document in DEC-###"; then implement |
| Task is mostly setup | keep a single "scaffold project + one failing test" task, never a chain of setup tasks |

## Ordering

Order so each task leaves the tree green: a test can be written before the
behaviour only if it is written in the same task. Never create a task whose only
purpose is to make the next task compile.

Use `depends_on` for real ordering constraints only. Two tasks with no dependency
may be done in any order; the BA still runs them one at a time.

## Writing it

Every criterion states its own precondition. Nobody who reads the task has seen
the conversation that produced it: if a step depends on something only you know,
it is not a criterion, it is a note to yourself — write the dependency into the
task or drop the step.

Copy `backlog/tasks/TASK-000-template.md`. Fill every field. `estimate` is
`small` — if you wrote `medium`, split it now, in the same turn, before returning
the batch. `status: proposed`, `attempts: 0`.

Add each new task to the feature's task table and to `backlog/BOARD.md`.
