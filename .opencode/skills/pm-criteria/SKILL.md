---
name: PM Acceptance Criteria
description: Write acceptance criteria and verification commands that a tester can execute without judgement calls. Use whenever creating or re-cutting a task.
---

# Acceptance criteria

Criteria are a contract between the developer and the tester. If the tester has
to interpret them, they are wrong.

## Form

Given/When/Then, one observable result each:

```md
1. [ ] Given an empty draft, when "Save" is tapped, then the button is disabled
       and the field shows "Nothing to save".
2. [ ] Given a draft "hello", when "Save" is tapped, then reopening the app shows
       "hello" in the same field.
3. [ ] Given storage rejects a write, when "Save" is tapped, then an error banner
       reads "Could not save" and the draft text is still in the field.
```

## Rules

- **Observable, not internal.** "The repository layer caches the value" is not
  observable; "the second load does not hit the network" might be, if the tester
  can see it.
- **No subjective words.** easy, fast, clean, nice, proper, robust, valid — banned
  unless quantified ("under 200 ms on the fixture").
- **Always include the failure path.** A task without an error-path criterion
  invites code that only handles the happy path.
- **2-5 criteria per task.** More than five means the task is too big.
- **Every criterion gets verification.** Either an exact command or a described
  observation with the exact expected text/state.

## Verification commands

Give the tester runnable commands, not advice:

```sh
npm test -- src/save.test.ts
npm run lint
```

If a criterion can only be checked by eye, write the steps and the expected
result precisely enough that two people would agree on pass/fail. If nobody can
agree, the criterion is not testable — rewrite it.

## Anti-patterns

| Bad | Why | Fix |
| --- | --- | --- |
| "Save works correctly" | no observable | state the exact user-visible result |
| "Handle errors gracefully" | multiple outcomes | name the message and the state after |
| "Add tests" | not a behaviour | tests are part of the criterion above |
| "Improve performance" | unmeasurable | give a number and a fixture |
| "Refactor X" | no behaviour | fold it into a task that needs it |

## Re-cutting a rejected task

If the BA rejects criteria, do not reword them — usually the task is too big.
Split it so each piece has one obvious criterion, or replace an unverifiable
criterion with the closest observable proxy and say so in `Notes`.
