---
id: TASK-026-review
task: TASK-026
feature: FEAT-005
verdict: PASS
date: 2026-11-22
attempt: 2
---

# Review — TASK-026 Parse the FairPlay fields of a SETUP request

## Criteria

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Given a recorded SETUP-request fixture (bytes committed in the test as a static fixture, sourced from reference behaviour or a device capture described in the test comment), when `FairPlaySetup.parse(from:)` runs, then it returns a model containing the non-empty `Apple-Challenge` bytes and the non-empty encrypted stream-key material bytes expected by that fixture. | PASS | `play-two/test/FairPlayFieldTests.swift:4-14` class comment names source/shape: "Static fixture source (traceable, not device-captured, not real DRM/key material): Shape follows the AirPlay 2 RTSP SETUP form documented by the openairplay/airplay2-receiver reference implementation..." and states bytes are "static synthetic fixtures committed in this test, shaped to that reference form for parser traceability". Fixtures are static base64 strings committed in test (`:17-47`): `recordedSetupRequestBase64`, `missingChallengeRequestBase64`, `emptyEkeyRequestBase64`, `malformedBodyRequestBase64`. No runtime `PropertyListSerialization.data(...)` synthesis present. Decoded recorded fixture (verified on this host with Python `base64`/`plistlib`) contains `Apple-Challenge: AAECAwQFBgcICQoLDA0ODw==` (16 bytes `00..0f`) and bplist `ekey` Data length 72 bytes `00..47`. Tests assert expected values from that fixture: `testParseChallengeFromAppleChallengeHeader` (`:53-61`) asserts non-empty challenge equals `expectedChallenge` (`[0..15]`); `testParseEncryptedKeyMaterialFromBplistBody` (`:63-72`) asserts non-empty `encryptedKeyMaterial` equals 72-byte `0..<72` and count 72. Parser: `play-two/src/RTSP/FairPlaySetup.swift:27-64` extracts base64 `Apple-Challenge` header (trimmed, decoded, exactly 16 bytes) and bplist `ekey` (top-level or inside `streams`) as non-empty `Data`; returns `FairPlaySetup` only when both present. Mac log: `Test Suite 'FairPlayFieldTests' passed at 2026-11-22 20:10:59.298.` / `Executed 4 tests, with 0 failures (0 unexpected) in 0.009 (0.011) seconds` (`/tmp/opencode/task-026-test.log:312-313`). |
| 2 | Given a SETUP request missing the challenge field, when parsed, then it returns `nil`/throws and no partial model is produced. | PASS | `play-two/test/FairPlayFieldTests.swift:74-79` uses static `missingChallengeRequestBase64` (decoded fixture has no `Apple-Challenge` header) and asserts `XCTAssertNil(FairPlaySetup.parse(from: request), "missing Apple-Challenge must not produce a partial model")`. Parser guard: `FairPlaySetup.swift:28,34-40` returns nil when header missing/empty/not base64/not 16 bytes. |
| 3 | Given a SETUP request with an empty or malformed encrypted-key field, when parsed, then it returns `nil`/throws with no crash. | PASS | `play-two/test/FairPlayFieldTests.swift:81-87` asserts nil for static empty-ekey fixture (`ekey` Data length 0 in bplist) and static malformed-body fixture (body bytes `00 01 02 03`, not bplist), with "no partial model"/"must not crash" messages. Parser guards: `FairPlaySetup.swift:43-50` reject empty body, non-plist/malformed body, missing/non-Data/empty `ekey`. |
| 4 | `FairPlayFieldTests` passes: `Test Suite 'FairPlayFieldTests' passed` and `Executed 3 tests, with 0 failures` — covering the three cases above. | PASS (minor count discrepancy) | `/tmp/opencode/task-026-test.log:312` `Test Suite 'FairPlayFieldTests' passed at 2026-11-22 20:10:59.298.`; `:313` `Executed 4 tests, with 0 failures (0 unexpected) in 0.009 (0.011) seconds`. Four tests cover all three required cases (criterion 1 split across `testParseChallengeFromAppleChallengeHeader` and `testParseEncryptedKeyMaterialFromBplistBody`; criteria 2 and 3 covered). Count exceeds the stated "3 tests" but is stronger coverage, not weaker. |

## What I ran

I did not re-run the Mac simulator suite myself (no Swift/Xcode/simulator on this Linux host, per `play-two/docs/STACK.md`); I verified the developer-provided Mac log/mirror and inspected source/tests/diff on this host.

```sh
# Required reads
cat play-two/AGENTS.md
cat play-two/docs/STACK.md
cat play-two/backlog/tasks/TASK-026-parse-fairplay-setup-fields.md
cat play-two/backlog/features/FEAT-005-rtsp-fairplay.md
cat play-two/qa/reports/TASK-026-review.md
cat play-two/qa/REGRESSION.md

# Scope / diff
git -C play-two status --short
git -C play-two diff --name-only
git -C play-two diff --stat
git -C play-two diff --unified=3 -- journal/<role>.md | tail -60

# Evidence
tail -60 /tmp/opencode/task-026-test.log
grep -n "FairPlayFieldTests" /tmp/opencode/task-026-test.log | tail -20
grep -B2 -A15 "Test Suite 'FairPlayFieldTests' passed" /tmp/opencode/task-026-test.log | tail -20

# Fixture sanity check (static bytes, not runtime synthesis)
python3 - <<'PY'  # decoded recorded/missing/empty/malformed base64 fixtures
import base64, plistlib
...
PY

# Safety/constraint checks
grep -rn "#import CryptoKit\|import CryptoKit\|CCCrypt\|CommonCrypto\|decrypt\|keyTable\|key_table\|URLSession\|NWConnection\|NWListener\|Socket\|connect\|listen" play-two/src/RTSP/FairPlaySetup.swift play-two/test/FairPlayFieldTests.swift || echo "CLEAN"
```

Observed test log lines (`/tmp/opencode/task-026-test.log`):
- `Test Suite 'FairPlayFieldTests' passed at 2026-11-22 20:10:59.298.`
- `Executed 4 tests, with 0 failures (0 unexpected) in 0.009 (0.011) seconds`
- `Executed 93 tests, with 0 failures (0 unexpected) in 792.117 (792.176) seconds`
- `** TEST SUCCEEDED **`
- `ok — log: /homedir/agent/opencode/apps/20261122T181026Z-test.log`

Observed scope (`git -C play-two status --short`):
- `M backlog/BOARD.md`, `M backlog/tasks/TASK-026-parse-fairplay-setup-fields.md` — BA-owned status edits (finding 1 from attempt 1; BA confirmed not dev defect, do not fail).
- `M journal/<role>.md` — allowed.
- `M journal/<role>.md`, `M qa/REGRESSION.md`, `?? qa/reports/TASK-026-review.md` — QA-owned files (this review).
- `?? src/RTSP/FairPlaySetup.swift`, `?? test/FairPlayFieldTests.swift` — task-allowed files.

## Findings

1. **MINOR** — `play-two/test/FairPlayFieldTests.swift:6-13` — Criterion 1/note asks for a traceable source naming a reference implementation file/version or dated device capture. The comment names `openairplay/airplay2-receiver` reference implementation and clearly states the fixture is static synthetic/non-capture/no real DRM, which resolves attempt 1's MAJOR runtime-synthesis issue. It does not name a specific reference file/version. Non-blocking: fixture is static committed bytes with explicit reference-shaped provenance; improve by citing a specific reference file/path/version if available.

2. **MINOR** — `play-two/backlog/tasks/TASK-026-parse-fairplay-setup-fields.md:47`, `play-two/test/FairPlayFieldTests.swift` — Criterion 4 states `Executed 3 tests, with 0 failures`; suite runs 4 tests. Stronger coverage, not weaker. Carried from attempt 1.

## Attempt 1 (2026-11-22) — FAIL

- Finding 1 (MAJOR, BA-process artifact): BA-owned `backlog/BOARD.md` and `backlog/tasks/TASK-026-parse-fairplay-setup-fields.md` status edits present. BA confirmed not a dev defect; excluded from attempt 2 verdict.
- Finding 2 (MAJOR): fixture was runtime-synthesized via `PropertyListSerialization`/string construction, not a traceable static recorded fixture with named source. **Resolved in attempt 2** by static base64 fixtures committed in test with explicit reference-shaped source comment.
- Finding 3 (MINOR): 4 tests vs 3 stated. Carried forward.

## Regressions

R2 high-water remains **93**. Attempt 2 Mac log shows `Executed 93 tests, with 0 failures (0 unexpected)`, `** TEST SUCCEEDED **` (`20261122T181026Z-test.log`, mirror `/tmp/opencode/task-026-test.log`). `FairPlayFieldTests` 4/0. I updated `play-two/qa/REGRESSION.md` R2 last-result to record TASK-026 attempt 2 PASS verification; high-water unchanged at 93. I did not re-run R1/R3-R15; no unrelated code paths changed. No regression failures observed.

## Unverifiable on this host

No Swift/iOS simulator/Xcode on this Linux host. I relied on the developer-provided Mac test log/mirror and static code inspection, per `play-two/docs/STACK.md`. Device/Apple TV FairPlay exchange is human-only and outside this task.

## Verdict

**Verdict:** PASS

Attempt 2 resolves attempt 1's MAJOR fixture-traceability finding: `FairPlayFieldTests.swift` now uses static base64 fixture bytes committed in the test, with an explicit class comment naming the openairplay/airplay2-receiver-shaped source and stating the fixtures are synthetic/non-capture/no real DRM. All four task criteria are satisfied with evidence; full bundle is 93/0 with no regressions observed. Two MINOR notes remain (reference file/version not named; 4 tests vs 3 stated).

**Next:** BA may record G4 PASS and proceed with FEAT-005 sequencing; consider adding a specific reference file/version to the fixture comment when convenient.