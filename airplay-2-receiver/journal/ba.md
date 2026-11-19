# BA journal — AirPlay 2 Receiver

Append only, newest at the bottom. One entry per unit of work. Status lives in
`docs/STATE.md`; this is the narrative.

```md
## 2026-11-15 — <what this was>
- did:
- decided:
- dispatched: <agent> for <TASK-###> → <result>
- next:
```

---

## 2026-11-15 — project created

- did: skeleton from `scripts/new-project.sh`, registry row added, workspace state
  set to this project.
- decided: nothing yet. Stack undecided by design.
- flagged: QQ-001 — receiving vs controlling. Affects feasibility, not just stack.
- next: intake.

## 2026-11-15 — intake session 1

- did: confirmed the product: iPhone 6s receives AirPlay, forwards to a Bluetooth
  speaker. Read the AirAP reference (AirPlay 1, Swift/shairplay, no certification
  needed).
- decided: nothing yet.
- flagged: QQ-002 (AirPlay 1 vs 2 for v1), QQ-003 (personal vs distributed).
  AirPlay 2 + Home app + multi-room is the licensed part; AirPlay 1 is proven.
- next: get QQ-002 answered, then write the spec.

## 2026-11-15 — spike opened

- did: evidence pass 1 on AirPlay 2 receivers. shairport-sync implements AP2 in
  software; openairplay's python receiver does HomeKit pairing and FairPlay v3 and
  states MFi auth may never be implemented. AirAP proves the iOS-app shape for
  AirPlay 1.
- decided: spike first (user's call), timeboxed, decision before G1.
- flagged: nothing can be compiled or tested on this host (no Mac/Xcode), so the
  spike's ceiling is "promising, needs a Mac".
- next: QQ-003, then pass 2 or DEC-001.

## 2026-11-15 — spike pass 2 and verdict

- did: found five independent AP2 receiver implementations (C, Python, Go, Rust,
  Java, ESP32); confirmed shairport-sync can be added to the Home app on iOS 15.3
  with no MFi hardware; confirmed FairPlay is implemented as extracted key tables
  (654 KB in the Python receiver); found zero Swift/ObjC AP2 receivers.
- decided: recommendation only — C if Home/multi-room matters, B if the 6s is the
  point, A is a 3-4 month research project with DRM exposure. No DEC yet.
- flagged: iOS background discovery is unsolved and untestable without a Mac.
- next: QQ-004, then DEC-001.

## 2026-11-15 — DEC-001 and the Mac blocker

- did: recorded DEC-001 (build it, sideload, personal use) and DEC-002 (four
  increments, kill-switch each). Rewrote the disposable spec scaffold into a
  decision record.
- decided: no coding starts before a Mac exists; QQ-005 opened.
- flagged: free Apple ID = 7-day re-sign; paid = annual. FairPlay key material
  cannot ever ship publicly.
- next: resolve Mac access, then write the spec for increment 1.

## 2026-11-15 — Mac bridge

- did: installed openssh and rsync under `.tooling/net`, generated
  `.tooling/ssh/mac_ed25519`, wrote the build bridge (check/key/sync/
  build/test/install/run) and `scripts/mac.env.example`; recorded DEC-007.
- decided: the Mac is a build host, not a second source of truth. Agents sync
  into `<build-dir>` and never edit the Mac otherwise.
- flagged: the bridge is untested until the human supplies host/user and installs
  the public key; `check` is the acceptance test.
- next: spec for increment 1, stack, G1.

## 2026-11-15 — spec and stack for G1

- did: wrote SPEC v0.1 (problem, persona, core flow, four-increment scope,
  non-goals, S1-S5 success criteria, constraints) and settled the stack: Swift 5,
  iOS 15.0, SwiftUI, Network.framework, CryptoKit, XcodeGen, XCTest, no
  dependencies.
- decided: XcodeGen over a committed .xcodeproj (reviewable text, no plist merge
  conflicts for the agents); increment 1 is foreground-only, which sidesteps the
  background-discovery risk until increment 4.
- flagged: S1-S5 need the human to look at the Apple TV; no agent can press those
  buttons. Mac must still offer an iOS 15.0 deployment target.
- next: G1, then PM breakdown of increment 1.

## 2026-11-15 — G1 passed

- did: checked the spec against the G1 checklist (one persona, 5-step flow, 7
  non-goals with reasons, S1-S5 observable, stack decided, no blocking question)
  and recorded the approval in SPEC, STATE and DEC-002.
- decided: increment 1 (discoverable) is the only work that will be staffed.
- next: PM breakdown, QA test plan, first task.

## 2026-11-15 — G2, G3, and the two scope questions

- did: read FEAT-001 and all eight task files; approved the feature at G2 (one
  vertical slice, traces to S1/S5, ordered) and the task batch at G3 (one
  behaviour each, no "and" in a title, <= 5 files, Given/When/Then criteria with
  commands). Answered QQ-006 (DEC-003: default name in increment 1) and QQ-007
  (DEC-004: withdraw on background; post-kill expiry is Bonjour's cache).
- decided: TASK-001 approved to run; tasks 002-008 stay proposed until the
  previous one is PASSed.
- flagged: every build/test criterion in FEAT-001 is expected BLOCKED until the
  Mac is configured. The scaffold is being written blind, so TASK-001 can only
  fully pass after `check`.
- next: QA test plan, then TASK-001.

## 2026-11-15 — QA plan review

- did: read the FEAT-001 test plan; fixed the agent permission gap that stopped
  `qa` from writing `journal/<role>.md` (and gave `pm` the same rule for
  `journal/<role>.md`); opened QQ-008 for the signing team, since S1b, S1c and S5
  only exist on a signed device build.
- decided: TASK-007 needs a launch marker so S5's log check has a producer; that
  is PM's edit, not the BA's.
- flagged: simulator iOS is newer than 15.0, so the deployment target is a
  compile-time promise until the 6s runs it.

## 2026-11-15 — TASK-001 implemented, BLOCKED

- did: developer wrote the scaffold (project.yml, SwiftUI entry, one test);
  QA verified the static half and returned BLOCKED with five minor findings and
  no code defect claimed.
- decided: stop the loop here. Continuing would stack unverified Swift on an
  unverified scaffold, and the process forbids counting it as done.
- flagged: TASK-001 stays `blocked`, attempts 1. The Mac is the only missing
  thing: local configuration, key, Xcode opened once, XcodeGen.
- next: on `xcodebuild -version`, re-verify TASK-001, then TASK-002.

## 2026-11-16 — Mac onboarding

- did: configured local configuration for the Tailscale address
  (<build-host>, user <user>); the first `check` reached the Mac and was
  refused for lack of the public key. Wrote the onboarding script because the
  human cannot paste into the Mac's terminal: idempotent key install, then Xcode,
  iOS SDK, XcodeGen and Remote Login checks. Tested its key logic twice under a
  temporary HOME (second run adds nothing).
- decided: onboarding is a script, not a copy-pasted command; the Mac pulls it
  over scp/Taildrop (documented in the private build notes).
- flagged: sandbox test cannot exercise the macOS-only branches (stat -f,
  systemsetup, xcodebuild); first real run will.

## 2026-11-16 — TASK-001 passes on the real Mac

- did: bridge fixes (PATH, tilde, project discovery) got `sync`, `xcodegen`,
  simulator build and the unit test green; QA re-verified with 5/5 criteria and a
  mutation probe that proves the test is not vacuous.
- decided: TASK-001 done at G4. Minor findings stay open: generated
  Info.plists not gitignored, display name duplicated in `project.yml` and
  `AppInfo`, `iPhone 16` still named in TASK-001's command.
- flagged: no iPhone 6s connected, so device criteria remain unverifiable.
