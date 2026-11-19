---
id: TASK-009
title: Install a signed build on the device
feature: FEAT-001
status: blocked
attempts: 0
owner: null
depends_on: [TASK-008]
estimate: small
---

# TASK-009 — Install a signed build on the device

## Goal

`xcodebuild build … iphoneos`, `install` and a launch put the app on the
iPhone 6s, with the signing team supplied by a gitignored local file so that
`project.yml` stays free of machine-specific values — this is what lets S1b, S1c
and S5 be observed on the device at all.

## Context for the developer

- Where it lives: `project.yml` (XcodeGen project settings), a new
  `Signing.xcconfig.example`, `.gitignore`, and the run instructions in
  `README.md` ("Running it").
- Interfaces it may touch: nothing in `src/` or `test/` — this task adds no
  product code and no dependency.
- Files in scope (4): `project.yml`, `Signing.xcconfig.example` (new),
  `.gitignore`, `README.md`.
- Shape: `project.yml` points its configurations at `Signing.xcconfig` (XcodeGen
  `configFiles`, or an equivalent that the developer can justify in the commit
  body); `Signing.xcconfig` is gitignored and holds the one line
  `DEVELOPMENT_TEAM = <TEAM_ID>`; `Signing.xcconfig.example` is committed with the
  placeholder only and the README says `cp Signing.xcconfig.example
  Signing.xcconfig`, then edit that one line.
- An empty `DEVELOPMENT_TEAM` must still build for `iphonesimulator`, so the
  existing A2-A3 path (TASK-001) keeps working with the local file present but
  unfilled. If XcodeGen cannot generate while `Signing.xcconfig` is absent, say so
  in the README as step 0 (`cp` before `xcodegen generate`) — the copy step is
  documented, not hidden.
- Explicitly **do not** touch: `src/`, `test/`, `scripts/`, `docs/`, `product/`,
  `qa/`, `journal/`, `.opencode/`, `../../docs/`, `../../templates/`, and never
  the workspace `.gitignore` or the build bridge.

## Acceptance criteria

1. [ ] Given the tree, when `grep -n 'Signing.xcconfig' project.yml` runs, then
       it finds the configuration reference, and
       `grep -c 'DEVELOPMENT_TEAM' project.yml` prints `0` — the team is read
       only from the local file, so `qa/REGRESSION.md` R3 and TEST-PLAN A9 stay
       green.
2. [ ] Given only the committed files, when `cp Signing.xcconfig.example
       Signing.xcconfig` runs (the team value may stay the placeholder — the
       human's real id arrives with `QQ-008`), then
       `git check-ignore -v play-two/Signing.xcconfig` names
       `play-two/.gitignore`, `git status --porcelain` shows no
       `Signing.xcconfig` line, and `git grep -nE 'DEVELOPMENT_TEAM *= *[A-Z0-9]{10}' -- play-two`
       prints nothing — no credentials in the repository.
3. [ ] Given a `Signing.xcconfig` with a real team id, when
       `xcodebuild build -scheme PlayTwo -sdk iphoneos`
       runs, then it exits 0 and prints
       `app bundle: …/build/Build/Products/Debug-iphoneos/PlayTwo.app`; a
       signing failure (`no signing certificate`, `requires a development team`)
       is a `FAIL` of this task, a missing Mac (`QQ-005`) is `BLOCKED`.
4. [ ] Given that bundle and the UDID printed by
       `xcrun devicectl list devices`, when
       `ios-deploy --bundle build/Build/Products/Debug-iphoneos/PlayTwo.app --id <udid>`
       runs, then it prints `ok — log:` and
       `xcrun devicectl device info apps --device <udid>` lists `<bundle-id>`.
5. [ ] Given the app is installed, when it is launched on the phone, then the app
       is foregrounded (a pid, not a crash) and its only screen shows the
       receiver status text, reported character for character — e.g.
       `Advertising as PlayTwo`; a launch that crashes or shows no
       status text is a `FAIL`.

## Verification commands

```sh
# on this host (static, works today once the files exist)
grep -n 'Signing.xcconfig' play-two/project.yml
grep -c 'DEVELOPMENT_TEAM' play-two/project.yml        # expected: 0
ls play-two/Signing.xcconfig.example
grep -n 'Signing.xcconfig' play-two/.gitignore
grep -nE 'Signing\.xcconfig|install|devicectl' play-two/README.md
git -C play-two grep -nE 'DEVELOPMENT_TEAM *= *[A-Z0-9]{10}' -- . || echo 'no committed team id'
git -C play-two check-ignore -v Signing.xcconfig || echo 'NOT ignored'

# on the Mac (signing steps BLOCKED until QQ-008 resolves)
xcodebuild -version
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild build -scheme PlayTwo -sdk iphoneos
xcrun devicectl list devices
ios-deploy --bundle build/Build/Products/Debug-iphoneos/PlayTwo.app --id <udid>
xcrun devicectl device info apps --device <udid> | grep -i play-two
xcrun devicectl device process launch --device <udid> <bundle-id>
```

`<udid>` is copied from `devicectl list devices`; `<bundle-id>` is the identifier
declared for the `PlayTwo` target in `project.yml` — read both, never
guess. Criterion 5's screen text is the human's line, in the TEST-PLAN O1 form.

**Expected today:** `QQ-005` is resolved, so the build lines up to
`build … iphoneos` run; the signing-dependent ones are `BLOCKED` on `QQ-008` for
the signing team. `BLOCKED` is recorded with the exact error line, never counted
as `FAIL`.

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-009-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only the four files listed above changed
- [ ] `Signing.xcconfig` is absent from `git status` and from the diff
- [ ] Regression list still passes (R3, R5 in particular)
- [ ] One commit `play-two/TASK-009: install a signed build on the device` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- **BLOCKED until `QQ-008` is answered:** which Apple ID / development team signs
  device builds, and whether it is the free (7-day) or paid (1-year) account. Do
  not guess a team id and do not ask for credentials. The default if the question
  stays unanswered is the free account: a 7-day profile and a re-sign routine;
  when the answer arrives, record the profile's expiry date in `README.md` so the
  re-sign step is a date, not a surprise.
- Signing credentials are never committed: no team id in `project.yml`, `README.md`,
  this task, a journal or a commit message. Only the placeholder in
  `Signing.xcconfig.example`.
- `sync` rsyncs the project directory minus `.git/`, `build/` and friends, so the
  untracked `Signing.xcconfig` **does** reach the Mac. That is intended — do not
  add an rsync exclusion for it, and do not edit the build bridge.
- If the Mac cannot create the profile headlessly, the human's one-time Xcode step
  (TEST-PLAN O1: open the generated project, pick the team, let Xcode create the
  profile) is the documented fallback. Record it as `BLOCKED (QQ-008)`, not as a
  code defect, and re-run `build`.
- Scope: this task makes the device reachable; it does not touch the
  advertisement, the listener or the UI. S1b/S1c/S5 themselves are the human's
  observations (TEST-PLAN O1-O5), verified at feature close, not here.
- Depends on TASK-008 only for build-loop ordering: the project is stable and the
  log export is what the S5 observation attaches. Nothing in this task reads the
  export code.
