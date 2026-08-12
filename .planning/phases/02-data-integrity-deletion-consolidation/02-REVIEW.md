---
phase: 02-data-integrity-deletion-consolidation
reviewed: 2026-08-12T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift
  - StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift
  - StressMonitor/StressMonitor/Services/DataManagement/CloudKitResetService.swift
  - StressMonitor/StressMonitor/Services/DataManagement/LocalDataWipeService.swift
  - StressMonitor/StressMonitor/Services/DataManagement/DataDeleter.swift
  - StressMonitor/StressMonitor/Views/Settings/DataManagement/DataManageView.swift
  - StressMonitor/StressMonitor/Views/Settings/DataManagement/DataDeleteView.swift
  - StressMonitor/StressMonitor/Views/Settings/DataManagement/DataExportView.swift
  - StressMonitor/StressMonitor/Services/CloudKit/CloudKitSchema.swift
findings:
  critical: 1
  warning: 4
  info: 4
  total: 9
status: issues_found
---

# Phase 02: Code Review Report (Pass 3)

**Reviewed:** 2026-08-12
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

This is the third review pass. The five iteration-2 fixes were re-verified against the actual code (not just the fix report) and **all five hold**:

1. `CloudKitResetServiceProtocol` DI seam (`cbf023d`) — protocol, `CloudKitResetService`, and the test double `FakeCloudKitResetService` all have matching signatures; `DataDeleterService` has both a `CKContainer`-based convenience initializer and a direct protocol-injecting initializer. Confirmed wired correctly.
2. `LocalizedError` conformance (`505d7a6`) — `CloudKitResetError`, `LocalDataError`, `DeletionError`, and `ExportError` all implement `errorDescription`. Confirmed present.
3. Cancel-mid-delete split-brain fix — `deleteAllMeasurements()` and the scoped `deleteMeasurements(in:includeLocal:includeCloud:)` both call `Task.checkCancellation()` once, before the CloudKit phase, and have no further cancellation checks between the CloudKit and local phases. This correctly guarantees that once CloudKit deletion has started, local deletion always follows (matches the two dedicated regression tests). Confirmed.
4. `deleteAllMeasurements()`/`performFactoryReset()` correctly gate `clearCredentialsAndSharedCaches()` behind full-success paths only.
5. `CloudKitEncryptionTests` still validates that health fields round-trip through `encryptedValues` and are absent from plaintext CKRecord keys.

However, this pass is not a rubber stamp. A fresh read of `CloudKitResetService.swift` (not part of the iteration-1/2 fix set, and never exercised by the `CloudKitResetServiceProtocol` fake) surfaced a genuine, previously-unreported **data-loss/privacy bug**: CloudKit batch-delete failures are silently swallowed and reported as success (CR-01 below). This means the "Delete all data" / factory-reset promise the app makes to the user is not actually guaranteed on the CloudKit side, and no existing test can catch it because the test seam bypasses `CloudKitResetService`'s internals entirely.

A handful of secondary issues (cancellation-fix inconsistency across sibling methods, a UI progress-mirroring race, a missing `Sendable` conformance on the new test double, and some dead code) round out the findings.

## Critical Issues

### CR-01: CloudKit batch-delete failures are silently swallowed and reported as success

**File:** `StressMonitor/StressMonitor/Services/DataManagement/CloudKitResetService.swift:368`
**Issue:**
```swift
let deletedInBatch = (try? await performModifyOperationHelper(operation: operation, database: database, batchCount: batch.count)) ?? batch.count
totalDeleted += deletedInBatch
```
`performModifyOperationHelper` is the only fallible call in `deleteBatchRecords`. Converting its result with `try?` and falling back to `?? batch.count` means: if the `CKModifyRecordsOperation` genuinely fails (network drop, quota exceeded, permission/zone error, partial failure with `isAtomic = false`), the code assumes the *entire* batch was deleted anyway. `deleteBatchRecords` itself is declared `async throws` but, with this pattern, it can never actually throw for a CloudKit-side failure — only `Task.sleep` cancellation can throw out of this loop. As a result:
- `deleteRecords(ofType:...)` never sees the failure and logs `"Successfully deleted N ... records"`.
- `DataDeleterService.deleteAllMeasurements()` reports `"Successfully deleted all measurements from both storage locations"`.
- `DataManageView.performDeleteAll()` shows the user `"All stress snapshots were deleted."`.
- The same path is reused by `performDatabaseReset()` / `resetCloudKitData()` / factory reset.

A user who explicitly asked to delete their data (or invoked "Delete all" for privacy reasons) can be told deletion succeeded while the records still exist in their private CloudKit database. This is exactly the kind of "feature-complete but not actually working" defect this milestone's remediation is meant to close, and it is completely untested: `DataDeletionConsolidationTests.swift` only exercises `CloudKitResetServiceProtocol` through the `FakeCloudKitResetService` seam, which bypasses `CloudKitResetService.deleteBatchRecords` entirely, so this bug cannot be caught by the current test suite regardless of how thorough it looks.

**Fix:** Propagate the failure instead of defaulting to "success":
```swift
for (index, batch) in batches.enumerated() {
    let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: batch)
    operation.isAtomic = false

    let deletedInBatch = try await performModifyOperationHelper(
        operation: operation, database: database, batchCount: batch.count
    )
    totalDeleted += deletedInBatch
    ...
}
```
and let the existing `catch let error as CKError` / `catch` blocks in `deleteRecords(ofType:...)` map it to `CloudKitResetError` as they already do for the fetch phase. If partial-batch failures need to be tolerated deliberately, that has to be an explicit, logged decision (e.g. collect failed IDs and surface a `CloudKitResetError.partialDeletionFailure(remaining: [CKRecord.ID])`), not a silent `?? batch.count`. Add a test that injects a `CKDatabase`/operation double which fails `modifyRecordsResultBlock`, to prove `deleteRecords(ofType:...)` now surfaces the failure.

## Warnings

### WR-01: Delete progress UI can silently never animate due to a Task-ordering race

**File:** `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataDeleteView.swift:418-444`
**Issue:**
```swift
let progressMirror = Task { @MainActor in
    while service.isDeleting {
        self.deleteProgress = service.deleteProgress
        self.currentOperation = service.currentOperation ?? ""
        try? await Task.sleep(for: .milliseconds(50))
    }
}
...
let deletionTask = Task {
    if scope == .everything && isAllTime {
        try await service.deleteAllMeasurements()
    } else { ... }
}
```
`progressMirror` is created and enqueued *before* `deletionTask`. `service.isDeleting` only flips to `true` once `deletionTask`'s body actually starts executing `deleteAllMeasurements()`/`deleteMeasurements(...)`. If the `progressMirror` job runs first on the MainActor executor (plausible, since it was enqueued first and both are non-detached `@MainActor`-affine tasks), its `while service.isDeleting` check reads `false` and the loop body never executes even once — the task exits immediately, and the progress ring/label never updates until the final `deleteProgress = 1.0` / `"Delete complete"` assignment after `try await deletionTask.value` returns. The deletion itself still completes correctly (this doesn't affect CR-01/data-loss), but the "0% → 100%" progress UI silently becomes a no-op, contradicting the intent of `ExportProgressBarView`/the circular progress indicator in `DataDeleteView`.
**Fix:** Create `deletionTask` first, or explicitly wait for `service.isDeleting == true` (or a small pre-flight `await Task.yield()`) before starting the polling loop, e.g.:
```swift
let deletionTask = Task { ... }
cancellationToken = deletionTask
let progressMirror = Task { @MainActor in
    repeat {
        self.deleteProgress = service.deleteProgress
        self.currentOperation = service.currentOperation ?? ""
        try? await Task.sleep(for: .milliseconds(50))
    } while service.isDeleting
}
```
using `repeat/while` (post-condition) removes the dependency on which task's first iteration runs first.

### WR-02: The "no split-brain" cancellation fix was not mirrored to sibling deletion methods

**File:** `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift:132-242, 320-360`
**Issue:** `deleteAllMeasurements()` and `deleteMeasurements(in:includeLocal:includeCloud:)` both got the iteration-2 treatment: a `try Task.checkCancellation()` checkpoint immediately before the CloudKit phase, and a `catch is CancellationError` clause mapping to `DeletionError.operationCancelled`. The unscoped `deleteMeasurements(before:)` (lines 132-184), the unscoped `deleteMeasurements(in:)` (lines 186-242), and `resetCloudKitData(confirmation:)` (lines 320-360) do **not** have either — no pre-CloudKit cancellation checkpoint and no explicit `CancellationError` catch (a stray cancellation would fall into the final generic `catch { throw DeletionError.repositoryError(error) }`, which is a misleading error type for a cancellation). These three methods are currently unreachable from any UI in the app (confirmed via repo-wide grep — nothing calls them except the `DataDeleter` protocol's own default-argument wrappers), so there is no live user-facing risk today, but they are public API on `DataDeleterService`/`DataDeleter` and the very next feature that wires one of them up will silently reintroduce the bug class iteration 2 just fixed, with no comment warning them why the checkpoint matters.
**Fix:** Either delete the three unused methods (`deleteMeasurements(before:)`, unscoped `deleteMeasurements(in:)`, `resetCloudKitData`) if they're genuinely obsolete now that the scoped variant covers their use cases, or apply the same `try Task.checkCancellation()` + `catch is CancellationError` pattern used in `deleteAllMeasurements()` for consistency.

### WR-03: `FakeCloudKitResetService` conforms to a `Sendable`-requiring protocol without declaring `Sendable`

**File:** `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift:175-217`
**Issue:** `CloudKitResetServiceProtocol` is declared `@MainActor protocol CloudKitResetServiceProtocol: Sendable`. `FakeCloudKitResetService` is a `final class` with a mutable `var behavior: Behavior` and conforms to that protocol, but is declared only as `@MainActor final class FakeCloudKitResetService: CloudKitResetServiceProtocol` — no `Sendable` or `@unchecked Sendable`. The project's own established convention (per repo docs) is that mutable-state mocks/fakes explicitly opt in with `@unchecked Sendable` (e.g. `MockHealthKitService`, `SimulatorHealthKitService`). Swift does not implicitly synthesize `Sendable` for classes regardless of `@MainActor` isolation or finality; whether this currently compiles clean depends on the test target's concurrency-checking level (the project builds under `SWIFT_VERSION = 5.0` with `SWIFT_APPROACHABLE_CONCURRENCY = YES` but no explicit `SWIFT_STRICT_CONCURRENCY = complete`, so this is likely a warning today rather than a hard error) — but it is inconsistent with the codebase's own convention and is one settings change away from becoming a build break.
**Fix:** Add an explicit conformance for clarity and future-proofing:
```swift
@MainActor
final class FakeCloudKitResetService: CloudKitResetServiceProtocol, @unchecked Sendable {
```

### WR-04: Scoped deletion's cancellation-ordering fix has no dedicated regression test

**File:** `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift` (whole file) / `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift:250-316`
**Issue:** `DataDeleterFailureAndCancellationTests` (the suite that validates "no split-brain") only exercises `deleteAllMeasurements()`. The scoped `deleteMeasurements(in:includeLocal:includeCloud:)` — the method actually invoked by `DataDeleteView`'s primary user-facing flow for anything other than "everything, all time" — implements the identical `Task.checkCancellation()` + no-further-checks pattern (lines 274-297) but has zero test coverage for the cancellation-ordering behavior specifically. `DataDeleterScopedDeletionTests` only covers the `includeLocal`/`includeCloud` gating, not cancellation timing.
**Fix:** Add a `FakeCloudKitResetService`-based test analogous to `cancellationAfterCloudKitStartsStillDeletesLocal`/`cancellationBeforeCloudKitStartsAbortsOperation`, but calling `deleteMeasurements(in:includeLocal:true,includeCloud:true)` instead of `deleteAllMeasurements()`, so the actually-used code path is the one under regression protection.

## Info

### IN-01: `DeleteError` enum is unused dead code with a name that invites confusion with `DeletionError`

**File:** `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataDeleteView.swift:474-484`
**Issue:** `enum DeleteError: LocalizedError { case noData, operationFailed ... }` is defined but never thrown or caught anywhere in the codebase (confirmed via grep). It sits a few hundred lines away from the actually-used `DeletionError` (defined in `DataDeleter.swift`), and the near-identical name is a maintenance trap for whoever edits this file next.
**Fix:** Delete `DeleteError` unless there's a near-term plan to use it.

### IN-02: `CloudKitResetService`'s progress-tracking properties are dead state

**File:** `StressMonitor/StressMonitor/Services/DataManagement/CloudKitResetService.swift:30-38`
**Issue:** `isDeleting`, `deleteProgress`, `currentOperation`, and `recordsDeleted` are maintained throughout the class but `CloudKitResetServiceProtocol` doesn't expose them, and nothing outside this file reads them (confirmed via grep) — `DataDeleterService` tracks its own `isDeleting`/`deleteProgress`/`currentOperation` independently and never reads these. They add bookkeeping overhead for no observable benefit.
**Fix:** Either remove the unused properties or expose them via the protocol if a future caller is expected to observe fine-grained CloudKit-only progress.

### IN-03: `DataExportView` repeats six near-identical `.onChange` blocks

**File:** `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataExportView.swift:59-88`
**Issue:** Six separate `.onChange(of: viewModel.<field>) { _, _ in Task { await viewModel.loadPreviewData(modelContext: modelContext) } }` blocks differ only in which field they observe. This is a maintainability smell — any future toggle added to the export view requires remembering to add a seventh copy of this boilerplate.
**Fix:** Consider a single computed "export selection changed" signal (e.g. combine the relevant `@Observable` fields into one derived value, or debounce via `.onChange` of a single tuple/hash) to reduce duplication.

### IN-04: Three `DataDeleter` protocol methods are unreachable from any UI

**File:** `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift:132-242, 320-360`
**Issue:** `deleteMeasurements(before:)`, the unscoped `deleteMeasurements(in:)`, and `resetCloudKitData(confirmation:)` are never called from any View or ViewModel in the app (only from their own protocol default-argument wrappers and their own declarations). Combined with WR-02, this is inert surface area that increases the chance of a future regression if wired up without re-applying the cancellation fix.
**Fix:** See WR-02 — remove if unused, or bring to parity and add a call site/test if they're meant to stay.

---

_Reviewed: 2026-08-12_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
