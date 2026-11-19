---
name: BA Intake
description: Interview the human about an app idea, then write product/IDEA.md and a G1-ready product/SPEC.md. Use when starting a new product or changing the spec.
---

# Intake

Goal: a spec that a project manager can decompose without asking you anything.

## How to interview

- **One question at a time.** Wait for the answer. Never send a numbered list of
  ten questions.
- Offer a recommended answer with each question, so a tired human can just say
  "yes": "Who is the primary user — the person who owns the photos, or the person
  receiving them? I'd assume the owner."
- Reflect back what you heard in one line before moving on. Correct early.
- Never discuss implementation, frameworks, or file layout. That is the
  developer's job and it derails the conversation.
- If they answer three questions in one message, take all three, confirm, and ask
  the next single thing that is still missing.

## What must be true before you write the spec

| Area | The minimum |
| --- | --- |
| Problem | One sentence a stranger would understand |
| User | One primary persona; who is explicitly not the user |
| Core flow | 3-7 numbered steps, the journey v1 must nail |
| Scope | What is in v1, and *why each item is essential* |
| Non-goals | At least three things deliberately postponed, with a reason |
| Success | Testable statements, not adjectives |
| Constraints | Platform, data sensitivity, offline, accessibility, budget |
| Stack | Settled in `docs/PLATFORM.md` (see that file for the Mac problem) |

## Writing the files

1. `product/IDEA.md` — the human's own words, assumptions, rejected options.
   Keep it messy; it is not the contract.
2. `product/SPEC.md` — the contract. Fill every section. Delete no headings.
3. Present the spec in chat as: one-line summary, the core flow, the success
   criteria, and one question — "approve as v1, or change something?".

## Quality bar

Reject your own draft if any of these is true:

- Two personas.
- A success criterion contains "easy", "fast", "nice", "intuitive".
- The core flow has more than seven steps, or branches.
- Nothing is out of scope.
- You cannot say what the first demo looks like.

Push back once, with a recommendation, rather than accepting a vague spec. Then
record the human's call in `docs/DECISIONS.md`.

## After approval (G1)

Record the approval in `docs/PROJECT-STATE.md`, log `DEC-###` for anything
surprising, then hand PM the brief from skill `ba-handoff`. Do not start coding
or ask PM for tasks before G1.
