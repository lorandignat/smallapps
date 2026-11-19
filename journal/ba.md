# BA journal

Append-only. Newest entry at the bottom. One entry per unit of work. This is
memory, not status — status lives in `docs/PROJECT-STATE.md`.

Format:

```md
## YYYY-MM-DD HH:MM — <what this was>
- did:
- decided:
- dispatched: <agent> for <TASK-###> → <result>
- next:
```

---

## 2026-11-15 — team scaffolded

- did: set up process, four agents, skills, state files, local git repo.
- decided: DEC-001 … DEC-004 (see `docs/DECISIONS.md`).
- next: await the human's idea; run intake.

## 2026-11-15 — smoke test

- did: dispatched pm, developer and qa once each with a no-write brief; all three
  answered, each saw only its own skills, no files changed.
- decided: keep BA-as-single-dispatcher (DEC-001); stack still undecided
  (DEC-004), so no task may require building an app until it is settled.
- next: intake.
