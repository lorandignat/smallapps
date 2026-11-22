---
id: FEAT-003-feature-review
feature: FEAT-003
verdict: PASS
scope: code/task level; S2a and S2b pending human observation
date: 2026-11-22
---

# FEAT-003 — HAP pairing endpoints and persistence — feature close

**Verdict: PASS at the code/task level.** All six tasks have a `qa` verdict of
PASS with runtime evidence, the regression list is green at the 81/0 high-water
mark, and `qa/REGRESSION.md` R4 has been reworded per `DEC-018` without deleting
the row. **S2a and S2b are human observations and were not performed or verified
by any agent**; they are recorded here as pending, in the same way FEAT-001
recorded O1-O6 (`play-two/docs/STATE.md:26`). This PASS does not claim either was
observed. No 14-minute suite was re-run for this close: both completed 81/0 runs
are already evidenced below.

## Feature criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| S2a (human) | Given the app is foregrounded on the iPhone 6s, when the human runs Home app "Add Accessory" and enters the setup code, then it completes without error and the phone is listed as a speaker | **PENDING — human observation, not verified here** | No agent can drive the Home app or see the 6s screen (`docs/STACK.md`, "What cannot be verified on this host"). The exact report string is in `qa/TEST-PLAN.md` FEAT-003 → Observational checks. Code-level support only: `GET /info` TASK-016 c2, pair-setup TASK-018 c1-c3, pair-verify TASK-019 c1-c3, setup code shown TASK-021 c3 (`src/HAP/HAPServer.swift:22`, `src/ContentView.swift:26`). None of these is S2a. |
| S2b (human) | Given the phone is paired, when the app is killed and relaunched, then the Home app still shows it as paired (no re-pair prompt) and the app's state screen shows the paired state | **PENDING — human observation, not verified here** | Same constraint. Code-level support only: the Keychain record reloads across instances (TASK-017 c1-c2), the `sf` flag reflects pairing (TASK-020 c1-c2), and a stored `paired: true` maps to `.paired`/`"Paired"` at launch and stays paired through `.advertising` (TASK-021 c1-c2). The Home app's no-re-pair-prompt behaviour is not covered by a unit test. |
| Regression | Increment-1 behaviours that still apply keep passing; the fixed 38-byte reply is superseded by HTTP handling and R4 is retired/updated accordingly | PASS | Two independent 81/0 bundles (quotes below); R1-R15 green; R4 reworded in `qa/REGRESSION.md` to assert `HAPServer.route` (`src/HAP/HAPServer.swift:134-145`) with `DEC-018` cited, row retained, free-port checks and app-level note kept; retired literal confirmed gone by `grep -n 'static let response' play-two/src/Net/ReceiverListener.swift` → no match. |
| Every task in this feature `done` with a `qa` verdict of `PASS` | PASS | Six reports `qa/reports/TASK-016-review.md` … `TASK-021-review.md`, all PASS on attempt 1; `backlog/BOARD.md:107` records 21 tasks done with none active; `docs/STATE.md:14` records FEAT-003 6 of 6 tasks done. |

## Task verdicts

| Task | Behaviour | Verdict (attempt) | Bundle at close |
| --- | --- | --- | --- |
| TASK-016 | Serve `GET /info` on port 7000, replacing the fixed reply | PASS (1) — `qa/reports/TASK-016-review.md` | 62/0 |
| TASK-017 | Expose pairing state in `HAPPairingStore` | PASS (1) — `qa/reports/TASK-017-review.md` | 68/0 |
| TASK-018 | Complete `POST /pair-setup` (SRP M1-M6) | PASS (1) — `qa/reports/TASK-018-review.md` | 73/0 |
| TASK-019 | Establish an encrypted session with `POST /pair-verify` | PASS (1) — `qa/reports/TASK-019-review.md` | 78/0 |
| TASK-020 | Advertise paired status in the AirPlay TXT record (`sf`) | PASS (1) — `qa/reports/TASK-020-review.md` | 79/0 |
| TASK-021 | Restart survival: setup code and paired state on screen | PASS (1) — `qa/reports/TASK-021-review.md` | 81/0 |

No task reached a second attempt. Per-task suite growth is pinned in `qa/REGRESSION.md` R2.

## Regression status

- **R2 — pass, high-water 81.** Two independent full runs of
  `xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.2'`:
  the developer's run mirrored at
  `20261122T140413Z-test.log:528` — `Executed 81 tests, with 0
  failures (0 unexpected) in 841.306 (841.354) seconds` — and `:538` — `**
  TEST SUCCEEDED **`; QA's independent re-run after a fresh `sync` +
  `xcodegen generate` at `20261122T142159Z-test.log:330` —
  `Executed 81 tests, with 0 failures (0 unexpected) in 840.019 (840.067)
  seconds` — and `:340` — `** TEST SUCCEEDED **`.
- **R1-R15 — pass** in the 81/0 bundle (`20261122T140413Z-test.log`),
  as itemised in `qa/reports/TASK-021-review.md` "Regressions": R9
  `ReceiverStatusTests` 5 (`testPaired`), R10 `AppStateTests` 5
  (`testStatusIsPairedWhenThePairingIsStored`), R15
  `HAPPairVerifyTests`/`HAPServerTests`.
- **R3, R5, R7 — re-run statically this close**, from the workspace root:
  `grep -c 'packages:' play-two/project.yml` → `0`;
  `grep -n 'iOS: "15.0"' play-two/project.yml` → line 13;
  `grep -A1 '^schemes:' play-two/project.yml` → `PlayTwo:`;
  `grep -c 'DEVELOPMENT_TEAM' play-two/project.yml` → `0`;
  `(grep -rnE 'XCTSkip|\.skip' play-two/test || echo 'no skips')` → `no skips`.
- **R6** is a one-off mutation probe, last passed TASK-002, and is not due (the
  display-name contract did not change). **R4's app-level port-7000 half** (the
  A7 browse-then-request-twice check) remains a documented feature-close item in
  the row's separate note; it is not a red row.

## What I ran (this close)

Static, quick checks only — no Mac test re-run, per the brief. From the workspace
root:

```sh
git status --short                                  # M docs/DECISIONS.md only (BA's uncommitted DEC-018); no source/backlog edits by QA
git log --oneline -6                                # HEAD c05b013; FEAT-003 task commits through a453eb9
sed -n '134,145p' play-two/src/HAP/HAPServer.swift  # GET /info, POST /pair-setup, POST /pair-verify, 404
grep -n 'static let response' play-two/src/Net/ReceiverListener.swift || echo 'no match (exit 1)'
grep -c 'packages:' play-two/project.yml            # 0
grep -n 'iOS: "15.0"' play-two/project.yml          # 13
grep -A1 '^schemes:' play-two/project.yml           # PlayTwo:
grep -c 'DEVELOPMENT_TEAM' play-two/project.yml     # 0
(grep -rnE 'XCTSkip|\.skip' play-two/test || echo 'no skips')
grep -n 'static let setupCode' play-two/src/HAP/HAPServer.swift  # 22: "00102003"
grep -n 'Setup code' play-two/src/ContentView.swift             # 26
sed -n '528p;530p;538p' 20261122T140413Z-test.log
sed -n '330p;332p;340p' 20261122T142159Z-test.log
```

The `route` quote that R4 now pins (`play-two/src/HAP/HAPServer.swift:134-145`):

```swift
if request.method == "GET", request.path == "/info" { return Response(status: 200, body: infoBody) }
if request.method == "POST", request.path == "/pair-setup" { return pairSetupResponse(for: request) }
if request.method == "POST", request.path == "/pair-verify" { return pairVerifyResponse(for: request) }
return Response(status: 404, body: Data("Not Found".utf8))
```

## Findings

No finding fails a criterion or a regression. The following are documentation
cleanups for the owners; each has a repro and the smallest acceptable fix.

1. **LOW — PM task text** — `play-two/backlog/tasks/TASK-021-screen-survival.md:47,67`
   (as quoted in `qa/reports/TASK-021-review.md:81`): the verification grep uses
   `play-two/src/HAPServer.swift`, which does not exist. Repro: run that grep →
   `grep: play-two/src/HAPServer.swift: No such file or directory` (exit 1);
   the constant is at `play-two/src/HAP/HAPServer.swift:22`. Fix: correct the path
   in the task text. Already recorded in TASK-021's report.
2. **LOW — PM task text** — `play-two/backlog/tasks/TASK-021-screen-survival.md:49-50`
   (as quoted in `qa/reports/TASK-021-review.md:82`): criterion 4 calls the four
   pre-existing `AppStateTests` "the four from TASK-020"; TASK-020 added an
   AirPlay TXT test. Repro: `git log` on `test/AppStateTests.swift` shows the four
   lifecycle tests predating TASK-020. Fix: reword to "the four existing
   AppStateTests (TASK-006)".
3. **LOW — PM task text** — `play-two/backlog/tasks/TASK-020-txt-sf.md:53-56`
   (as quoted in `qa/reports/TASK-020-review.md:35`): says `ServiceAdvertiserTests`
   runs `Executed 9 tests`; the repo and log both show 4
   (`/tmp/opencode/task-020-test.log:493`). Fix: correct the number to 4, or
   amend the spec and add tests if 9 is authoritative.
4. **OBSERVATION — BA/PM** — `play-two/backlog/BOARD.md:75-79` still carries the
   "Agents run on Tidepool Alpha" and "The Mac is offline" blocker rows; both are
   stale (the Mac is up at macOS 12.7.6 / Xcode 14.2) and `BOARD.md:112-116`
   already lists them for a PM cleanup pass. Fix: remove or mark resolved; no
   code impact.
5. **OBSERVATION — BA** — project `DEC-005` (`play-two/docs/DECISIONS.md:92-104`)
   still names `iPhone 16e`/Xcode 26.6. That is stale against this host
   (`platform=iOS Simulator,name=iPhone 14,OS=16.2` is the only destination). QA
   corrected its own docs; the decision doc is BA-owned and was not touched.
6. **OBSERVATION — QA-owned correction made this close** — `qa/TEST-PLAN.md` A7
   still expected the retired fixed 38-byte reply and used a bare `nc` with no
   request; `HAPServer.handle` cancels an unparsable connection
   (`src/HAP/HAPServer.swift:245-248`), so that check could not pass now. A7 and
   P3 were reworded to send `GET /info` and expect the HTTP 200 JSON body. Not
   re-run here; recorded as a revised check, not an observation.

## Unverifiable here / pending human observation

- **S2a** — the Home app "Add Accessory" result and the phone appearing as a
  speaker. Only the human on the iPhone 6s can do this. Report the exact
  `S2a: …` string from `qa/TEST-PLAN.md`.
- **S2b** — no re-pair prompt after relaunch and the state screen reading
  `Paired`. Only the human can do this. Report the exact `S2b: …` string.
- The provisioning profile expires 2026-11-23 (`play-two/docs/STATE.md:21`,
  `backlog/BOARD.md:85`); re-sign before the observations if it has lapsed.
- Live HTTP wire framing for `/pair-setup` and `/pair-verify` is asserted nowhere
  (TASK-019 "Unverifiable"); the only live-socket test is `GET /info`.
- FEAT-001's S5 `Restart` log line still has no producer (carried gap,
  `qa/TEST-PLAN.md` FEAT-001 "Verification gaps").

## Verdict

**PASS** — code/task level: every agent-verifiable feature criterion has
evidence, all six tasks are PASS, all regressions are green, R4 is reworded per
`DEC-018`, and scope was respected (QA wrote only `qa/**` and `journal/<role>.md`).
S2a and S2b are explicitly **pending human observations** and are **not** claimed
as verified.

**Next:** BA G4 — read this file and the 81/0 logs, commit `play-two/chore: FEAT-003 feature close`,
hand findings 1-4 to PM/BA, and ask the human for the S2a/S2b report strings before
treating S2 as observed.

```text
FEAT-003 HAP pairing endpoints and persistence — PASS (code/task level)
Criteria: 2/4 verified (Regression; all tasks PASS) · S2a/S2b pending human observation
Tasks: TASK-016..021 all PASS (attempt 1)
Regressions: pass (R1-R15; R2 high-water 81 in two independent 81/0 runs; R4 reworded per DEC-018)
Findings: 4 documentation cleanups for BA/PM + 2 observations; none fail a criterion
Unverifiable here: S2a, S2b (human on iPhone 6s); live POST wire framing; A7 app-level reply-twice
Report: qa/reports/FEAT-003-feature-review.md
```
