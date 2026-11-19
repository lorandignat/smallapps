---
description: Show the state of every project
agent: ba
---

Read `docs/STATE.md`, `docs/PROJECTS.md`, `git log --oneline -5`, and the
`docs/STATE.md` of every project listed as active.

Reply as a compact table, one line per project, then at most three lines of
commentary:

```text
<project>   <phase>   <n/m tasks>   <next task or gate>   <blocked?>
```

Then: what is waiting on me, and what you would do next without me. Six lines of
commentary maximum. No process explanation.
