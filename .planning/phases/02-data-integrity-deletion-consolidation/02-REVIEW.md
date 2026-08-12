---
phase: 02-data-integrity-deletion-consolidation
reviewed: 2026-08-12T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift
  - StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift
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

# Phase 02: Code Review Report (Re-Review)

**Reviewed:** 2026-08-12
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

This is a fresh re-review of the six files after the prior round's CR-01..CR-04 / WR-01..WR-03 fixes (commits 65a5881, 14d538f, b531522, c9e2797, 87b3c5f, 3445a47, d06d9c0). I verified each of the seven prior fixes directly against the current source and confirmed all seven are genuinely resolved:

- **CR-01** (stale CloudKit-first-order messaging) — fixed. `DataManageView.swift:170,185` now correctly say local data was *not* touched when the CloudKit phase fails.
- **CR-02** (scope picker not enforced) — fixed. `DataDeleteViewModel.performDelete` now threads `includeLocal`/`includeCloud` from `DataDeleteScope` into `DataDeleterService.deleteMeasurements(in:includeLocal:includeCloud:)`, and `DataDeleterScopedDeletionTests` locks in both directions.
- **CR-03** (CloudKit errors swallowed as generic `.repositoryError`) — fixed. `deleteAllMeasurements`, `deleteMeasurements(before:)`, and the unscoped `deleteMeasurements(in:)` now all have a dedicated `catch let error as CloudKitResetError` clause.
- **CR-04** (export toggles had no effect) — fixed. `csvHeaderColumns`/`csvRow`/`jsonFields` now gate on `includeHRV`/`includeHeartRate`/`includeStressLevels`, and baseline sections are only emitted when `includeBaseline` is set. `DataExportFieldSelectionTests` covers this directly.
- **WR-01** (`cancellationToken` never assigned) — fixed. `DataDeleteViewModel.performDelete` now assigns the `deletionTask` to `cancellationToken`.
- **WR-02** (dead stats methods / duplicate counting) — **partially** fixed; see WR-02 below, reopened as a residual finding.
- **WR-03** (no tests for the risky paths) — **partially** fixed; the new suite covers CR-02 and CR-04 well but still has no coverage for the CloudKit-failure-ordering paths or cancellation, see WR-03 below.

While verifying the fixes, adversarial re-reading of the "fixed" cancellation/error-propagation code turned up one new correctness bug that undermines the phase's own data-integrity goal (a cancel-mid-delete split-brain state), plus a subtler but consequential defect in how CloudKit/local error detail is (or isn't) actually surfaced to the user despite CR-01/CR-03. Findings below.

## Critical Issues

### CR-01: Cancelling a delete mid-flight can leave CloudKit and local storage out of sync

**File:** `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift:73-84` (also `268-290`)
**Issue:**
`deleteAllMeasurements` (and the scoped `deleteMeasurements(in:includeLocal:includeCloud:)` used by the "Delete by range" flow) delete from CloudKit first, then call `try Task.checkCancellation()`, and only then delete from local storage:

```swift
try await cloudKitResetService.deleteRecords(ofType: .stressMeasurement, expectedProgress: 0.1...0.4)
try Task.checkCancellation()          // <-- cancellation observed here
try await localWipeService.deleteAllMeasurements()
```

`DataDeleteView`'s toolbar "Cancel" button, while `isDeleting` is true, calls `viewModel.cancelDelete()`, which cancels the exact `Task` running this code (`DataDeleteViewModel.swift:440-443`, wired via WR-01's fix). `Task.cancel()` is cooperative — it does not abort the in-flight CloudKit network call — so if the user taps Cancel while `cloudKitResetService.deleteRecords` is executing, that call still runs to completion (CloudKit data is now gone), and only the *next* checkpoint (`Task.checkCancellation()`) throws, aborting before `localWipeService` ever runs. The user asked to stop the deletion and instead gets an irreversible partial deletion: CloudKit measurements removed, local measurements intact, with no indication that anything happened (the UI just dismisses/returns on `DeletionError.operationCancelled`, per `DataDeleteView.swift:237-238`). This directly contradicts the phase's "data integrity" goal — the two stores can now silently diverge, which will also manifest as odd resync behavior next time CloudKit sync runs.

The same shape of bug exists in the scoped variant (`includeCloud` branch completes, `try Task.checkCancellation()` at line 280 aborts before the `includeLocal` branch).

**Fix:** Treat "CloudKit deletion has started" as a point of no return — don't check cancellation between the two phases; only check cancellation *before* any network/storage call begins:

```swift
try Task.checkCancellation()   // last safe checkpoint before the operation becomes irreversible
try await cloudKitResetService.deleteRecords(ofType: .stressMeasurement, expectedProgress: 0.1...0.4)
try await localWipeService.deleteAllMeasurements()   // always run once CloudKit succeeded, no cancellation gate here
```
Apply the same change to `deleteMeasurements(in:includeLocal:includeCloud:)` (remove the `try Task.checkCancellation()` at line 280, between the CloudKit and local blocks). If genuine mid-flight cancellation of the CloudKit call itself is desired, that has to be implemented via `CKOperation.cancel()`/cooperative checks inside `CloudKitResetService`, not via a `Task.checkCancellation()` checkpoint placed *after* the call already returned.

## Warnings

### WR-01: CloudKit/local failure detail never reaches the user despite CR-01/CR-03's fix

**File:** `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataManageView.swift:169-175, 184-190`; `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataDeleteView.swift:237-245`; `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift` (all `errorMessage = error.localizedDescription` sites)
**Issue:**
`CloudKitResetError` and `LocalDataError` each hand-write a `var localizedDescription: String` computed property (e.g. `CloudKitResetService.swift:491-514`), but **neither conforms to `LocalizedError`**, and `DeletionError` (`DataDeleter.swift:39-44`) is declared as:

```swift
enum DeletionError: Error {
    case repositoryError(Error)
    case cloudKitError(Error)   // payload typed as `Error`, not `CloudKitResetError`
    ...
}
```

A type's own ad-hoc `localizedDescription` property is only visible when the *static* type of the value is known to be that concrete type. Once a `CloudKitResetError` is boxed into `DeletionError.cloudKitError(Error)` and later unwrapped through a `catch let DeletionError.cloudKitError(cloudKitError)` pattern, `cloudKitError`'s static type is `Error` (per the case's declared payload type) — so `cloudKitError.localizedDescription` resolves through Foundation's `Error → NSError` bridging, which only special-cases `LocalizedError`/`CustomNSError` conformances. Since neither `CloudKitResetError` nor `DeletionError` conforms to `LocalizedError`, this produces Foundation's generic fallback string ("The operation couldn't be completed…") instead of the carefully-written message ("iCloud account is not available", "Network is unavailable", etc.).

Concretely:
- `DataManageView.swift:170` — `"iCloud data couldn't be removed (\(cloudKitError.localizedDescription))..."` will show the generic NSError string, not the actual CloudKit failure reason, defeating the entire point of CR-01/CR-03's fix.
- `DataDeleteView.swift:239-244` — the catch-all `catch { errorMessage = error.localizedDescription; ... }` never even pattern-matches on `DeletionError` cases (unlike `DataManageView`), so *every* deletion failure in the primary "Delete by range" screen — local or cloud, whatever the cause — shows the same generic Foundation string. CR-03's careful error-type differentiation at the service layer has zero observable effect in this screen.
- Inside `DataDeleterService` itself, the concretely-typed catch clauses (`catch let error as CloudKitResetError`) *do* get the correct message when setting the service's own `errorMessage` — but see WR-04, nothing reads that property.

**Fix:** Conform `CloudKitResetError`, `LocalDataError`, and `DeletionError` to `LocalizedError` (rename the existing `localizedDescription` switches to `errorDescription: String?`). For `DeletionError.cloudKitError`/`.repositoryError`, this alone is enough — once the *boxed* `CloudKitResetError`/`LocalDataError` conform to `LocalizedError`, Foundation's bridging will find `errorDescription` dynamically even through the `Error` existential. Additionally, give `DataDeleteView.swift` a `catch let DeletionError.cloudKitError(...)` / `.repositoryError(...)` branch mirroring `DataManageView`, so local-vs-cloud failures are distinguishable in that screen too.

### WR-02 (residual from prior review): dead deletion/count API surface only partially closed

**File:** `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift:117-173, 316-360, 431-452`; `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataManageView.swift:148-151`
**Issue:** `getDeletionStats(in:)` is now wired up (`DataDeleteViewModel.loadAffectedCounts` calls it) — real progress since the last review. But `deleteMeasurements(before:)`, the unscoped `deleteMeasurements(in:)`, `resetCloudKitData`, `getDeletionStats(before:)`, and `getTotalCount()` are still never called by any view/viewmodel (verified via repo-wide grep). `DataManageView.snapshotCount` (line 148-151) still hand-rolls its own `FetchDescriptor<StressMeasurement>()` + `fetchCount` instead of calling `getTotalCount()`, which exists on `DataDeleterService` for exactly this purpose — the "two independent counting code paths for the same data" problem from the original WR-02 is still present, just one layer smaller.
**Fix:** Either wire `DataManageView.snapshotCount` through `DataDeleterService.getTotalCount()` (consistent with how `DataDeleteView` now uses `getDeletionStats(in:)`), or delete the still-unused methods (`deleteMeasurements(before:)`, unscoped `deleteMeasurements(in:)`, `resetCloudKitData`, `getDeletionStats(before:)`) if there's no near-term caller, per YAGNI.

### WR-03 (residual from prior review): risky ordering/cancellation paths still untested

**File:** `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift`
**Issue:** The new `DataDeleterScopedDeletionTests` and `DataExportFieldSelectionTests` suites are solid, targeted regression coverage for CR-02 and CR-04. However, there is still no test that (a) simulates a `CloudKitResetError` thrown mid-`deleteAllMeasurements`/mid-`performFactoryReset` to lock in CR-01's/CR-03's fixed behavior (message accuracy, correct error-case propagation), or (b) cancels the deletion `Task` mid-flight to catch the split-brain regression described in CR-01 above. Both would require a fake/mock `CloudKitResetService` seam, which doesn't currently exist (the service is constructed concretely inside `DataDeleterService.init`).
**Fix:** Introduce a `CloudKitResetServiceProtocol` (mirroring the existing `StressRepositoryProtocol`/`HealthKitServiceProtocol` DI pattern) so tests can inject a failing/cancellable fake and assert on the resulting `DeletionError` case and on-disk state after cancellation.

### WR-04: `DataDeleterService.errorMessage` is fully maintained but never read

**File:** `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift:19, 96, 100, 107, 161, 165, 169, 223, 227, 231, 297, 301, 308, 348, 352, 356, 412, 416, 420, 469-471`
**Issue:** Every one of the five public methods sets `self.errorMessage` in every catch branch (13 call sites), and `clearError()` exists to reset it — real, deliberate effort. But no caller (`DataManageView`, `DataDeleteView`, `DataDeleteViewModel`) ever reads `service.errorMessage`; both views construct a fresh, short-lived `DataDeleterService` per action and instead handle the *thrown* error directly at the call site. This is dead published state that could mislead a future maintainer into thinking they can observe `errorMessage` as an alternative to catching the throw (they can't — the two paths currently diverge in content per WR-01 above, compounding the confusion).
**Fix:** Either remove `errorMessage`/`clearError()` from `DataDeleterService` (simplify per YAGNI — the throw is already the source of truth), or actually bind a view to it instead of maintaining a parallel `@State private var errorMessage` in each screen.

## Info

### IN-01 (residual): `DeleteError` enum still dead code

**File:** `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataDeleteView.swift:462-471`
**Issue:** `enum DeleteError { case noData, operationFailed }` is declared but never thrown or caught anywhere in the file (confirmed unchanged since the prior review).
**Fix:** Delete it, or use it where `viewModel.performDelete` currently just propagates whatever `DataDeleterService` throws.

### IN-02 (residual): unused `ExportError` cases

**File:** `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataExportView.swift:584-608`
**Issue:** `.noData`, `.fileWriteFailed(Error)`, and `.invalidPath` are declared but never thrown in this flow (only `.exceedsSizeCap`, `.fileAccessFailed`, and `.encodingFailed` are actually used, confirmed unchanged since the prior review).
**Fix:** Remove the unused cases, or throw `.noData` from `exportData` when `records.isEmpty` (currently an empty export silently produces a header-only CSV / empty-array JSON rather than surfacing anything to the user).

### IN-03 (residual): progress-mirroring task still races the deletion task it observes

**File:** `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataDeleteView.swift:406-418`
**Issue:** `progressMirror` and `deletionTask` are both freshly-created `Task {}`s with no ordering guarantee; `progressMirror`'s `while service.isDeleting { ... }` loop can observe `isDeleting == false` and exit immediately if it happens to run before `deletionTask` sets it `true`. Unchanged since the prior review's IN-04 — noted here as still relevant given the CR-01 cancellation fix above now depends on this same task-timing behavior more than before.
**Fix:** Bind the view directly to the `@Observable` `DataDeleterService` instance (pass it into the view/viewmodel instead of creating it fresh per-call and polling its state via a separate task), or await `deletionTask` while updating progress from within `deletionTask`'s own body rather than a sibling task.

### IN-04: cosmetic phase-percentage comments don't match the values they annotate

**File:** `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift:69-82, 385-401`
**Issue:** Comments like `// Phase 1: Delete from CloudKit (0% - 40%)` are followed by `deleteProgress = 0.1`, and `// Phase 2: Delete from local storage (40% - 100%)` is followed by `deleteProgress = 0.5` — the stated ranges don't match the assigned values (repeats in `performFactoryReset`'s phase comments too). Purely cosmetic; no functional impact.
**Fix:** Align the comments with the actual `deleteProgress` values, or drop the percentage annotations from the comments.

---

_Reviewed: 2026-08-12_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
