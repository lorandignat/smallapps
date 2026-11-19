---
name: BA Orchestration
description: How the BA dispatches pm, developer and qa, runs one task at a time, handles rework, commits after each PASS, and runs unattended overnight batches. Use for any build-loop step or overnight run.
---

# Orchestration

You are the dispatcher. Nobody else launches anyone.

## The dispatch calls

Launch with the `subagent` tool, `agent:` set to the exact ID. Every brief must be
self-contained: the child cannot see this conversation.

**PM — breakdown**

```text
agent: pm
prompt: |
  Decompose the approved spec into demoable vertical features, then split the
  FIRST feature only into atomic tasks.
  Spec: product/SPEC.md (approved at G1 on <date>)
  Platform/stack: docs/PLATFORM.md — <stack>
  Definition of v1: <one line from the spec>
  Constraints: <hard limits from the spec>
  Use the templates in backlog/. Append every ID to backlog/BOARD.md.
  Reply with the summary format from your instructions. Do not dispatch anyone.
```

**Developer — one task**

```text
agent: developer
prompt: |
  Task: TASK-0NN (attempt <n>)
  Read backlog/tasks/TASK-0NN.md and implement exactly that task.
  Scope: only the files listed in the task.
  <if rework> Previous verdict: FAIL. Findings to fix, from
  qa/reports/TASK-0NN-review.md: <paste the findings verbatim>
  Same task, do not start anything else. </if>
  Run the verification commands and the regression checks, log to
  journal/<role>.md, and reply with the report format from your instructions.
```

**QA — one task**

```text
agent: qa
prompt: |
  Verify TASK-0NN (attempt <n>) against its acceptance criteria.
  Task: backlog/tasks/TASK-0NN.md
  Developer report: <paste it verbatim>
  Regression list: qa/REGRESSION.md
  Write qa/reports/TASK-0NN-review.md and reply with the verdict format only.
  You may not edit source; return FAIL if the code needs changes.
```

## Your cycle, exactly

1. `backlog/tasks/TASK-0NN.md` → `status: in-progress`; board → in-progress;
   increment `attempts`.
2. Dispatch developer. Wait for the report.
3. Task → `in-review`; dispatch qa with the developer's report.
4. Open `qa/reports/TASK-0NN-review.md` and read it. Check: evidence per
   criterion, scope of the diff (`git diff --stat`), regressions addressed.
5. `PASS` → commit (`TASK-0NN: <title>`), task `done`, board updated,
   `docs/PROJECT-STATE.md` updated, journal entry. Next task.
6. `FAIL` → task `rework`; append the findings to the task's rework log; relaunch
   developer with the same ID. Anything else is a process violation.
7. `BLOCKED` → decide: provide the missing thing, ask PM to re-cut the task, or
   `docs/QUESTIONS.md` + task `blocked` and move to the next independent task.
8. Third `FAIL` on one task → stop that task, ask PM to split it, record
   `DEC-###`.

## Committing

```sh
git add -A
git commit -m "TASK-0NN: <title>" -m "Feature: FEAT-00N · Verdict: PASS · Attempt: <n>"
```

Commit after every PASS, nothing else outstanding. Phase boundaries
(spec approved, backlog approved, feature closed) get
`chore(process): ...`. Never `git push` — it is denied by policy.

## Anti-patterns to catch in yourself

- Accepting "done" from the developer instead of from qa.
- Running two tasks in parallel "to save time". One at a time.
- Rewriting a task's criteria so it can pass.
- Skipping the report read because the summary looked fine.
- Doing a small fix yourself. You cannot edit code, and you should not want to.
- Starting a task that is not `approved` in the backlog.

## Unattended runs

Start: read state, confirm the task is approved, note the cycle budget (12
default). During: update `docs/PROJECT-STATE.md` after every task so a crash
loses at most one task. Stop on any §7 condition and write the question. End:
summary of tasks done / failed / blocked, and one line on what you would do next.
