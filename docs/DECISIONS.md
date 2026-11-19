# DECISIONS

One entry per decision that someone might later ask "why?". Append only; reverse
a decision with a new entry, never by editing the old one.

Format:

```md
## DEC-001 — <title>
- date: YYYY-MM-DD
- status: proposed | accepted | superseded by DEC-###
- owner: ba
- context: what forced a choice
- decision: what we chose
- consequences: what it costs, what it enables
```

---

## DEC-001 — BA is the single dispatcher

- date: 2026-11-15
- status: accepted
- owner: ba
- context: Four roles need to cooperate. OpenCode subagents can launch
  subagents, but deep nesting multiplies context loss and makes blame
  ambiguous.
- decision: Only the BA launches subagents: `ba → pm`, `ba → developer`,
  `ba → qa`. PM and QA never dispatch; the human never addresses anyone but
  the BA.
- consequences: one clear chain of custody, shallow nesting, and every task has
  a single accountable owner at each moment. Cost: the BA's context grows over a
  long run, mitigated by disk state.

## DEC-002 — Only tester-approved work counts as done

- date: 2026-11-15
- status: accepted
- owner: ba
- context: Agents tend to declare success on their own work.
- decision: `done` requires a `PASS` verdict from `qa` recorded in
  `qa/reports/TASK-###-review.md`, plus BA gate G4. Developer self-reports are
  advisory only.
- consequences: slower per task, trustworthy state.

## DEC-003 — One task per developer invocation

- date: 2026-11-15
- status: accepted
- owner: ba
- context: Batch work produces unreviewable diffs and untraceable failures.
- decision: Developer receives exactly one task ID per launch and never starts
  a second task. Task size is enforced upstream by PM atomicity rules (≤ one
  behavior, ≤ ~30 minutes of work, single commit).
- consequences: many small commits; predictable diffs; easy rollback.

## DEC-004 — iOS toolchain deferred

- date: 2026-11-15
- status: accepted
- owner: ba
- context: The build host is Linux with no Xcode and no root. iOS binaries can
  only be produced on macOS or a macOS CI runner.
- decision: No language toolchain is installed yet. Options and their costs are
  documented in `docs/PLATFORM.md`; the stack is chosen at first intake.
- consequences: intake must settle the stack before Phase 1 breakdown.
