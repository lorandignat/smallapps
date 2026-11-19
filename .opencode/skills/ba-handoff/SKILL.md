---
name: BA Handoff
description: Brief templates for dispatching pm, developer and qa so a subagent with no conversation context can do its job and nothing more. Use every time you launch a subagent.
---

# Handoffs

A subagent starts with a fresh context. If a fact is only in your head or in the
chat, it does not exist for them. Every brief carries: the ID, the file to read,
the boundaries, and the exact reply shape.

## Rules

1. **Point at files, do not paraphrase them.** "Read `backlog/tasks/TASK-014.md`"
   beats a summary you wrote from memory.
2. **Verbatim findings.** When sending rework, paste the tester's findings
   exactly. Summarising them is how a fix gets lost.
3. **State the boundary out loud.** Files allowed, files forbidden, and one
   sentence on what is out of scope.
4. **One job per launch.** Never "implement task 14 and also look at task 15".
5. **Ask for the fixed reply format**, so you can tell a report from an essay.
6. **No secrets, no credentials, no host paths.** They do not need them.

## PM

```text
Decompose the approved spec into demoable vertical features; split only the
first feature into atomic tasks.
Spec: product/SPEC.md — approved at G1 <date>
Stack: <from docs/PLATFORM.md>
v1 definition: <one sentence>
Hard constraints: <3-5 bullets from the spec §7>
Templates: backlog/features/FEAT-000-template.md, backlog/tasks/TASK-000-template.md
Update backlog/BOARD.md. Do not dispatch anyone.
Reply: the summary format from your instructions, nothing longer.
```

## Developer

```text
Task: TASK-0NN — attempt <n>.
Read backlog/tasks/TASK-0NN.md, then the feature file it belongs to.
Implement exactly that task. Allowed files: <list>. Do not touch: <list>.
Run the task's verification commands and the regression list.
<if rework>
The previous attempt failed. Fix these findings from
qa/reports/TASK-0NN-review.md, verbatim:
<paste>
This is the same task. Do not start another one.
</if>
Reply: the report format from your instructions.
```

## QA

```text
Verify TASK-0NN — attempt <n> — against its acceptance criteria.
Task: backlog/tasks/TASK-0NN.md. Regression list: qa/REGRESSION.md.
Developer report (verify, do not trust):
<paste>
Write qa/reports/TASK-0NN-review.md. You may write only inside qa/.
Reply: the verdict format only.
```

## Reading the reply

- Missing files or evidence → send it back once with what is missing. Do not do
  the work yourself.
- A report that argues with the task ("I also refactored X") → treat the extra
  work as a scope violation at G4.
- A `BLOCKED` without a specific missing thing → send it back asking for exactly
  one sentence: what is missing and what would unblock it.
