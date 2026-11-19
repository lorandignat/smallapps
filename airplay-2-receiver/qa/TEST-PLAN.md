# TEST PLAN — AirPlay 2 Receiver

Owner: `qa`. One section per feature, written before the first task of that
feature is verified. Concrete enough that the BA can check tasks against it.

Every check below is either a command (quoted verbatim, run from the workspace
root) or a numbered human procedure with the exact string to report back. A
criterion with neither is a gap, and gaps are listed as gaps.

---

## FEAT-001 — Discoverable AirPlay 2 receiver

Traces to `product/SPEC.md` S1 and S5, through `FEAT-001` S1a-S1d. The feature is
increment 1 of `DEC-002` and the project's kill-switch.

**Feature demo:** with the app foregrounded on the iPhone 6s, (1) the state
screen reads `Advertising as AirPlay Receiver` with no error, and (2) the Apple
TV's AirPlay speaker list contains `AirPlay Receiver` within 30 seconds; killing
the app removes the entry, and the next launch offers exactly one entry again
with a matching log line.

### Environment

Nothing iOS executes on this Linux host: no Swift, no Xcode, no simulator, no
`dns-sd`. Every build, test and simulator run happens on the human's Mac through
the build bridge (contract: the private build notes), and every device
observation is the human looking at the iPhone and the Apple TV (`docs/STACK.md`,
"What cannot be verified on this host").

Preamble for every review, from the workspace root:

```sh
xcodebuild -version          # read the "== xcode ==" block — see A1
rsync -a <project> <build-host>:<build-dir>/ airplay-2-receiver
xcodegen generate
```

`sync` does not run `xcodegen`, and `.xcodeproj` is gitignored, so a `project.yml`
edit without the third line fails `build`/`test` with `no .xcodeproj or
.xcworkspace`. That failure is a process step missed, not a code defect.

Run `xcodegen generate` after **every** `sync`, not only after a `project.yml`
change: `sync` is `rsync --delete` and the generated `.xcodeproj`, `src/Info.plist`
and `test/Info.plist` exist only on the Mac, so each sync removes them. Observed
on TASK-001 round 2 (2026-11-16): after `sync`, `ls -d *.xcodeproj` → `zsh:1: no
matches found: *.xcodeproj`, and both plists were absent.

**The Mac bridge is up since 2026-11-16** (`check` exits 0: macOS 26.6.2, Xcode
26.6, iOS 26.5 SDK). The simulator is `iPhone 16e`, not `iPhone 16` (`DEC-005`);
the literal `iPhone 16` destination fails with `xcodebuild: error: Unable to find
a device matching the provided destination specifier`, verified on TASK-001.

**BLOCKED looks like this here**, and it is never PASS and never FAIL: the
command prints `error: missing .../local configuration, `cannot reach
<user>@<host> over ssh`, `no .xcworkspace or .xcodeproj in <dir>` (exit 1), or
`xcodebuild: error: Unable to find a device matching the provided destination
specifier` (wrong simulator name — use `iPhone 16e`). Record the exact error line
and the `*.log` path in the review. Today the bridge is up, so
any of these is a real failure of the bridge or of the tree, not the expected
state.

### Automated checks

`<bundle-id>` is the identifier declared for the `AirPlayReceiver` target in
`project.yml`; read it, do not guess.

| # | Command | Proves | Covers |
| --- | --- | --- | --- |
| A1 | `xcodebuild -version` — then read the `== xcode ==` block for a line matching `^Xcode [0-9]` | the Mac bridge works **and** Xcode exists. Exit 0 alone does not: `check` runs `xcodebuild -version … \|\| true`, so a missing Xcode still exits 0 | enabler for A2-A8 |
| A2 | `xcodebuild build airplay-2-receiver AirPlayReceiver iphonesimulator` | the tree compiles for the simulator and produces `build/Build/Products/Debug-iphonesimulator/AirPlayReceiver.app` | R1; TASK-001 c2 |
| A3 | `xcodebuild test airplay-2-receiver AirPlayReceiver 'platform=iOS Simulator,name=iPhone 16e' \| tee /tmp/opencode/feat-001-test.log` then `grep -E "Executed [0-9]+ tests?, with 0 failures" /tmp/opencode/feat-001-test.log` | every unit test green, and the count is at least the high-water mark: 1 after TASK-001, 6/10/13/17/21/25/28 as TASK-002…008 land | R2; every task's "Executed N tests" criterion |
| A4 | `xcrun simctl boot "iPhone 16e" \|\| true; xcrun simctl bootstatus "iPhone 16e" -b; xcrun simctl install booted <build-dir>/airplay-2-receiver/build/Build/Products/Debug-iphonesimulator/AirPlayReceiver.app` then `xcrun simctl launch booted <bundle-id>` | the app runs and is foreground — `simctl launch` prints `<bundle-id>: <pid>`; a pid is the evidence, a bare error means the app is not running and an empty browse proves nothing | prerequisite for A5-A8 |
| A5 | `dns-sd -B _airplay._tcp . > /tmp/ap2-b.txt 2>&1 & BP=$!; sleep 1; xcrun simctl terminate booted <bundle-id> 2>/dev/null; echo "T0 $(date -u +%H:%M:%S)"; xcrun simctl launch booted <bundle-id>; sleep 30; kill $BP 2>/dev/null; grep " Add " /tmp/ap2-b.txt \| sed -E "s/.*_airplay\._tcp\.[[:space:]]+//" \| sort -u` — expect exactly one line reading `AirPlay Receiver`, and its first `Add` timestamp within 30 s of `T0` | **S1a**: the app registers the service over real mDNS, once, under the app's name, within the deadline. Count **by name**, not by type: the Apple TV and any HomePod publish `_airplay._tcp` too | S1a |
| A6 | `dns-sd -L "AirPlay Receiver" _airplay._tcp . > /tmp/ap2-l.txt 2>&1 & BP=$!; sleep 3; kill $BP 2>/dev/null; cat /tmp/ap2-l.txt` — expect `can be reached at <host>:7000` and the TXT keys `deviceid`, `features` (64-bit, bit 38 set), `model`, `srcvers`, `vv=2` | the instance resolves to a host and the TXT record from TASK-002 reached the wire intact | S1a; TASK-002 c2; TASK-004 c1-c2 at network level |
| A7 | `nc -w 5 <host> 7000 \| xxd` twice in a row, `<host>` taken from A6 | **S1d**: a sender that found us gets exactly `RTSP/1.0 200 OK`, `Content-Length: 0`, an empty body, and the connection closes (the `nc` returns before its 5 s deadline); the second call answers identically (not single-use). On the simulator `<host>` is the Mac — that proves listener + registration linkage only; on the device it is the LAN path, which is the evidence that matters | S1d; TASK-003 c1-c2 |
| A8 | From A5's running state: `xcrun simctl launch booted com.apple.Preferences` (backgrounds our app) then re-run A5's browse — expect **zero** lines reading `AirPlay Receiver`; then `xcrun simctl launch booted <bundle-id>` and re-run A5 — expect exactly one, same name | S1c's app-controlled half per `DEC-004`: leaving the foreground withdraws the advertisement, returning republishes one, not two. Proxy evidence for the device step O3, not a substitute | S1c (app half); TASK-006 c1-c2 |
| A9 | On this host: `grep -c 'packages:' airplay-2-receiver/project.yml` → `0`; `grep -n 'iOS: "15.0"' airplay-2-receiver/project.yml`; `grep -A1 '^schemes:' airplay-2-receiver/project.yml` → `AirPlayReceiver:` (not the project `name:`); `grep -c 'DEVELOPMENT_TEAM' airplay-2-receiver/project.yml` → `0`; `grep -rnE 'XCTSkip\|\.skip' airplay-2-receiver/test \|\| echo 'no skips'`; `grep -nE 'xcodeproj\|build/' airplay-2-receiver/.gitignore` | no dependency, no signing team in the shared file, target still 15.0, the scheme still exists, no test silently skipped, generated project still ignored | R3, R5 |

A5-A8 assume the app starts advertising on its own when active (TASK-005 adds no
buttons, TASK-006 wires `scenePhase`). If a browse is empty, first prove the
process is alive (A4's pid), then run the triage below. **An empty browse with no
pid is a crashed or backgrounded app, not evidence about Bonjour.**

### Observational checks

The human performs these on the iPhone 6s and the Apple TV and reports **one
line each, in this exact form**, plus the exported log file when the feature
ships. No prose, no "looks fine".

| # | Steps | Expected (report exactly this) |
| --- | --- | --- |
| O1 | 1. On the Mac, open `<build-dir>/airplay-2-receiver/AirPlayReceiver.xcodeproj`, select the signing team, let Xcode create the profile. 2. Connect the iPhone 6s, trust the Mac. 3. Run the app onto the phone (product scheme `AirPlayReceiver`, destination the 6s). 4. Leave the phone on the app's only screen. | `O1: installed and launched on iPhone 6s; screen reads "<status text>"` — with `<status text>` copied character for character, e.g. `Advertising as AirPlay Receiver` |
| O2 | 1. Phone unlocked, app foregrounded, phone and Apple TV on the same Wi-Fi. 2. Start a stopwatch at the tap that brings the app to the front. 3. On the Apple TV: Settings → Remotes and Devices → (or Control Centre) AirPlay speaker list. 4. Look for the name. 5. If absent, wait to 60 s, refresh the list once, look again. 6. Read the phone's screen. 7. Report. | `S1b: PASS — "AirPlay Receiver" appeared in N s` or `S1b: FAIL at 60 s; list showed <what was there>; phone screen read "<status text>"` |
| O3 | 1. With the entry visible, press Home (background the app) — do **not** force-quit. 2. Reopen the Apple TV speaker list. 3. Note the seconds until the entry is gone (stop at 60 s). | `S1c-bg: PASS — entry gone N s after backgrounding` or `S1c-bg: FAIL — still listed at 60 s` |
| O4 | 1. Relaunch the app, confirm the entry returns. 2. Force-quit it (swipe up in the app switcher) and start the stopwatch. 3. Reopen the Apple TV list every 10 s until the entry is gone, to 120 s. 4. Report the seconds. | `S1c-kill: entry gone after N s (Bonjour cache expiry, not app code — DEC-004)` — **a measurement, not a pass/fail**; the app's responsibility is O3 |
| O5 | 1. Same state as O2. 2. On the Apple TV, select `AirPlay Receiver` in the speaker list. 3. Force-quit the app while selected. 4. Relaunch it. 5. Open the Apple TV list. 6. Count entries under that name. 7. Tap the app's export control and send the file to yourself; open it. | `S5: entries=N, name="AirPlay Receiver"; log: Restart line present/absent` — N must be 1; attach the exported `airplay-receiver-log.txt` |
| O6 | 1. In the simulator (or on the phone) with at least two log lines, tap the export control. 2. Note whether the iOS share sheet opens and what filename it shows. 3. Cancel it. | `Export: share sheet opened, file "airplay-receiver-log.txt", N lines` or `Export: FAIL — <what appeared>` |

O2-O5 need O1. If O1 is impossible (no signing team, phone not trusted),
O1-O5 are `BLOCKED` with the reason — never `FAIL` of a task's code.

### Triage — "the app never advertised" vs "the Apple TV ignored us"

Run on the Mac (it shares the LAN), with the app foregrounded on the phone. Each
step narrows the fault; stop at the first failure and quote that output.

| T | Command | If it fails, this is the conclusion |
| --- | --- | --- |
| T1 | `dns-sd -B _airplay._tcp .` (browse 5 s, as in A5) | no `AirPlay Receiver` line at all → **the app never advertised**: check A4's pid, the phone's status text (should read `Advertising as AirPlay Receiver`), and the exported log for `Advertising`/a failure line. App-side bug (TASK-004/TASK-006), or the app was not foreground. |
| T2 | `dns-sd -L "AirPlay Receiver" _airplay._tcp .` | instance exists but will not resolve to a host and TXT → registered without a publishable record; app-side bug. Quote the raw `dns-sd` error (`DNSServiceResolve` code). |
| T3 | `dns-sd -G v4 <host>.local`, then `ping -c 1 <ip>`, then `nc -w 5 <ip> 7000` | resolves and pings but TCP refuses/times out → we advertise a door that does not open; app-side bug (TASK-003) and a real reason for the Apple TV to drop us. |
| T4 | `dns-sd -B _raop._tcp .` and `dns-sd -B _airplay._tcp .` with a **known-working** AirPlay 2 speaker on the same network, list its instance names and its TXT from `dns-sd -L` | a working device publishes `_raop._tcp` (and `_airplay._tcp`) while we publish only `_airplay._tcp`, and the Apple TV omits us → the advertisement is reachable and correct **as specified**, so this is a finding against FEAT-001's in-scope claim (missing `_raop._tcp` and/or TXT bits), for the BA — not a task FAIL and not a reason to hand-wave a pass. Record the diff of both TXT records verbatim. |
| T5 | 1. Attach T1-T4 output. 2. `ipconfig getifaddr en0` on the Mac and the phone's LAN IP from T3. 3. Refresh the Apple TV speaker list once more. 4. Read the phone's status text. 5. Export the log. | **the Apple TV ignored us**: T1-T3 pass, T4 shows no missing service, and the Apple TV still omits us → discovery is correct as specified. Report to the BA as a feature/protocol finding with the attached evidence, not a verdict on a task. |

The point of the split: T1-T3 failing means the app is wrong; T1-T3 passing with
the Apple TV silent means the app did what the feature specified and the feature
is wrong (or incomplete). Only the first is a task defect.

### Probes beyond the criteria

Run at feature close, once; each catches a criterion met by accident.

| P | Probe | Expected |
| --- | --- | --- |
| P1 | Relaunch without terminating (A4 again on an advertising app) | still exactly one instance (A5), not two — a duplicate name is the S5 stale-entry bug arriving early |
| P2 | A8 twice in a row: background → foreground → background → foreground, browsing after each | one instance while active, zero while background, never two; no flapping to zero while the app stays foreground (TASK-006 c3) |
| P3 | Port 7000 after re-foregrounding (A7 again) | same fixed response — the listener comes back with the advertiser, it does not leak or stay closed |
| P4 | Export with an empty log (fresh launch, export before anything else) | the file exists and is 0 bytes, the control stays enabled (TASK-008 c2), status text unchanged |

### Out of scope for verification (accepted, with reasons)

- **Any iOS execution on this host.** No Swift, Xcode or simulator here; the Mac
  is the only execution environment. The bridge went green on 2026-11-16, so
  A1-A9 now run for real; `BLOCKED` is only for a bridge failure, and it names
  the error line.
- **`dns-sd` on this host.** macOS-only; avahi on Linux would be a different
  responder and proves nothing about the Mac's mDNS proxy. A5-A8, T1-T4 run via
  `the build bridge run`.
- **The Apple TV speaker list.** Human only (O2-O5). No agent can see it, and a
  simulator browse is not evidence for it.
- **"Disappears within 30 s of a kill" as app behaviour.** No code runs after a
  kill; per `DEC-004` this is measured once (O4) and recorded, never pass/fail.
- **iOS 15.0 runtime behaviour.** The test destination is `iPhone 16e`, an iOS
  26.5 runtime (`DEC-005`): 15.0 is only a deployment-target promise checked at
  compile time (A9) and in the built product's `MinimumOSVersion`. Device
  behaviour is observed on the 6s, which is the real target.
- **Signed `iphoneos` builds.** No signing team in `project.yml` (A9), by
  design; signing is the human's one-time Xcode step (O1).
- **AirPlay discovery semantics beyond `_airplay._tcp`.** Whether the Apple TV
  needs `_raop._tcp` or specific TXT bits is unresolved at feature level; T4 is
  how we would find out. Not verifiable by unit test.

### Exit criteria

1. Every TASK-001…008 has a `qa` verdict of `PASS` in
   `qa/reports/TASK-###-review.md`, or a `BLOCKED` with the missing Mac step
   named and later cleared.
2. A1-A9 green from quoted output, with the log paths recorded.
3. O1-O6 reported in the exact strings above, with the exported
   `airplay-receiver-log.txt` attached to the feature verdict.
4. S5's entry count is 1 after a killed session; the exported log's `Restart`
   content is reported as found, not assumed (see the gap below).
5. `qa/REGRESSION.md` R1-R5 green.
6. No open finding, and any T4/T5 conclusion handed to the BA with its evidence.

### Verification gaps handed to the BA (do not paper over)

- **S5's `Restart` log line has no owner task.** `FEAT-001` S5 requires the
  exported log to contain "the `Restart` line for that launch", but TASK-007
  records start, stop, failure and rejected connection only — no `Restart`
  event, and TASK-006 explicitly forbids persisting "was advertising" across
  launches, so nothing in increment 1 can distinguish a relaunch from a first
  launch. The log half of S5 is therefore **not verifiable as written**: a
  review may record the entries count and what the log actually contains, but
  must not claim S5 met. Fix: BA adds the literal event to TASK-007 (e.g. a
  `Launched (n)` or `Restart` line on every launch after the first) or re-words
  S5. Until then this feature's verdict carries a stated limitation.
- **Installing on the 6s is nobody's task.** S1b/S1c/S5 need the app on the
  device; FEAT-001 has no task for signing and installing, and TASK-001 verifies
  the simulator build only. The human does O1 once. If that step is not done at
  feature close, O1-O5 stay `BLOCKED` and the feature cannot be closed — that is
  a scheduling gap for the BA, not a task defect.

---

## Template

### FEAT-000 — <feature title>

**Feature demo:** the two-step path that proves it.

**Environment:** how to run the app here, and what cannot be verified on this
host (see `docs/STACK.md`; state it plainly).

**Automated checks**

| # | Command | Proves | Covers criteria |
| --- | --- | --- | --- |
| 1 |  |  |  |

**Observational checks**

| # | Steps | Expected |
| --- | --- | --- |
| 1 |  |  |

**Out of scope for verification:** what we accept as unverifiable, and why.

**Exit criteria:** all tasks `PASS`, no open regressions, demo works from a clean
checkout.
