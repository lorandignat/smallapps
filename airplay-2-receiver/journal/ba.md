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
