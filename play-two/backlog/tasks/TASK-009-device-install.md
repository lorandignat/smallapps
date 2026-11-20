---
id: TASK-009
title: Install a signed build on the device
feature: FEAT-001
status: done
attempts: 1
owner: null
depends_on: [TASK-008]
estimate: small
---

# TASK-009 — Install a signed build on the device

## Goal

The device path is repeatable and written down: anyone can rebuild, install and
launch PlayTwo on the iPhone 6s from the commands in `README.md`, and knows the
profile expires on 2026-11-23. This is what lets S1b, S1c and S5 be observed on
the device at all.

## Context for the developer

- Where it lives: `play-two/README.md`, one new section
  `## Running it on the iPhone`.
- Files in scope (1): `play-two/README.md` only.
- The path is already built and already proven by hand; this task documents it,
  it does not design it. `DEC-008` is binding:
  - the signing team lives only in local configuration and is never committed;
    the build passes it to `xcodebuild` as `DEVELOPMENT_TEAM`;
  - device builds and non-simulator tests must run in the Mac's Aqua login
    session: an ssh session cannot reach the login keychain and fails with
    `errSecInternalComponent`, so never tell the reader to run `xcodebuild`
    directly over ssh;
  - install and launch use `ios-deploy` (Homebrew on the Mac) because
    `xcrun devicectl` needs iOS 17 and the 6s runs iOS 15.8.8;
  - the profile `iOS Team Provisioning Profile: com.lorand.playtwo` expires
    **2026-11-23**; the app stops launching after that and a rebuild is the fix.
- The section must contain, in this order: prerequisites that are already true
  (the free Apple ID account, the signing team set in Xcode, the team id in
  local configuration), the commands that sync, build, install and launch the
  app, the expiry date with what to do when it lapses, the device (its UDID,
  name and iOS version), and the note that `devicectl` does not work for iOS 15
  and `ios-deploy` does.
- Explicitly **do not** touch: `src/`, `test/`, `project.yml`, `scripts/`,
  `docs/`, `product/`, `qa/`, `backlog/`, `journal/`, `.opencode/`, and anything
  outside `play-two/`. No `Signing.xcconfig` of any kind, no
  `DEVELOPMENT_TEAM` in `project.yml`.

## Acceptance criteria

1. [ ] Given `play-two/README.md`, when
       `grep -n 'Running it on the iPhone' play-two/README.md` runs, then it
       prints exactly one heading line, the section names `iphoneos`,
       `ios-deploy`, `<udid>` and `2026-11-23`,
       and for each of those four strings
       `grep -c -- '<string>' play-two/README.md` prints a number greater than 0.
2. [ ] Given the committed tree, when
       `git -C play-two grep -nE 'DEVELOPMENT_TEAM *= *[A-Z0-9]{10}'` and
       `git -C /homedir/agent/opencode/apps grep -nE 'DEVELOPMENT_TEAM *= *[A-Z0-9]{10}'`
       run, then both print nothing (exit 1) and `git status --porcelain` stages
       no such line — no team id, certificate id or profile UUID is committed.
3. [ ] Given a synced, generated tree on the Mac and the Aqua session available,
       when `xcodebuild build -scheme PlayTwo -sdk iphoneos` runs, then
       it exits 0, prints `app bundle:` with
       `build/Build/Products/Debug-iphoneos/PlayTwo.app`, and the build log
       carries `Signing Identity:[[:space:]]+"Apple Development: <apple-id>`; a
       signing error (including `errSecInternalComponent`,
       `no signing certificate`, `requires a development team`) is a `FAIL`, an
       unreachable Mac is `BLOCKED`.
4. [ ] Given that bundle, when
       `ios-deploy --bundle build/Build/Products/Debug-iphoneos/PlayTwo.app --id <udid>`
       runs, then it exits 0 and prints `Installed package`.
5. [ ] Given the app is installed, when it is launched on the phone and the human
       reads the screen, then the PlayTwo screen is visible with its receiver
       status text, reported character for character in the TEST-PLAN O1 form; a
       crash, a blank screen, or an app that does not come to the foreground is a
       `FAIL`.

## Verification commands

```sh
# on this host (static, expected green as soon as README is written)
grep -n 'Running it on the iPhone' play-two/README.md
for t in iphoneos ios-deploy <udid> 2026-11-23; do
  printf '%s: ' "$t"; grep -c -- "$t" play-two/README.md
done                                                        # each: > 0
git -C play-two grep -nE 'DEVELOPMENT_TEAM *= *[A-Z0-9]{10}' || echo 'no committed team id'
git -C /homedir/agent/opencode/apps grep -nE 'DEVELOPMENT_TEAM *= *[A-Z0-9]{10}' || echo 'no committed team id'
git status --porcelain | grep -E 'DEVELOPMENT_TEAM' || echo 'nothing staged with a team id'

# on the Mac, through the bridge (never xcodebuild over ssh)
xcodebuild -version
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild build -scheme PlayTwo -sdk iphoneos | tee /tmp/opencode/task-009-build.log
grep -E '\*\* BUILD SUCCEEDED \*\*' /tmp/opencode/task-009-build.log
grep -E 'app bundle:' /tmp/opencode/task-009-build.log
grep -E 'Signing Identity:[[:space:]]+"Apple Development: <apple-id>' /tmp/opencode/task-009-build.log
ios-deploy --bundle build/Build/Products/Debug-iphoneos/PlayTwo.app --id <udid>
ios-deploy --justlaunch --id <udid> --bundle play-two/build/Build/Products/Debug-iphoneos/PlayTwo.app
# Note: this command may exit 1 because ios-deploy's final lldb `safequit`
# returns non-zero, even though `run` printed `success` and the process stayed up.
# Verify aliveness instead with `ios-deploy --list_processes` / `--get_pid`. The
# documented command is otherwise correct.
```

**Expected today:** every line runs. Device command names are by `DEC-008`: bundle
id `com.lorand.playtwo`, device UDID `<udid>`.
build picks `ios-deploy` itself when it is installed and falls back to
`devicectl`, which cannot serve the 6s — if the log shows a `devicectl` error, the
miss is a missing `ios-deploy` on the Mac, reported as `BLOCKED`, not a code
defect.

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-009-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only `play-two/README.md` changed
- [ ] No team id, certificate id or profile UUID in the diff or in `git status`
- [ ] Regression list still passes (R1, R3, R5 in particular)
- [ ] One commit `play-two/TASK-009: document the device install path` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- **The seven-day cliff is a date, not a surprise.** The free-account profile
  expires 2026-11-23 (`DEC-008`). After that the app stops launching until it is
  rebuilt and reinstalled; the README says so next to the commands, with the date,
  so nobody debugs a signature failure that is really an expired profile.
- **`sync` does not generate.** `rsync -a <project> <build-host>:<build-dir>/` rsyncs the tree; the
  `.xcodeproj` is generated on the Mac and is gitignored. `xcodegen generate` must
  follow every `sync` that changes `project.yml` — the README states this in the
  command list rather than in a footnote.
- **The team is not in the tree.** `DEC-008` puts it in local configuration as
  `MAC_TEAM_ID`, outside the project and outside git. Do not add a
  `DEVELOPMENT_TEAM` to `project.yml`, do not create `Signing.xcconfig` or
  `Signing.xcconfig.example`, and do not write the team id, the certificate id or
  the profile UUID into the README, this task or a commit message. The account
  name and the expiry date are documentation, not credentials.
- **Aqua session, not ssh.** build already routes `iphoneos` builds and
  non-simulator tests through the GUI-session runner; an ssh `codesign` fails
  with `errSecInternalComponent`. The README must not offer an ssh `xcodebuild`
  alternative, and this task does not edit `scripts/`.
- **`devicectl` is not the tool for this phone.** It requires iOS 17; the 6s runs
  iOS 15.8.8, so install and launch go through `ios-deploy`. The README says which
  one works and why, or the next person will follow Apple's current
  documentation and conclude the phone is unsupported.
- **Scope.** This task documents the path that has already been proven end to end
  (`** BUILD SUCCEEDED **`, `Installed package`, launch success). It adds no
  product code and no dependency. S1b, S1c and S5 remain the human's observations
  at feature close (TEST-PLAN O1-O5), not criteria of this task.
- Depends on TASK-008 only for build-loop ordering: the log export is what the S5
  observation attaches. Nothing here reads that code.
- **`ios-deploy --justlaunch` may exit 1 and still be a success.** ios-deploy's
  final lldb `safequit` returns non-zero, so `the build bridge run 'ios-deploy
  --justlaunch …'` can return exit 1 even though `run` printed `success` and
  the app process stayed up (PID visible via `ios-deploy --list_processes` /
  `--get_pid`). Treat exit 1 as benign when `success` was printed and the
  process is alive; verify aliveness with `ios-deploy --list_processes` /
  `--get_pid`. The documented command is otherwise correct.
