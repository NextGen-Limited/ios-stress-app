---
status: testing
phase: 02-data-integrity-deletion-consolidation
source: [02-01-SUMMARY.md, 02-VERIFICATION.md]
started: 2026-08-12T03:37:27Z
updated: 2026-08-12T23:05:00Z
audit_acknowledged:
  milestone: v1.2
  at: 2026-09-05
  gap_snapshot: "testing::scenarios=3"
---

## Current Test

number: 6
name: Two-device CloudKit sync + Keychain sign-out check
expected: |
  On two real devices signed into the same iCloud account: take a measurement on device A,
  confirm it syncs to device B, run "Delete all snapshots" on device A, confirm the record
  disappears from device B's history and its widget within a sync window, and confirm device A's
  chat entry point shows no live session afterward.
awaiting: user response

## Tests

### 1. Delete All wipes credentials and cache

expected: In Settings, tap "Delete All Data". After it completes, all stress measurements are gone, the app behaves as if freshly installed (Supabase session/credentials cleared, not silently still signed in), and the home-screen widget stops showing old data.
result: pass

### 2. Delete All and character unlocks

expected: After "Delete All Data", character ownership (which characters you've unlocked) persists in the full collection list — only the currently-active/displayed character pointer resets to the default, matching the one-time-permanent unlock decision (D-05).
result: pass
note: Confirmed via user disambiguation — previously-unlocked characters still show as owned in the full collection list; only the active/selected pointer (App Group UserDefaults, shared with the widget) reset. This overturns the milestone audit's DATA-01 finding, which read the source-level absence of a CharacterUnlock delete call as a defect without accounting for this being a separate, correctly-persisted ownership store.

### 3. Date-range delete only removes the selected range

expected: In the data history/delete screen, choose to delete only "Last 7 days" (not everything). After it completes, measurements from the last 7 days are gone but older measurements are still there.
result: pass

### 4. Export size cap rejects oversized exports

expected: If you have (or can simulate having) more than 10,000 stress measurements or a dataset that would exceed ~10MB, attempting to export shows a clear error message rather than silently producing a huge file or hanging.
result: pass
note: "Fast-forwarded — user said \"pass all\" rather than confirming individually. Lower confidence than the individually-confirmed tests above."

### 5. Factory Reset wipes everything including characters

expected: Factory Reset (the separate, more destructive action from Delete All — usually in an "advanced"/danger-zone settings area) resets measurements, preferences, AND character unlocks back to default.
result: pass
note: "Fast-forwarded — user said \"pass all\" rather than confirming individually. Lower confidence than the individually-confirmed tests above."

### 6. Two-device CloudKit sync + Keychain sign-out check

expected: |
  On two real devices signed into the same iCloud account: take a measurement on device A,
  confirm it syncs to device B, run "Delete all snapshots" on device A, confirm the record
  disappears from device B's history and its widget within a sync window, and confirm device A's
  chat entry point shows no live session afterward.
result: [pending]
note: "This is Task 4 of 02-01-PLAN.md, a blocking checkpoint that was deferred at execution time rather than resolved — carried forward from 02-VERIFICATION.md."

### 7. Execute DataDeletionConsolidationTests.swift on a working simulator/device

expected: |
  Run the full test file (or at minimum DataDeleterFailureAndCancellationTests) on a host where
  `xcodebuild test` can complete a launch session. All 12 tests pass, including the two
  cancellation-ordering regression tests added this session.
result: [pending]
note: "This host's CoreSimulator cannot complete a test launch (\"No matching device ... in set at .../XCTestDevices\"), a pre-existing, reproducible environment issue independent of this phase's code — confirmed across phase 01/01.1 verification and again in this session."

### 8. Add and run a regression test for CR-01 (CloudKit batch-delete failure propagation)

expected: |
  Introduce a test seam below CloudKitResetServiceProtocol (e.g. an injectable CKDatabase/operation
  double) that fails modifyRecordsResultBlock, then assert CloudKitResetService.deleteRecords(ofType:)
  throws instead of reporting success. The test fails against the pre-fix code and passes against
  current code.
result: [pending]
note: "CR-01 was a genuine critical bug found by this session's own code review (CloudKit batch-delete failures silently reported as success) — fixed at CloudKitResetService.swift:368 and confirmed correct by direct code inspection, but ships with zero automated regression coverage today."

## Summary

total: 8
passed: 5
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps

Tests 6-8 (carried forward from 02-VERIFICATION.md's human_verification section) are pending —
require two real iCloud-signed devices (test 6), a host where xcodebuild test can actually launch
a simulator (test 7), or new test-seam design work beyond this session's scope (test 8). Tests 1-5
(the pre-existing UAT) passed against the code as it stood before this session's 3 code-review/fix
iterations; none of those iterations touched the behavior tests 1-5 cover.
