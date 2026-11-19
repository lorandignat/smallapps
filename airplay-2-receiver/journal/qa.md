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

## 2026-11-15 — TASK-001 (attempt 1)
- verdict: BLOCKED (QQ-005). Criterion 4 (project.yml contract) PASS statically;
  criteria 1, 2, 3, 5 need the Mac. R3 and R5 pass statically; R1, R2 BLOCKED.
- evidence: `grep`/YAML parse on `project.yml` (iOS 15.0 at :14, scheme at :49-50,
  `bundle.unit-test` at :35, `packages:` 0, `DEVELOPMENT_TEAM` 0); `git
  check-ignore` on `.xcodeproj` and `build/`; all five build commands
  exit 1 with `error: missing …/local configuration; `/tmp/opencode/task-001-test.log`
  holds only that line, so no `Executed 1 test` exists.
- scope: the task commit also moves TASK-001 to `in-review` in `BOARD.md` and the
  task file (BA-owned, likely committed by the BA); the developer's files are the
  five in-scope ones plus an append-only journal entry.
- recurring issue: none yet — first task. Two process defects found in QA's own
  docs: `rsync -a <project> <build-host>:<build-dir>/ --delete` removes the Mac's generated `.xcodeproj` and
  plists every time, so `xcodegen generate` must follow every sync (TEST-PLAN
  preamble corrected); A9/R3's scheme check matched the project `name:` instead
  of the scheme (R3 tightened).
- unverifiable: the Swift compiles, XcodeGen accepts `project.yml`, the simulator
  named `iPhone 16` exists, `Executed 1 test, with 0 failures`.
- next: re-run TASK-001 on the Mac when QQ-005 clears; do not start TASK-002
  before R1/R2 are green.

## 2026-11-16 — TASK-001 (attempt 1, round 2)
- verdict: **PASS**, all 5 criteria executed on the real Mac. Round 1's BLOCKED
  cause (`QQ-005`, no `mac.env`) is resolved: `check` exit 0, macOS 26.6.2, Xcode
  26.6, iOS 26.5 SDK.
- evidence: `sync` → no `.xcodeproj` (`zsh: no matches found`) → `xcodegen
  generate` exit 0 and the project exists; `build … iphonesimulator` exit 0,
  `** BUILD SUCCEEDED **`, real `.app` with `MinimumOSVersion 15.0`; `test …
  name=iPhone 16e` exit 0, `Executed 1 test, with 0 failures`, zero `error:`
  lines; `xcodebuild -list` + `project.pbxproj` confirm scheme, targets,
  `bundle.unit-test`, `IPHONEOS_DEPLOYMENT_TARGET = 15.0`; after a sync `build`
  exits 1 with `no .xcworkspace or .xcodeproj in … — run: … xcodegen generate`.
- anti-accident: mutating `AppInfo.displayName` on the Mac copy makes the test
  fail (`Executed 1 test, with 1 failure`, `XCTAssertEqual failed`), then `sync`
  restores it (sha256 match) and it passes; the literal `name=iPhone 16` fails
  with "Unable to find a device matching", so `iPhone 16e` (DEC-005) is the only
  working destination; clean derived-data build also green.
- regressions: R1 PASS, R2 PASS (count 1 = high-water 1), R3 PASS (static + Mac),
  R5 PASS, R6 (new: test not vacuous) PASS. R4 pending by design (TASK-003).
- scope: developer commit `dd15fbb` = the five in-scope files + `journal/<role>.md`,
  plus the BA's two `in-review` status lines; the other commits since the task
  started are the BA's BLOCKED verdict and workspace Mac-bridge chores. No
  developer change outside scope.
- findings: six MINOR, none blocking — `iPhone 16` still in the task file (PM, my
  TEST-PLAN/REGRESSION fixed); criterion-5 message quoted in the other word
  order; criterion 5's "edited without regenerating" is really "sync removed the
  project" (a bare edit on the Mac copy builds green from the stale project);
  generated plists not gitignored; display name duplicated in two files.
- unverifiable: no iPhone 6s connected (device-only S1b/S1c/S5); iOS 15 runtime
  behaviour (simulator is 26.5, 15.0 is compile-time + `MinimumOSVersion`).
- next: BA may close TASK-001; TASK-002 raises R2's high-water mark to 6 and owns
  findings 4-5.
