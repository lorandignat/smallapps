# QA journal — AirPlay 2 Receiver

Append only, newest at the bottom. Short: what you verified, what you could not,
and any pattern of developer mistakes worth fixing in the process.

```md
## YYYY-MM-DD — TASK-### (attempt n)
- verdict: PASS | FAIL | BLOCKED
- evidence: commands run, counts
- unverifiable:
- recurring issue:
```

---

## 2026-11-15 — FEAT-001 test plan

- did: wrote the FEAT-001 plan (A1-A9 automated on the Mac, O1-O6 human
  observations, triage T1-T5, probes P1-P4) and the increment-1 regression list
  (R1-R5). Distinguishes never-advertised (T1-T3) from Apple-TV-ignored (T4-T5).
- flagged: S5's log half has no producer — no task emits a `Restart` line;
  TASK-007 needs a launch marker. Signing/device install is unowned. The
  simulator's iOS is newer than 15.0, so 15.0 is a compile-time promise only.
- blocked: this entry was written by `ba` because `qa` had no edit rule for
  `journal/<role>.md`; the rule is now added (`**/journal/<role>.md`) and takes effect
  after an OpenCode restart.
- next: verify TASK-001, expecting BLOCKED until QQ-005 resolves.
