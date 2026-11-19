---
name: QA Test Strategy
description: Decide what to automate, what to check by observation, and how to keep the suite fast and deterministic for the chosen stack. Use when opening a feature in qa/TEST-PLAN.md.
---

# Test strategy

You verify a project that is being built at the same time, on a small host, with
minutes per task. Optimise for fast, trustworthy checks — not coverage numbers.

## Layers

| Layer | When | Cost |
| --- | --- | --- |
| Unit tests of pure logic | always, written by the developer, re-run by you | seconds |
| Component/widget tests | anything with state or rendering | seconds |
| End-to-end / integration | the core flow of the feature, one path | minutes |
| Observation (manual steps) | visual, platform, or interaction checks | varies |

Every task needs at least one automated check. Features need one end-to-end path
that exercises the demo steps.

## Rules

- **Fast:** the whole suite should run in under ~2 minutes. Slow suite → the loop
  dies on a long night.
- **Deterministic:** no real network, no sleeps, no real clock, no random data
  without a seed. A flaky test is a finding, not an inconvenience.
- **Isolated:** tests must not depend on run order or on leftover state.
- **Meaningful:** a test that passes with the feature removed is dead weight —
  replace it.
- **No secrets, no real accounts, no paid services.** Fixtures only.

## Platform limits

Check `<project>/docs/STACK.md` before promising anything. On Linux you cannot
run an iOS simulator or produce a signed build. Write that into the plan's "Out
of scope for verification" section, and return `BLOCKED` when a criterion depends
on it rather than inventing confidence.

## Per-feature plan

Add a section to `qa/TEST-PLAN.md` before verifying that feature's first task:
automated commands, observational checks with expected results, what is out of
scope, and exit criteria. Keep it to one page.

## Growing the suite

Between tasks, look for gaps: a bug that slipped through, a finding that repeated,
a criterion nobody could check. Turn each into either a regression row or a note
to the BA that a future task should cover it.
