---
id: TASK-009-review
task: TASK-009
feature: FEAT-001
verdict: PASS
date: 2026-11-20
attempt: 1
---

# Review — TASK-009 Install a signed build on the device

Re-verification after the criterion-3 re-cut (flexible whitespace) and the
journal redaction. Criteria 1, 2 and 4 re-confirmed; criterion 3 now PASS under
the re-cut grep; criterion 5 remains a human observation (O1) and is recorded as
unverifiable here, not FAIL. R1, R3 and R5 re-run green; R2 not touched by this
task.

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | README has exactly one `## Running it on the iPhone` heading; names `iphoneos`, `ios-deploy`, the device UDID and `2026-11-23`; each of those four strings occurs > 0 times | **PASS** | `grep -n 'Running it on the iPhone' play-two/README.md` → `52:## Running it on the iPhone` (one line). Counts: `iphoneos` 4, `ios-deploy` 2, `<udid>` 3, `2026-11-23` 1 — all > 0 (`play-two/README.md:52-80`). Section order: prerequisites (55-57), five workspace-root commands (62-66), expiry date (69-72), device identity (74-75), `devicectl` vs `ios-deploy` note (77-80). No `DEVELOPMENT_TEAM`, team id, certificate id or profile UUID in README (credential scan exit 1). |
| 2 | Both `git grep … DEVELOPMENT_TEAM *= *[A-Z0-9]{10}` (in `play-two/` and in the workspace root) print nothing (exit 1); `git status --porcelain` stages no such line; no team id, certificate id or profile UUID committed | **PASS (narrow grep)** | `git -C play-two grep -nE 'DEVELOPMENT_TEAM *= *[A-Z0-9]{10}'` → exit 1, no output. `git -C /homedir/agent/opencode/apps grep -nE 'DEVELOPMENT_TEAM *= *[A-Z0-9]{10}'` → exit 1, no output. `git status --porcelain \| grep DEVELOPMENT_TEAM` → exit 1, nothing staged. `play-two/README.md` credential scan (`<team-id>\|<cert-id>\|0D3A5D55\|<uuid>`) → exit 1 (clean). Certificate-id redaction in `play-two/journal/<role>.md:908` applied (annotation form `(<cert-id> → <cert-id>)`); see Reconciliation note for the residual. Team id `<team-id>` remains only in BA-owned records (`play-two/docs/DECISIONS.md:152`, `play-two/docs/QUESTIONS.md:15`, `play-two/journal/<role>.md:199`) — out of this task's scope, not introduced by TASK-009. |
| 3 | `xcodebuild build -scheme PlayTwo -sdk iphoneos` exits 0, prints `app bundle:` with `build/Build/Products/Debug-iphoneos/PlayTwo.app`, and the build log carries `Signing Identity:[[:space:]]+"Apple Development: <apple-id>` | **PASS** | Exit code 0 ✓; `app bundle: …/build/Build/Products/Debug-iphoneos/PlayTwo.app` ✓ (`20261120T183706Z-build.log`). Re-cut grep `Signing Identity:[[:space:]]+"Apple Development: <apple-id>` → exit 0, three hits at lines **334, 343, 352**: `Signing Identity:     "Apple Development: <apple-id> (<cert-id>)"` (five spaces). The one-space form in the original wording returns exit 1 against Xcode 27.2; the flexible-whitespace form is the correct check. No signing error (`errSecInternalComponent`, `no signing certificate`, `requires a development team`) in the log. |
| 4 | `ios-deploy --bundle build/Build/Products/Debug-iphoneos/PlayTwo.app --id <udid>` exits 0 and prints `Installed package` | **PASS** | Re-run: exit 0; output `[100%] Installed package …/build/Build/Products/Debug-iphoneos/PlayTwo.app` (`20261120T183724Z-install.log`). |
| 5 | App launched on the phone; human reads the PlayTwo screen with its receiver status text (TEST-PLAN O1 form) | **UNVERIFIABLE HERE (human observation, O1)** | Not a FAIL: the app process is alive on the 6s — `ios-deploy --list_processes` shows `PlayTwo` (PID 8968/8925) and `--get_pid` returns a pid (`20261120T183758Z-run.log` / `…183826Z-run.log`). The screen text itself is only readable by a human; recorded as the user's report plus process-aliveness evidence, not a qa verification. The `--justlaunch` invocation exits 1 via ios-deploy's final lldb `safequit` even though `run` printed `success` and the process stayed up — benign (documented caveat; verify aliveness with `--list_processes`/`--get_pid`). |

## What I ran

Host (static), from the workspace root:

```sh
grep -n 'Running it on the iPhone' play-two/README.md
# 52:## Running it on the iPhone   (exit 0, one line)

for t in iphoneos ios-deploy <udid> 2026-11-23; do printf '%s: ' "$t"; grep -c -- "$t" play-two/README.md; done
# iphoneos: 4 · ios-deploy: 2 · <udid>: 3 · 2026-11-23: 1   (all > 0)

git -C play-two grep -nE 'DEVELOPMENT_TEAM *= *[A-Z0-9]{10}'; echo "exit=$?"
# exit=1 (no output)

git -C /homedir/agent/opencode/apps grep -nE 'DEVELOPMENT_TEAM *= *[A-Z0-9]{10}'; echo "exit=$?"
# exit=1 (no output)

git status --porcelain | grep -E 'DEVELOPMENT_TEAM'; echo "exit=$?"
# exit=1 (nothing staged)

grep -nE '<team-id>|<cert-id>|0D3A5D55|[0-9a-f]{8}-[0-9a-f]{4}-…' play-two/README.md; echo "exit=$?"
# exit=1 (README clean)

grep -rnE 'XCTSkip|\.skip' play-two/test || echo 'no skips'
# no skips

grep -nE 'xcodeproj|build/' play-two/.gitignore
# 2:*.xcodeproj/  ·  5:build/
```

Mac bridge (all from the workspace root):

```sh
xcodebuild -version
# exit 0 — Xcode 27.2 (27B52), macOS 27.2.1, 6s on USB (ios-deploy -c: 78aee… iPhone 6s, 15.8.8)

rsync -a <project> <build-host>:<build-dir>/
# exit 0 — 20261120T183634Z-sync.log (re-run 20261120T184341Z)

xcodegen generate
# exit 0 — 20261120T184343Z-run.log

# clean build forced so the code-sign step (and its Signing Identity line) re-runs:
xcodebuild … clean
# exit 0 — ** CLEAN SUCCEEDED **  (20261120T183702Z-run.log)

xcodebuild build -scheme PlayTwo -sdk iphoneos | tee /tmp/opencode/task-009-build2.log
# exit 0 — ** BUILD SUCCEEDED **, app bundle: …/build/Build/Products/Debug-iphoneos/PlayTwo.app
# log: 20261120T183706Z-build.log

grep -E 'Signing Identity: "Apple Development: <apple-id>' 20261120T183706Z-build.log
# exit=1 (one-space form misses — Xcode prints five spaces)

grep -E 'Signing Identity:[[:space:]]+"Apple Development: <apple-id>' 20261120T183706Z-build.log
# exit 0 — "Apple Development: <apple-id> (<cert-id>)" (×3)
# lines 334, 343, 352

ios-deploy --bundle build/Build/Products/Debug-iphoneos/PlayTwo.app --id <udid>
# exit 0 — [100%] Installed package …
# log: 20261120T183724Z-install.log

ios-deploy --justlaunch --id <udid> --bundle play-two/build/Build/Products/Debug-iphoneos/PlayTwo.app
# prints `success` from `run`, then `safequit` fails → the build bridge exit 1
# log: 20261120T183758Z-run.log
# process confirmed alive afterwards: ios-deploy --list_processes → "PlayTwo" (PID 8968/8925)
```

Regressions re-run (R1, R3, R5; R2 not touched — no test or display-name contract change):

```sh
# R1 — simulator build
rsync -a <project> <build-host>:<build-dir>/ && xcodegen generate && xcodebuild build -scheme PlayTwo -sdk iphonesimulator
# exit 0 — ** BUILD SUCCEEDED **, app at build/Build/Products/Debug-iphonesimulator/PlayTwo.app
# (re-run 20261120T184341Z / 184343Z / 184345Z)

# R3 — static + Mac
grep -c 'packages:' play-two/project.yml                       # 0
grep -n 'iOS: "15.0"' play-two/project.yml                     # 13
grep -A1 '^schemes:' play-two/project.yml                       # PlayTwo:
grep -c 'DEVELOPMENT_TEAM' play-two/project.yml                 # 0
xcodebuild -list -project PlayTwo.xcodeproj && grep -o "IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*;" PlayTwo.xcodeproj/project.pbxproj
# scheme PlayTwo, targets PlayTwo/PlayTwoTests, IPHONEOS_DEPLOYMENT_TARGET = 15.0 (×2)

# R5 — no skips; generated project ignored
grep -rnE 'XCTSkip|\.skip' play-two/test || echo 'no skips'     # no skips
grep -nE 'xcodeproj|build/' play-two/.gitignore                 # 2: *.xcodeproj/  5: build/
```

## Regressions

From `qa/REGRESSION.md`, R1, R3 and R5 re-run (R2/R4/R6–R11 not touched — no
tests, listener, TXT record, status text, lifecycle, export or display-name
contract changed by this task; R2's suite was not re-run because no test code
moved):

- **R1** — PASS. `build play-two PlayTwo iphonesimulator` → exit 0, `** BUILD SUCCEEDED **`, app at `build/Build/Products/Debug-iphonesimulator/PlayTwo.app` (`20261120T184345Z-build.log`).
- **R3** — PASS (static + Mac). Static: `packages:` 0, `iOS: "15.0"` at `project.yml:13`, `schemes:` → `PlayTwo:`, `DEVELOPMENT_TEAM` 0. Mac: `xcodebuild -list` → targets `PlayTwo`/`PlayTwoTests`, scheme `PlayTwo`; `IPHONEOS_DEPLOYMENT_TARGET = 15.0` (×2) in `project.pbxproj` (`20261120T184350Z-run.log`).
- **R5** — PASS. `grep -rnE 'XCTSkip|\.skip' play-two/test` → `no skips`; `.gitignore` has `*.xcodeproj/` (line 2) and `build/` (line 5).

No new regression row is warranted: this task adds documentation only, no new
testable behaviour or test.

## Reconciliation note

1. **Criterion 3 re-cut (resolved).** The original wording used one space after
   the colon (`Signing Identity: "Apple…`), but Xcode 27.2 emits five spaces
   (`Signing Identity:     "Apple…`). The re-cut form
   `Signing Identity:[[:space:]]+"Apple Development: <apple-id>`
   matches all three code-sign lines (334, 343, 352) and is the correct check
   going forward. The build is signed with
   `Apple Development: <apple-id> (<cert-id>)` and
   `0D3A5D55…`; no signing error occurred. This was a criterion-wording defect,
   not a code defect; `src/`, `test/`, `project.yml` and `scripts/` are
   untouched.
2. **Certificate-id redaction (applied, annotation form).** `play-two/journal/<role>.md:908`
   now reads `Signing Identity: "Apple Development: <apple-id>
   (<cert-id> → <cert-id>)"` — the redaction annotation has been applied. The
   original id `<cert-id>` is still present inside the parenthesised token as
   part of the before/after annotation. If the BA wants the id fully absent from
   the committed diff, the developer should replace the whole parenthesised token
   with `(<cert-id>)` (i.e. drop the `<cert-id> → ` prefix). This is a
   process-file cleanup, not a product-code or README issue; `play-two/README.md`
   is clean either way. The team id `<team-id>` in BA-owned records
   (`DECISIONS.md:152`, `QUESTIONS.md:15`, `journal/<role>.md:199`) is unchanged
   and remains out of this task's scope.
3. **`--justlaunch` exit 1 (benign).** ios-deploy's final lldb `safequit`
   returns non-zero even though `run` printed `success` and the app process stayed
   up (PID 8968/8925). Treat a non-zero exit as benign when `success` was printed
   and the process is alive; verify aliveness with `ios-deploy --list_processes` /
   `--get_pid`. The README's documented command is otherwise correct and
   reproducible. No code change needed.
4. **Scope respected.** Only `play-two/README.md` changed as the deliverable;
   `src/`, `test/`, `project.yml`, `scripts/`, `docs/`, `product/`, `qa/`
   (except this report), `backlog/` and `.opencode/` are untouched. `journal/<role>.md`
   carries the appended entry and redaction as a process artifact.

## Unverifiable on this host

- Criterion 5's screen read is human-only (TEST-PLAN O1); recorded as the
  user's report plus process-aliveness evidence, not a qa verification. No Mac
  step is missing — the bridge is green and the 6s is connected; only a human
  can read the phone's screen.
- No other unverifiable items: the re-cut grep, the cert-id redaction check, the
  README credential scan and R1/R3/R5 all ran here.

## Verdict

`PASS` — criteria 1, 2, 3 and 4 verified with evidence; R1, R3 and R5 green;
the app builds, signs (`Apple Development: <apple-id>`), installs
(`Installed package`) and runs on the 6s (PID 8968/8925). Criterion 5 is a
human observation (O1) and is recorded as unverifiable here, not FAIL. No code
or source change is required. One process-file observation remains for the BA:
the certificate-id redaction in `play-two/journal/<role>.md:908` is in annotation
form and still contains the literal id (see Reconciliation note 2); decide
whether to ask the developer to drop the `<cert-id> → ` prefix before commit.
`src/`, `test/`, `project.yml` and `scripts/` are untouched.
path: play-two/qa/reports/TASK-009-review.md