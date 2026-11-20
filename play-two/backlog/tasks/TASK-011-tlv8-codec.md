---
id: TASK-011
title: TLV8 codec (encode and decode)
feature: FEAT-002
status: done
attempts: 1
owner: null
depends_on: []
estimate: small
---

# TASK-011 — TLV8 codec (encode and decode)

## Goal

A Swift type that encodes a list of (type, value) TLV8 entries into bytes and
decodes bytes back into the same list, including values longer than 255 bytes
via the HAP continuation rule, so HAP messages can be framed and parsed.

## Context for the developer

- Where it lives: `src/HAP/TLV8.swift` (new), `test/TLV8Tests.swift` (new).
- Interfaces it may touch: none existing. Do not import anything beyond
  `Foundation`.
- Files in scope (2): the two above.
- Explicitly **do not** touch: `project.yml`, `src/PlayTwoApp.swift`,
  `src/ContentView.swift`, `src/Net/`, `src/AirPlay/`, `docs/`, `qa/`,
  journals other than `journal/<role>.md`, `scripts/`, `.opencode/`.
- TLV8 format (HAP): each entry is a 1-byte type, a 1-byte length, then
  `length` bytes of value. If a value exceeds 255 bytes, split it into
  consecutive fragments of at most 255 bytes, each with the same type and its
  own length byte; a value of exactly 255 bytes needs no continuation. A fragment
  with length 0 and a type marks... no: a zero-length fragment is only used as
  the terminator of a multi-fragment value? Actually in HAP, a multi-fragment
  value is terminated by a fragment of the same type with length 0. Decode
  accordingly: collect fragments of the same type until a zero-length fragment
  of that type, concatenate their values.

## Acceptance criteria

1. [ ] Given a list of `(type: UInt8, value: Data)` pairs each with value
       length ≤ 255, when `TLV8.encode(_:)` is called, then decoding the
       result returns an equal list.
2. [ ] Given a pair whose value is 300 bytes, when encoded and decoded, then
       the decoded value equals the original 300 bytes (fragmented form on the
       wire).
3. [ ] Given bytes that are truncated mid-value, when decoded, then it returns
       `nil` (or throws) instead of a partial entry.
4. [ ] Given two entries with the same type, when encoded and decoded, then
       they are preserved as two separate entries (not merged) unless a
       multi-fragment continuation is intended — the encoder only fragments a
       single value over 255 bytes.
5. [ ] `TLV8Tests` passes: `Executed N tests, with 0 failures`, including at
       least the four cases above.

## Verification commands

```sh
# on this host
ls play-two/src/HAP play-two/test

# on the Mac
rsync -a <project> <build-host>:<build-dir>/
xcodegen generate
xcodebuild test -scheme PlayTwo -destination 'platform=iOS Simulator,name=iPhone 16e,OS=26.5' | tee /tmp/opencode/task-011-test.log
grep -E "Test Suite 'TLV8Tests' (passed|failed)" /tmp/opencode/task-011-test.log
```

## Definition of done

- [ ] All criteria have evidence in `qa/reports/TASK-011-review.md`
- [ ] `qa` verdict is `PASS`
- [ ] Only files listed above changed
- [ ] Regression list still passes
- [ ] One commit `play-two/TASK-011: TLV8 codec (encode and decode)` exists

## Rework log

| Attempt | Date | Tester findings | Outcome |
| --- | --- | --- | --- |
| — | — | — | — |

## Notes

- Pure value type / enum; no I/O, no state. Easily unit-testable on the
  simulator.
- HAP TLV8 reference: Apple's HAP spec section on data encoding. Type codes
  are defined by callers (this task does not assign meaning to types).
- Keep the API minimal: `static func encode(_ entries: [(UInt8, Data)]) -> Data`
  and `static func decode(_ data: Data) -> [(UInt8, Data)]?` (or throwing). The
  developer chooses the exact signature; the tests pin the round-trip.