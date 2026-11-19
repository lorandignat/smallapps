---
description: Run exactly one task cycle, supervised
agent: ba
---

Run one cycle of `docs/PROCESS.md` §4 for the next approved task in dependency
order, and stop after recording the verdict. "One cycle" means: dispatch the
developer once, dispatch the tester once, read the report, commit or return for
rework, update state. Do not start a second task. Report the outcome in five
lines.
