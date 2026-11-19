---
id: TASK-003-review
task: TASK-003
feature: FEAT-001
verdict: PASS
date: 2026-11-18
attempt: 3
---

# Review — TASK-003 Answer TCP connections on port 7000

Attempt 3, the first under `DEC-011`. Attempts 1 and 2 were `BLOCKED`
(`DEC-010` superseded); nothing was implemented before this one, so this review
covers the whole task.

Everything below was executed by me today on the Mac through
the build bridge, after `check` printed `Xcode 26.6` / `Build version
17F113` (`…/20261118T155840Z-check.log`). The code was read, not taken from the
developer's report: `src/Net/ReceiverListener.swift` stores the port in a
read-only `let port` (`:25`), takes it in `init(port: NWEndpoint.Port =
.init(rawValue: 7000)!)` (`:44`), binds it in `start()` (`:64`) and sends the
constant at `:17` then cancels (`:92-102`). Nothing else in the class moved:
`.failed`/`.waiting` mapping, `allowLocalEndpointReuse`, catch branches and
`stop()` are the previous attempt's code. No call site exists
(`grep -rn 'ReceiverListener(' play-two/src` → none), so the app ships 7000 by
construction and the tests must prove the default separately, which is what
`DEC-011` asks.

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Given a listener on a free port, a client on `127.0.0.1` receives exactly `RTSP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n` with `isComplete == true` within 5 s | **PASS** | Independent runtime capture, not just the test: a probe replaced test 1's expectation with an `XCTFail` that printed the received bytes — `PROBE received-bytes: "RTSP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n" \| length: 38 \| isComplete: true` (`…/20261118T160856Z-test.log`, `/tmp/opencode/qa-probe-received.log`). The source literal at `ReceiverListener.swift:17` is the same string, 38 bytes, counted on this host. Removing `connection.cancel()` from the send completion makes the receive never complete and the test fails at 5 s (`…/20261118T160522Z-test.log`) — the "connection closes" half is load-bearing. |
| 2 | Two client connections made one after the other both receive the full response | **PASS** | Green in six consecutive full-suite runs. The second connection is opened only after the first body arrives (`ReceiverListenerTests.swift:84-95`), so this is genuinely sequential, not two concurrent sockets. A mutant that cancels the listener on the first connection fails exactly this test — `answered only 1 of 2 connections` (`…/20261118T160626Z-test.log`) — so "not single-use" is asserted, not assumed. |
| 3 | Port already bound → `.failed` with the underlying `NWError`, no crash | **PASS** | The blockers bind a free port on `0.0.0.0` and on `::` with `IPV6_V6ONLY` and stay open while the listener starts, so the failure is real and not a free-then-compete race. The run shows the listener's own socket failing: `bind(10, ::.59591) … failed [48: Address already in use]` (`…/20261118T155849Z-test.log`). The test asserts the error is `.posix(.EADDRINUSE)` (`ReceiverListenerTests.swift:132-136`), i.e. the `NWError` itself, and the rest of the suite ran after it — no crash. |
| 4 | After `stop()`, a new connection to `127.0.0.1` is refused within 1 s | **PASS** | Test asserts a pre-stop `.connected`, waits for `.cancelled`, then a blocking `connect()` and requires `.refused` with elapsed `< 1.0` (`ReceiverListenerTests.swift:140-161`). Green in every run. A mutant that turns `stop()` into a no-op fails it three ways: `("connected") is not equal to ("refused")`, `("1.2256…") is not less than ("1.0")`, and the teardown signal never fires (`…/20261118T160737Z-test.log`). |
| 5 | `ReceiverListener()` reports port 7000 — the default is asserted, not assumed | **PASS** | `init` default at `ReceiverListener.swift:44`; `testDefaultPortIs7000` reads `listener.port.rawValue` without starting (so nothing binds 7000). A mutant `7000 → 7001` on the Mac copy fails **exactly** that test (`("7001") is not equal to ("7000")`) while the other four still pass (`…/20261118T160952Z-test.log`) — the assertion bites and the behaviour tests are port-independent. |
| 6 | `ReceiverListenerTests` passes: `Executed 5 tests, with 0 failures` | **PASS** | `Test Suite 'ReceiverListenerTests' passed`; `Executed 5 tests, with 0 failures (0 unexpected)`; whole run `Executed 13 tests, with 0 failures`; `** TEST SUCCEEDED **`, exit 0 (`…/20261118T161156Z-test.log`). Six consecutive green runs of the same command; the five `Test Case … passed` lines are the five intended methods, one per criterion. |

### Anti-accident checks — is each test load-bearing, and can a criterion be green by accident?

All mutants were applied to the **Mac copy only** and restored with `sync` +
`xcodegen generate`; afterwards `src/Net/ReceiverListener.swift` `b576432c…`,
`test/ReceiverListenerTests.swift` `6344dfa1…` and `src/PlayTwoApp.swift`
`55cb0632…a666c5` all equal the repo.

- **Default port changed 7000 → 7001** — only `testDefaultPortIs7000` fails
  (`…/20261118T160952Z-test.log`). Criterion 5's test is load-bearing; criteria
  1-4 do not depend on the default.
- **`connection.cancel()` removed after send** — criteria 1 and 2 fail
  (`Exceeded timeout of 5 seconds … "received the fixed response"`, then
  `answered only 0 of 2`), `Executed 13 tests, with 4 failures`
  (`…/20261118T160522Z-test.log`). The half-open path is caught.
- **Listener made single-use** (cancel the listener in `answer()`) — criterion 2
  fails, criterion 1 still passes (`…/20261118T160626Z-test.log`). The
  "not single-use" assertion is specifically exercised.
- **`stop()` made a no-op** — criterion 4 fails as above, plus the teardown
  guard (`…/20261118T160737Z-test.log`). My first attempt at this mutant did not
  compile (`…/20261118T160724Z-test.log`); the corrected one is the evidence.
- **Independent expectation literal** — test 1's expectation was replaced with a
  43-byte literal (`Content-Length: 5` + `HELLO`): it fails with `("38 bytes") is
  not equal to ("43 bytes")` (`…/20261118T160436Z-test.log`), which shows the
  test compares the bytes actually received, at 38 bytes, rather than something
  it computed.
- **Production reply literal changed** — the converse probe, and the one that
  produced finding 1: replacing `ReceiverListener.response` with a
  `Content-Length: 5` + `HELLO` body leaves the suite **13/13 green**
  (`/tmp/opencode/qa-probe-response2.log`; the first attempt of this probe hit a
  simulator launch failure, `…/20261118T160247Z-test.log`). The test's expectation
  is derived from the constant it is checking, so the suite alone cannot catch a
  drifted reply. The criterion is still met today — the runtime capture above
  fixes the actual bytes at the required 38-byte string — but the assertion is
  weaker than it looks. Finding 1.
- **No test binds 7000.** The only occurrences of `7000` in the test file are the
  assertion at `:44` and comments; `testDefaultPortIs7000` never calls `start()`.
  Cross-check: macOS ControlCenter held `TCP *:7000 (LISTEN)` on IPv4 and IPv6
  while the suite was green, so a test that bound it would have failed with
  `EADDRINUSE` instead of passing (`…/20261118T155414Z-run.log`, developer's run;
  I re-confirmed ControlCenter still owns IPv4 7000 during my session).
- **No skip / opt-out.** `grep -rnE 'XCTSkip|\.skip' play-two/test` → `no skips`
  (R5).
- **Port release between tests.** `tearDown` stops every tracked listener and
  waits for `.cancelled` through a latched `DispatchGroup`, not an expectation
  that has already been waited on (`ReceiverListenerTests.swift:24-36,430-453`).
  Six back-to-back runs with no port carry-over support that.

### Flakiness

Six runs of the plain task command were green. Two of roughly twelve simulator
invocations, however, never reached the tests: `Simulator device failed to
launch com.lorand.playtwo … Application failed preflight checks` (FBS
`Busy`), once with `-test-iterations 10` (`…/20261118T155946Z-run.log`) and once
on the mutant run above (`…/20261118T160247Z-test.log`). Each time the simulator
was `Shutdown`, no `xcodebuild` was left running, and the identical command
passed on the next attempt. This is host launch flakiness, not test logic —
recorded as finding 2, not as a defect in this task. The `freePort()` window
(bind 0, close, hand the number to the listener) is a real but tiny race; I saw
no failure attributable to it in six runs, and criterion 3 avoids it by keeping
its blockers bound.

## What I ran

From `/homedir/agent/opencode/apps`; logs under ``.

```sh
$ xcodebuild -version                                   # exit 0
26.6.2 / arm64 / Xcode 26.6 / Build version 17F113

$ rsync -a <project> <build-host>:<build-dir>/                           # exit 0
$ xcodegen generate   # exit 0

$ ls play-two/src/Net                                            # ReceiverListener.swift
$ grep -n 'RTSP/1.0 200 OK' play-two/src/Net/ReceiverListener.swift   # :17
$ grep -n 'rawValue: 7000' play-two/src/Net/ReceiverListener.swift    # :44
$ python3 -c "print(len('RTSP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n'))"   # 38

$ xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e'
Test Suite 'ReceiverListenerTests' passed …  Executed 5 tests, with 0 failures
Test Suite 'AirPlayTXTRecordTests' passed …  Executed 7 tests, with 0 failures
Test Suite 'AppInfoTests' passed …           Executed 1 test,  with 0 failures
	 Executed 13 tests, with 0 failures ; ** TEST SUCCEEDED **   # exit 0
# six green runs: …155849Z, …160043Z, …160112Z, …160134Z, …160154Z, …160214Z,
# final …161156Z-test.log

# probes, Mac copy only, each restored by sync + xcodegen afterwards
$ … python3 mutate_test_expectation.py && xcodebuild test …
XCTAssertEqual failed: ("38 bytes") is not equal to ("43 bytes")      # …160436Z
$ … python3 mutate_no_cancel.py && … test …                             # …160522Z
XCTAssertEqual failed: ("0") is not equal to ("2") / wait timed out
$ … python3 mutate_single_use.py && … test …                            # …160626Z
answered only 1 of 2 connections
$ … python3 mutate_stop_noop.py && … test …                             # …160737Z
("connected") is not equal to ("refused") ; 1.2256… not less than 1.0
$ … python3 mutate_default_port.py && … test …                          # …160952Z
("7001") is not equal to ("7000") ; the other four still pass
$ … python3 probe_received_bytes.py && … test …                         # …160856Z
PROBE received-bytes: "RTSP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n" | length: 38 | isComplete: true
$ … python3 mutate_response.py && … test …                              # exit 0, 13/13
# finding 1: a changed reply literal does not fail the suite

$ … shasum -a 256 src/Net/ReceiverListener.swift test/ReceiverListenerTests.swift \
      src/PlayTwoApp.swift
b576432c… / 6344dfa1… / 55cb0632…a666c5   # all = repo
```

## Scope

`git status --porcelain play-two` at review start:

| File | Owner | Verdict |
| --- | --- | --- |
| `src/Net/ReceiverListener.swift` | developer | in scope (2 allowed files) |
| `test/ReceiverListenerTests.swift` | developer | in scope |
| `journal/<role>.md` | developer | required by `PROCESS.md` §5 step 10; the task file's "do not touch `journal/`" line contradicts the process and the ownership table, which is a documentation defect, not a scope breach (see finding 2's sibling note below) |
| `backlog/BOARD.md`, `backlog/tasks/TASK-003-tcp-listener.md` | BA | the attempt-3 re-cut (`in-review`, `attempts: 3`), not the developer's |

`project.yml` untouched; no dependency, no `src/AirPlay/`, no `src/PlayTwoApp.swift`,
no `docs/`, no `scripts/`. The generated project picked both files up: the run
executed five listener tests, which it could not do otherwise. My only writes
are inside `play-two/qa/` and `play-two/journal/<role>.md`.

No `qa/reports/TASK-003-review.md` exists for attempts 1-2; their `BLOCKED`
findings live only in the task's rework log and `BOARD.md`. Not a defect of this
attempt — noted so the record is not assumed to exist.

### Developer report check

The report's claims check out against the files and logs, with one wording slip:
"`git status play-two` lists exactly those three" — at review time it also lists
the BA's `BOARD.md` and task-file re-cut edits, which the developer did not make.
Their two deliberate oddities are real and correctly explained: the red
`…/20261118T155205Z-test.log` fails with `expectations can only be waited on
once` and `Failed due to unwaited expectation 'listener reports cancelled'`, and
the final green is `…/20261118T155630Z-test.log` (`Executed 13 tests, with 0
failures`). Their note that R4's "43-byte" wording was wrong is correct: the
literal is 38 bytes.

## Findings

1. **MINOR (test quality)** — `play-two/test/ReceiverListenerTests.swift:66-70,99-101`
   compare the received bytes against `Data(ReceiverListener.response.utf8)`,
   i.e. the same constant the listener sends. Changing the production reply
   literal to `Content-Length: 5\r\n\r\nHELLO` leaves the suite **13/13 green**
   (`/tmp/opencode/qa-probe-response2.log`; first attempt of the probe failed at
   simulator launch, `20261118T160247Z-test.log`). The criterion
   is still met — my independent-literal probe fixes the actual bytes at
   `RTSP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n`, 38 bytes, `isComplete: true`
   (`20261118T160856Z-test.log`) — but the *test* can be
   satisfied by accident. Reproduce: apply that one-line change to the Mac copy
   and run the suite. Smallest acceptable fix: put the literal string in test 1,
   e.g. `XCTAssertEqual(Data("RTSP/1.0 200 OK\r\nContent-Length: 0\r\n\r\n".utf8),
   body.value)` (test 2 may keep the constant, or reuse a file-private literal).
   No production change. Mitigated for now by R4, which pins the literal with a
   `grep` so a drift fails the regression list even while this test would not.
2. **MINOR (flaky runner)** — 2 of ~12 simulator invocations died at launch:
   `Simulator device failed to launch com.lorand.playtwo … Application failed
   preflight checks` (`…/20261118T160247Z-test.log`, `…/20261118T155946Z-run.log`).
   Not test logic (the identical command passes immediately after, the simulator
   was `Shutdown`, no stale `xcodebuild`), but it perturbs the suite; needs a
   record-and-retry note, not a code change.

One documentation inconsistency, not a finding against the developer:
`backlog/tasks/TASK-003-tcp-listener.md:35-37` lists `journal/` under "Explicitly
do not touch", while `docs/PROCESS.md` §5 step 10 requires the developer to
append `journal/<role>.md` and the ownership table gives that file to them. The
developer did the process-correct thing; PM should narrow the exclusion to
"journals other than `journal/<role>.md`" when the task is next touched.

## Regressions

From `qa/REGRESSION.md`, run today on this host and the Mac:

| ID | Result |
| --- | --- |
| R1 | **PASS** — `sync` → `xcodegen generate` → `build … iphonesimulator`, exit 0, `** BUILD SUCCEEDED **`, app at `build/Build/Products/Debug-iphonesimulator/PlayTwo.app`, `ls -d` on the Mac confirms it (`…/20261118T161046Z-build.log`). |
| R2 | **PASS, high-water raised 8 → 13** — exit 0, `Executed 13 tests, with 0 failures` (`ReceiverListenerTests` 5 + `AirPlayTXTRecordTests` 7 + `AppInfoTests` 1), six consecutive green runs, final `…/20261118T161156Z-test.log`. The stale 8 and the log list were corrected in `qa/REGRESSION.md` this turn. |
| R3 | **PASS** — static: `packages:` 0, `iOS: "15.0"` at `project.yml:13`, scheme `PlayTwo`, `DEVELOPMENT_TEAM` 0. Generated: targets `PlayTwo`/`PlayTwoTests`, scheme `PlayTwo`, `IPHONEOS_DEPLOYMENT_TARGET = 15.0` ×2 (`…/20261118T161059Z-run.log`). |
| R4 | **PASS for the unit half, rewritten this turn** — five listener tests green on a free port (reply + `isComplete`, two sequential connections, `.failed`/`EADDRINUSE`, refusal within 1 s, default 7000) and the 38-byte literal pinned at `ReceiverListener.swift:17` by `grep` (`…/20261118T161156Z-test.log`, runtime bytes from `…/20261118T160856Z-test.log`). The row no longer says "43 bytes" and no longer assumes a Mac loopback check against 7000; the app-level 7000 observation is deferred to TASK-004 / feature close per `DEC-011`. |
| R5 | **PASS** — `grep -rnE 'XCTSkip\|\.skip' play-two/test` → `no skips`; `.gitignore:2` `*.xcodeproj/`, `:5` `build/`; no generated file tracked. |
| R6 | **PASS** — re-run because the suite changed: `AppInfo.displayName` → `"Mutant"` on the Mac copy → exit 1, `XCTAssertEqual failed: ("Mutant") is not equal to ("PlayTwo")`, `Executed 13 tests, with 1 failure`, listener tests still 5/5 (`…/20261118T161106Z-test.log`); restored by `sync` + `xcodegen`, sha256 `55cb0632…a666c5` = repo. |
| R7 | **PASS** — no `AirPlayReceiver` in `project.yml`/`src`/`test`; `bundleIdPrefix` 0; `CFBundleDisplayName` 0; both generated plists ignored at `play-two/.gitignore:8-9`. |
| R8 | **PASS** — 7/7 `AirPlayTXTRecordTests … passed`, constant at `AirPlayTXTRecord.swift:23`, bit 38 `True`. |

No regression failed, and none is `BLOCKED`.

## Unverifiable here / not covered

- **The app serving the real port 7000.** `DEC-011` moves this out of TASK-003:
  nothing constructs `ReceiverListener` yet (no call site in `src/`), so no
  process binds 7000. It is an app-level observation once TASK-004 wires the
  listener: `qa/TEST-PLAN.md` A7 (`nc -w 5 <host> 7000 \| xxd` twice, against the
  host A6 resolves) and R4's deferred half. The unit suite proves the same code
  path on a free port; it does not prove 7000.
- **iOS 15.0 runtime.** The simulator is iPhone 16e / iOS 26.5 (`DEC-005`); 15.0
  is a compile-time and deployment-setting promise (R3), never runtime evidence.
  Only the iPhone 6s gives that.
- **The Apple TV speaker list and the device path.** Human only (O2-O5), not part
  of this task.
- Nothing else in this task touches a device, network or credential; every
  criterion was executed, not inferred.

## Traceability — FEAT-001 S1d

**S1d is not closed by TASK-003 and must not be marked closed at G4.** S1d is
written at app level ("the app … connects to the phone's port 7000"). This task
delivers the listener class and proves its behaviour on a free ephemeral port;
nothing in the app constructs it (`grep -rn 'ReceiverListener(' play-two/src` →
none), so no app process listens on 7000 yet. S1d closes when TASK-004 wires the
listener into the app and the A7 network check answers twice on the real port,
then again at feature close. `DEC-011` says exactly this; the unit suite is not
substitute evidence for it.

## Verdict

All six criteria have Mac-produced evidence, including a runtime capture of the
exact reply bytes and `isComplete`, and four mutants showing the tests bite on
the default port, the connection close, the second connection and `stop()`. The
regression list is green, with R2 corrected to 13 and R4 rewritten for the
free-port path. Two MINOR findings: the reply assertion derives its expectation
from the constant under test (mitigated by R4's literal grep and to be fixed in
the test when convenient; no criterion affected), and the simulator host
intermittently fails to launch the app, needing a retry rather than a code
change.

**Verdict:** PASS

**Next:** BA commits the two in-scope files under `play-two/TASK-003: answer TCP
connections on port 7000`, marks the task `done`, and keeps FEAT-001 S1d open
for TASK-004. Developer: nothing to rework; optionally pin the reply literal in
`testConnectionReceivesTheFixedResponseAndTheReceiveCompletes` (finding 1).
