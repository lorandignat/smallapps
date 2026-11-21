# DECISIONS

One entry per decision that someone might later ask "why?". Append only; reverse
a decision with a new entry, never by editing the old one.

Format:

```md
## DEC-001 — <title>
- date: YYYY-MM-DD
- status: proposed | accepted | superseded by DEC-###
- owner: ba
- context: what forced a choice
- decision: what we chose
- consequences: what it costs, what it enables
```

---

## DEC-001 — BA is the single dispatcher

- date: 2026-11-15
- status: accepted
- owner: ba
- context: Four roles need to cooperate. OpenCode subagents can launch
  subagents, but deep nesting multiplies context loss and makes blame
  ambiguous.
- decision: Only the BA launches subagents: `ba → pm`, `ba → developer`,
  `ba → qa`. PM and QA never dispatch; the human never addresses anyone but
  the BA.
- consequences: one clear chain of custody, shallow nesting, and every task has
  a single accountable owner at each moment. Cost: the BA's context grows over a
  long run, mitigated by disk state.

## DEC-002 — Only tester-approved work counts as done

- date: 2026-11-15
- status: accepted
- owner: ba
- context: Agents tend to declare success on their own work.
- decision: `done` requires a `PASS` verdict from `qa` recorded in
  `qa/reports/TASK-###-review.md`, plus BA gate G4. Developer self-reports are
  advisory only.
- consequences: slower per task, trustworthy state.

## DEC-003 — One task per developer invocation

- date: 2026-11-15
- status: accepted
- owner: ba
- context: Batch work produces unreviewable diffs and untraceable failures.
- decision: Developer receives exactly one task ID per launch and never starts
  a second task. Task size is enforced upstream by PM atomicity rules (≤ one
  behavior, ≤ ~30 minutes of work, single commit).
- consequences: many small commits; predictable diffs; easy rollback.

## DEC-004 — iOS toolchain deferred

- date: 2026-11-15
- status: accepted
- owner: ba
- context: The build host is Linux with no Xcode and no root. iOS binaries can
  only be produced on macOS or a macOS CI runner.
- decision: No app language toolchain is installed yet. Options and their costs
  are documented in `docs/PLATFORM.md`; each project records its stack in
  `docs/STACK.md` at intake.
- consequences: intake must settle the stack before Phase 1 breakdown.

## DEC-005 — One repository, many projects

- date: 2026-11-15
- status: accepted
- owner: ba
- context: Several apps are planned. Splitting into repositories now would add
  per-repo process duplication and make shared tooling awkward; splitting later
  should still be cheap.
- decision: A single git repository at the workspace root, one directory per
  project, shared `.opencode/` agents and skills. All project artifacts live
  inside the project directory; shared documents live in `docs/`.
- consequences: one toolchain and one place to look for process; commits are
  prefixed with the project name. Moving a project out later means copying its
  directory and re-initialising a remote, because no project artifact depends on
  a path outside it.

## DEC-006 — Environment changes are recorded once, at workspace level

- date: 2026-11-15
- status: accepted
- owner: ba
- context: With several projects, per-project install logs duplicate the same
  toolchain facts and rot independently.
- decision: one environment log holds the installs, downloads and host-visible
  changes, with one section per project for project-specific dependencies.
  Lockfiles remain the source of truth for the exact versions a project builds
  with. The log names local paths and accounts, so it is kept out of this
  repository.
- consequences: the developer owns one file instead of N; a project moved to its
  own repository must copy its section with it.

## DEC-008 — The repository is published as `smallapps`

- date: 2026-11-16
- status: superseded by `DEC-009`
- owner: ba (human decision)
- context: the workspace was built local-only on purpose (`git push` is denied to
  every agent). The human wants it on GitHub under a name that fits what it is: a
  monorepo of small apps, one of which is PlayTwo.
- decision: the repository is `smallapps`. Only the human adds the remote and
  pushes; agents keep the `git push` denial. What actually gets published is
  `DEC-009`.

## DEC-009 — The public repository is a sanitised snapshot, not the history

- date: 2026-11-17
- status: superseded by `DEC-013`
- owner: ba (human decision)
- context: `DEC-008` assumed the whole history could be published as it stands.
  It cannot: the history carries the build host's address and account, the Mac's
  scratch paths and the role journals, which are working notes rather than
  product. The human's rule is simple — the Mac path and the Mac address are
  never committed, and the way the Mac is driven does not need to be public.
- decision: `smallapps` is published from an orphan branch built by a script in
  `.tooling/` (gitignored), from the current tree. The snapshot is the app source
  plus the spec, backlog, QA plan and process documents. The build bridge, the
  install log, the role journals, the per-task QA transcripts and every host,
  device and account identifier are removed or replaced with a placeholder such
  as `<build-host>`, `<udid>` and `<apple-id>`. The branch holds one commit with
  no ancestors, so no earlier commit can carry what was removed. The private
  repository stays the source of truth; agents never push; the human adds the
  remote and pushes.
- consequences: the public repository cannot reproduce the private workspace
  exactly, because the bridge is not in it — that is intended. Republishing is a
  re-run of the snapshot script, not a rebase. `DEC-008`'s "full history" and
  "the Apple ID stays" no longer hold; its naming decision still does.

## DEC-013 — Publish the history, scrubbed commit by commit

- date: 2026-11-19
- status: accepted
- owner: ba (human decision)
- context: `DEC-009` published one orphan commit, so three days of work appeared
  as a single "Initial import". The human wants the repository to show how the
  app, the agents and the requirements evolved. Scrubbing the tree is already
  solved; what was missing was scrubbing each commit rather than the final state.
- decision: `make-history.sh` replays every commit on `main` in order, applies the
  same rules to each tree, scrubs each commit message with the same patterns, and
  re-commits with the original message, subject and date. A commit whose tree is
  unchanged after scrubbing is dropped, so the public log carries no empty
  commits. The result is `public-history`, pushed as `main`. Authorship is the
  human's, as in the snapshot. The private repository remains the source of
  truth; `main` is never rewritten or pushed.
- consequences: the public log now shows 55 commits from 2026-11-15 onward —
  spec, decisions, agent definitions, task cuts, verdicts and code — each with
  the date it happened. The journals remain private, so the reasoning behind a
  commit is summarised by its message, not published verbatim. Republishing is
  `make-history.sh` plus a force-push, which rewrites the public history each
  time; that is acceptable because the public repository is generated.

## DEC-014 — Build agent may push only the scrubbed public-history ref

- date: 2026-11-20
- status: accepted
- owner: ba
- context: The human wants the build loop to publish without a manual step,
  but raw `main` contains team ids, Mac paths, UDIDs, `ENVIRONMENT.md`
  references and other material that must never reach the public repository.
  The scrubbed-history pipeline (`make-history.sh`, DEC-013) exists to prevent
  that leak.
- decision: The developer (build) agent may run `git push`, but only the
  scrubbed ref produced by `.tooling/publish/make-history.sh`
  (`public-history` → `origin/main`). It must never push raw `main`, never
  add a remote, and never bypass the scrubbing step. The BA (and the other
  agents) still never push. Publishing the private working branch anywhere
  remains the human's decision.
- consequences: The build loop can publish a release candidate unattended, but
  only through the scrubbing pipeline; the leak protection is preserved. The
  developer agent's instructions and PROCESS.md §7 carry the constraint in
  writing.

## DEC-015 — The GUI-session helper runs via `sh`, not `chmod +x`

- date: 2026-11-20
- status: accepted
- owner: ba
- context: The Mac is flagged as a "remote SSH-driven workflow: used base64 -d to
  create /private/tmp/mac-gui-run.sh; added executable permission with
  `chmod +x`; executed the new temporary script; passed a Base64-encoded command
  to it" (hobby project; the user doesn't like that pattern).
- decision: The executable bit is never needed: the GUI-session runner writes
  `run.sh`, and the LaunchAgent in the private build notes runs it as
  `/bin/sh "$work/run.sh"` (the GUI-session runner:49`); the inner command is
  also run via `/bin/sh "$work/cmd.sh"` (the GUI-session runner:37`). So
  `chmod +x "$work/run.sh"` (the GUI-session runner:42`) is removed, and
  `scripts/mac-build.sh:123` now runs `sh /tmp/mac-gui-run.sh '$b64'` instead of
  `chmod +x /tmp/mac-gui-run.sh; /tmp/mac-gui-run.sh '$b64'`. The base64 wire
  format is unchanged; only the exec bit is gone.
- consequences: No `chmod +x` executes on the Mac during any build GUI
  command. If some future platform/setup requires the helper to be executable,
  re-add the bit — but not here.

## DEC-016 — xcodegen is staged under `.tooling/` on the build host

- date: 2026-11-21
- status: accepted
- owner: ba
- context: The build host moved to a MacBook Pro 2015 on macOS 12.7.6 (Xcode
  14.2). `xcodegen` is not installed there, Homebrew 3.6.4 has no bottle for
  macOS 12, and the project's `.xcodeproj` is generated, not committed. The
  workspace rule is that toolchains live in `.tooling/`, not in the machine.
- decision: Vendor the upstream release `xcodegen.zip` **2.38.0**
  (`yonaskolb/XcodeGen`, sha256
  `aed5bedc80979058287d46b292d3118f89a4cec8e7f1f2ff849e190948c9cd7e`; x86_64
  slice minimum macOS 10.13) at `<build-dir>/.tooling/xcodegen/` on the build host
  — i.e. inside the synced workspace copy, not in `/usr/local` and not via
  `brew`. the build bridge prepends `<build-dir>/.tooling/xcodegen/bin` to
  `PATH`, so every existing `xcodegen generate` command works unchanged.
- consequences: Replacing the build host only needs the same unzip plus the
  checksum; nothing on the Mac is installed system-wide. Upgrading xcodegen
  means bumping the version and checksum in this record, and only after a
  release whose minimum macOS is <= 12.7.6 has been confirmed from the Mach-O
  load command.
