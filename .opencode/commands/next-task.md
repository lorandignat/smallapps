---
description: Run exactly one task cycle in the active project, supervised
agent: ba
---

Run one cycle of `docs/PROCESS.md` §5 for the next approved task in dependency
order in the active project, then stop after recording the verdict. "One cycle"
means: dispatch the developer once, dispatch the tester once, read the report,
commit or return for rework, update both state files. Do not start a second task.
Report the outcome in five lines.
