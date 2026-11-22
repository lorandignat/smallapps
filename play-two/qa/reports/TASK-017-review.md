# TASK-017 — Expose the pairing state in the pairing store — PASS

Tester run: 2026-11-22. Host: MacBook Pro 2015, macOS 12.7.6, Xcode 14.2
(14C18), x86_64; destination `platform=iOS Simulator,name=iPhone 14,OS=16.2`.
Attempt 1 (dev report: `play-two/journal/<role>.md` §2026-11-22 — TASK-017).
Evidence log: `/tmp/opencode/task-017-test.log`.

The suite was not re-run on this host (Linux, no Swift or Xcode —
`play-two/docs/STACK.md` "Nothing iOS runs on this host"); the log is the
developer's Mac run of the verification commands from
`play-two/backlog/tasks/TASK-017-expose-pairing-state.md`. Every quote below is
from `/tmp/opencode/task-017-test.log` or the source/test files.

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Given a saved `HAPPairingStore.Record(salt: 16 bytes, verifier: 384 bytes, paired: false)`, a new store instance on the same service reloads an equal record and `paired == false` — the Keychain round-trip (reload proof, not a static var) | PASS | Log: `Test Suite 'HAPPairingStoreTests' passed at 2026-11-22 12:07:20.651.` + `Executed 5 tests, with 0 failures (0 unexpected) in 0.061 (0.064) seconds`; case line: `Test Case '-[PlayTwoTests.HAPPairingStoreTests testSaveAndReloadAcrossInstances]' passed (0.010 seconds).` The reload is real: the test saves on one instance and reads on a second — `play-two/test/HAPPairingStoreTests.swift:46-49` (`HAPPairingStore(service: service).save(record: saved)` `:46`, `let reloaded = HAPPairingStore(service: service)` `:47`) with `XCTAssertEqual(reloaded.record, saved, "the record must reload from the Keychain")` `:48` and `XCTAssertFalse(reloaded.paired, "the saved record is unpaired")` `:49`. The reload path is `SecItemCopyMatching` per call (`play-two/src/HAP/HAPPairingStore.swift:91`). |
| 2 | Given a saved record with `paired: true`, a new instance on the same service reads `paired == true` | PASS | Log case line: `Test Case '-[PlayTwoTests.HAPPairingStoreTests testPairedStateReloadsAcrossInstances]' passed (0.007 seconds).` — `play-two/test/HAPPairingStoreTests.swift:54-62`: saves `Record(salt: Data(repeating: 0xC3, count: 16), verifier: Data(repeating: 0xD4, count: 384), paired: true)` `:56-60`; the new instance is `HAPPairingStore(service: service).paired` `:61` — `XCTAssertTrue`. |
| 3 | `HAPPairingStore.shared` → `GET /info` body contains `"paired": false` while no record is saved | PASS | Log: `Test Suite 'HAPServerTests' passed at 2026-11-22 12:07:20.694.` + `Executed 8 tests, with 0 failures (0 unexpected) in 0.039 (0.042) seconds`; case line: `Test Case '-[PlayTwoTests.HAPServerTests testRouteInfoReturns200WithNameCategoryAndPaired]' passed (0.002 seconds).` — `play-two/test/HAPServerTests.swift:74-81`: `HAPServer()` defaults to `HAPPairingStore.shared` (`play-two/src/HAP/HAPServer.swift:31`), routes `GET /info`, asserts `body.contains("\"paired\": false")` `:80`. Mechanism: `HAPServer.infoBody` (`HAPServer.swift:122-126`) interpolates `pairingStore.paired` at route time (`route` returns `Response(status: 200, body: infoBody)` `:115`). Live-wire proof: case line `Test Case '-[PlayTwoTests.HAPServerTests testLiveInfoExchangeAnswersOverAPort]' passed (0.017 seconds).` asserts the text received over the real socket contains `"paired": false` (`HAPServerTests.swift:175`). "No record saved" holds because nothing writes `com.lorand.playtwo.hap-pairing` yet — dev journal: "the `paired` default depends on no pairing record existing in the simulator — TASK-018 writes one and flips it to true, which is the intent"; `HAPPairingStore.defaultService` is new and `save` has no other caller. |
| 4 | `HAPPairingStoreTests` passes: `Executed 5 tests, with 0 failures` — `testFreshStoreHasNoRecordAndIsUnpaired`, `testSaveAndReloadAcrossInstances`, `testPairedStateReloadsAcrossInstances`, `testSaveReplacesTheRecord`, `testDeleteClearsTheRecord` | PASS | Log: `Test Suite 'HAPPairingStoreTests' passed at 2026-11-22 12:07:20.651.` + `Executed 5 tests, with 0 failures (0 unexpected) in 0.061 (0.064) seconds`. All five cases passed, per the log: `testFreshStoreHasNoRecordAndIsUnpaired` (0.003 s), `testSaveAndReloadAcrossInstances` (0.010 s), `testPairedStateReloadsAcrossInstances` (0.007 s), `testSaveReplacesTheRecord` (0.027 s), `testDeleteClearsTheRecord` (0.013 s). |
| 5 | `HAPServerTests` passes: `Executed 8 tests, with 0 failures` — the seven from TASK-016 plus `testInfoReportsThePairedStateFromTheStore` | PASS | Log: `Test Suite 'HAPServerTests' passed at 2026-11-22 12:07:20.694.` + `Executed 8 tests, with 0 failures (0 unexpected) in 0.039 (0.042) seconds`. The eight cases passed, per the log: the seven TASK-016 cases (`testParseReturnsMethodPathAndBody` 0.001 s, `testParseReadsTheContentLengthBody` 0.002 s, `testParseReturnsNilOnMalformedInput` 0.001 s, `testRouteInfoReturns200WithNameCategoryAndPaired` 0.002 s, `testRouteOtherPathReturns404` 0.001 s, `testRoutePostPairSetupReturns404` 0.001 s, `testLiveInfoExchangeAnswersOverAPort` 0.017 s) and `Test Case '-[PlayTwoTests.HAPServerTests testInfoReportsThePairedStateFromTheStore]' passed (0.013 seconds).` — `play-two/test/HAPServerTests.swift:104-118`: constructs `HAPPairingStore(service: freshPairingService())` `:105`, saves `Record(salt: Data(repeating: 1, count: 16), verifier: Data(repeating: 2, count: 384), paired: true)` `:106-110`, routes `HAPServer(pairingStore: store).route(HAPServer.Request(method: "GET", path: "/info", body: Data()))` `:111-112`, asserts `response.status == 200` `:113` and `String(decoding: response.body, as: UTF8.self).contains("\"paired\": true")` `:114-117`. |

## Gaming checks

- **`paired` is read live from the Keychain on every call (the two reload cases).** `HAPPairingStore.paired` is an instance property: `var paired: Bool { record?.paired ?? false }` (`play-two/src/HAP/HAPPairingStore.swift:55-57`), and `record` re-queries the Keychain per access: `var record: Record? { guard let data = Self.storedRecordData(service: service) … }` (`:48-51`) → `storedRecordData` → `SecItemCopyMatching` (`:86-96`, match at `:91`). No cached value, no static stored property.
- **No leftover static/constant source of truth; the constant `HAPServer.paired` is deleted.** `grep -nE "static .*paired" play-two/src/HAP/HAPServer.swift play-two/src/HAP/HAPPairingStore.swift` → no matches. `git diff play-two/src/HAP/HAPServer.swift` shows the old `static let paired = false` removed; `HAPServer.swift` now has `let pairingStore: HAPPairingStore` `:27` and `init(pairingStore: HAPPairingStore = HAPPairingStore.shared)` `:31`. `HAPPairingStore.shared` (`HAPPairingStore.swift:20`) is the app's shared instance; the paired flag is never a static constant anywhere.
- **New tests use UUID-suffixed services and delete entries in teardown.** `HAPPairingStoreTests.freshService()` returns `"com.lorand.playtwo.hap-pairing.\(UUID().uuidString)"` and records it (`play-two/test/HAPPairingStoreTests.swift:22-26`); `tearDown` deletes each entry via `HAPPairingStore(service: service).delete()` (`:13-19`). `HAPServerTests.freshPairingService()` is the same pattern (`play-two/test/HAPServerTests.swift:32-36`) with the delete in its `tearDown` (`:22-28`). R5: `grep -rnE 'XCTSkip|\.skip' play-two/test` → `no skips`.
- **`testInfoReportsThePairedStateFromTheStore` really constructs a store, saves a record, and routes** — yes: store at `HAPServerTests.swift:105`, `store.save(record: …)` `:106-110`, `HAPServer(pairingStore: store).route(HAPServer.Request(method: "GET", path: "/info", body: Data()))` `:111-112`, asserts 200 `:113` and `"paired": true` in the body `:114-117`; the log records `Test Case '-[PlayTwoTests.HAPServerTests testInfoReportsThePairedStateFromTheStore]' passed (0.013 seconds).`
- **Nothing vacuous about the reload cases.** The equality assert compares the *second instance's* record to the saved record (`HAPPairingStoreTests.swift:48`), and both instances read through `SecItemCopyMatching` (`HAPPairingStore.swift:91`).

## Scope

`git status --short`: `M play-two/src/HAP/HAPServer.swift`, `M play-two/test/HAPServerTests.swift`, `?? play-two/src/HAP/HAPPairingStore.swift`, `?? play-two/test/HAPPairingStoreTests.swift` — the four files in scope; `M play-two/backlog/tasks/TASK-017-expose-pairing-state.md` and `M play-two/journal/<role>.md` are dev-owned, not touched here. This turn wrote only `qa/reports/TASK-017-review.md`, the R2 row raise in `qa/REGRESSION.md`, and this `journal/<role>.md` entry. No commit, no task-status change, no other files.

## What I ran

- `git diff -- play-two/src/HAP/HAPServer.swift play-two/test/HAPServerTests.swift play-two/backlog/tasks/TASK-017-expose-pairing-state.md`; `git log --oneline -5` (HEAD `a5bb336 play-two/chore: TASK-016 done (G4 PASS); next TASK-017`); `git status --short` — tree matches the dev's reported diff.
- `grep -n "paired" play-two/src/HAP/HAPServer.swift`; `grep -nE "static .*paired" play-two/src/HAP/HAPServer.swift play-two/src/HAP/HAPPairingStore.swift`.
- Reads: `play-two/src/HAP/HAPPairingStore.swift`, `play-two/test/HAPPairingStoreTests.swift`, `play-two/test/HAPServerTests.swift`, `play-two/backlog/tasks/TASK-017-expose-pairing-state.md`, `play-two/qa/REGRESSION.md` (R2 row), `play-two/qa/reports/TASK-016-review.md`, tail of `play-two/journal/<role>.md`.
- Log greps: `grep -aE "Test Suite '(PlayTwoTests.xctest|HAPPairingStoreTests|HAPServerTests)' (passed|failed)" /tmp/opencode/task-017-test.log`; `grep -aA1 -E "Test Suite '(PlayTwoTests.xctest|HAPPairingStoreTests|HAPServerTests)' (passed|failed)" /tmp/opencode/task-017-test.log`; `grep -aE "Test Case '-\[PlayTwoTests\.(HAPPairingStoreTests|HAPServerTests) test.*' passed" /tmp/opencode/task-017-test.log` (13 case lines, all `passed`); `grep -acE "Test Case '.*' failed" /tmp/opencode/task-017-test.log` → `0`; `grep -acE "TEST SUCCEEDED" /tmp/opencode/task-017-test.log` → `1`; `grep -rnE 'XCTSkip|\.skip' play-two/test` → `no skips`; `ls -la /tmp/opencode/task-017-test.log` (312,644 bytes).
- No re-run of the suite on this host (Linux, no Swift/Xcode).

## Findings

None. Nothing in the diff touches out-of-scope files and every criterion has evidence. Observations, not findings:

- The R4 row in `qa/REGRESSION.md` is stale: it pins the deleted `ReceiverListener.response` fixed reply (`play-two/src/Net/ReceiverListener.swift`) while `ReceiverListenerTests` is now 4. The dev journal defers rewording to feature close; out of this task's scope.
- Criterion 3 ("while no record is saved") holds only because nothing writes `com.lorand.playtwo.hap-pairing` yet; dev journal: TASK-018 is the first writer of the record under that service. This is the intended state, not a defect.

## Regressions

- **R2 — pass.** Full bundle line, `/tmp/opencode/task-017-test.log`: `Test Suite 'PlayTwoTests.xctest' passed at 2026-11-22 12:14:40.746.` + `Executed 68 tests, with 0 failures (0 unexpected) in 440.431 (440.474) seconds`. `** TEST SUCCEEDED **` present (`grep -cE "TEST SUCCEEDED"` → `1`); `grep -acE "Test Case '.*' failed"` → `0`. **R2 high-water actual: 68** (dev journal: "high-water 68 (62 after TASK-016 + 5 + 1)"); the R2 row in `qa/REGRESSION.md` was raised **62 → 68** this turn.

## Unverifiable on this host

The suite was not re-executed (no Swift/Xcode on Linux — `play-two/docs/STACK.md`); all quoted lines are from the developer's Mac run log `/tmp/opencode/task-017-test.log`. No device-side behaviour is claimed by this task.

## Verdict

PASS — every criterion has evidence (per-criterion table above), the regression list passes at the raised high-water mark, and nothing important was left unverified: the two reload cases are real second instances reading the Keychain, and the old `HAPServer.paired` constant is gone.

```text
TASK-017 Expose the pairing state in the pairing store — PASS
Criteria: 5/5 verified · Regressions: pass (R2, 68 tests, high-water 68)
Findings: none
Unverifiable here: none
Report: qa/reports/TASK-017-review.md
```
