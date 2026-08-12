---
phase: 02
fixed_at: 2026-08-12T09:34:36Z
review_path: .planning/phases/02-data-integrity-deletion-consolidation/02-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 02: Code Review Fix Report

**Fixed at:** 2026-08-12T09:34:36Z
**Source review:** `.planning/phases/02-data-integrity-deletion-consolidation/02-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope (Critical + Warning, per `fix_scope=critical_warning`): 7 (CR-01..CR-04, WR-01..WR-03)
- Fixed: 7
- Skipped: 0
- Out of scope (Info, not attempted per `fix_scope`): IN-01, IN-02, IN-03, IN-04

## Fixed Issues

### CR-03: `DataDeleterService` swallows CloudKit-specific errors into a generic wrapper

**Files modified:** `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift`
**Commit:** `65a5881`
**Applied fix:** Added the missing `catch let error as CloudKitResetError { throw DeletionError.cloudKitError(error) }` clause to `deleteAllMeasurements`, `deleteMeasurements(before:)`, and `deleteMeasurements(in:)`, matching the pattern already used by `resetCloudKitData`/`performFactoryReset`. Also added `Task.checkCancellation()` checkpoints and a `catch is CancellationError` clause in `deleteAllMeasurements` in support of WR-01. This was fixed first because CR-01's message fix depends on the `.cloudKitError` branch actually being reachable from `deleteAllMeasurements`.

### CR-01: Recovery messages in `DataManageView` assumed the old local-first delete order

**Files modified:** `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataManageView.swift`
**Commit:** `14d538f`
**Applied fix:** Reworded both `.cloudKitError` catch messages in `performDeleteAll` and `performFactoryReset` to reflect the actual CloudKit-first phase order in `DataDeleterService` (CloudKit deletion runs first; on failure, local storage/credentials are never touched, since phase 2 is never reached). Previously the messages claimed local data/credentials had already been cleared — now they correctly state local data was **not** touched.

### CR-02: `.localOnly`/`.cloudOnly` delete scope was never enforced

**Files modified:**
- `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift`
- `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataDeleteView.swift`

**Commits:** `65a5881` (new scoped method), `b531522` (wiring)
**Applied fix:** Added a new additive `DataDeleterService.deleteMeasurements(in:includeLocal:includeCloud:confirmation:)` overload that only touches the CloudKit store when `includeCloud` is true and only touches local SwiftData (and resets the local baseline) when `includeLocal` is true — the existing protocol-required `deleteMeasurements(in:confirmation:)` overload was left untouched to avoid breaking `DataDeleter` conformance. `DataDeleteViewModel.performDelete` now calls the new overload with `includeLocal: deleteScope != .cloudOnly` and `includeCloud: deleteScope.includesCloud`, so "Local Only" no longer touches CloudKit and "Cloud Only" no longer touches local storage — matching the promise made in `DeleteConfirmationView`'s `warningMessage`.

### WR-01: `cancelDelete()` was a complete no-op

**Files modified:** `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataDeleteView.swift`
**Commit:** `c9e2797`
**Applied fix:** Changed `cancellationToken` from `Task<Void, Never>?` to `Task<Void, Error>?`, and `performDelete(modelContext:)` now runs the actual deletion call inside a `Task` assigned to `cancellationToken` before `await`-ing its `.value`. `cancelDelete()` now cancels a real in-flight `Task`. Cooperative cancellation checkpoints (`Task.checkCancellation()`) were added at the CloudKit/local phase boundaries in `DataDeleterService` (see CR-03 commit) so a cancel between phases now actually aborts the remaining phase instead of running to completion; the resulting `CancellationError` is translated to `DeletionError.operationCancelled`, which `DataDeleteView.performDelete()` now catches silently (no error alert), consistent with how `DataManageView` already handles user-initiated cancellation.
**Note:** True mid-network-call cancellation of a single CloudKit query/batch delete is not possible without larger changes to `CloudKitResetService`/`LocalDataWipeService`; the fix makes cancellation effective at phase boundaries, which is the scope the finding described ("a complete no-op").

### WR-02: Two independent counting code paths for the same data

**Files modified:** `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataDeleteView.swift`
**Commit:** `87b3c5f`
**Applied fix:** `DataDeleteViewModel.loadAffectedCounts` previously hand-rolled its own `FetchDescriptor`/`modelContext.fetch` count; it now delegates to `DataDeleterService.getDeletionStats(in:)` (previously dead code per the finding), via a shared `makeDeleterService(modelContext:)` helper reused by both `loadAffectedCounts` and `performDelete`. `DataManageView.snapshotCount` was intentionally left as a synchronous `Text`-backed computed property — converting it to use the async service would require restructuring that view's state management, which is out of proportion for a Warning-level consolidation fix and risks introducing new bugs; this is noted here rather than silently left unaddressed.

### CR-04: Export "Data to Include" toggles had no effect; baseline never exported

**Files modified:** `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataExportView.swift`
**Commit:** `3445a47`
**Applied fix:** `generateCSV`/`generateCSVPreview`/`generateJSON`/`generateJSONPreview` now build their column/field list from `includeHRV`, `includeHeartRate`, and `includeStressLevels` via shared `csvHeaderColumns()`/`csvRow(for:)`/`jsonFields(for:)` helpers, instead of unconditionally emitting all four columns. `includeBaseline` now fetches the real `PersonalBaseline` via `StressRepository(modelContext:).getBaseline()` (only when the toggle is on, to avoid the extra round-trip otherwise) and appends it as a CSV "Baseline" section / JSON `"baseline"` key. The JSON top-level shape changed from a bare array to `{"measurements": [...], "baseline": {...}?}` to accommodate the optional baseline section — verified no other code in the repo parses this exported JSON. Also added `.onChange` handlers on the four toggles in `DataExportView` so the on-screen preview reflects toggle changes immediately (previously only date range and format triggered a preview refresh).

### WR-03: Zero test coverage of the actual consolidated deletion/export behavior

**Files modified:** `StressMonitor/StressMonitorTests/DataDeletionConsolidationTests.swift`
**Commit:** `d06d9c0`
**Applied fix:** Added two new test suites:
- `DataDeleterScopedDeletionTests` — exercises the new `deleteMeasurements(in:includeLocal:includeCloud:)` overload with `includeCloud: false` to verify local-only deletion actually empties the local store, and with `includeLocal: false, includeCloud: false` to verify local data survives when the scope excludes it. These are regression tests for CR-02 (the "Local Only"/"Cloud Only" no-op bug) that run entirely against an in-memory `ModelContext`, never invoking CloudKit network calls.
- `DataExportFieldSelectionTests` — exercises `DataExportViewModel.exportData` end-to-end (writes and reads back the real exported file) to verify disabled toggles omit their columns/fields from CSV output, and that the JSON `"baseline"` section only appears when `includeBaseline` is true. These are regression tests for CR-04.

**Scope note:** Regression coverage for CR-01/CR-03 (CloudKit failure during `deleteAllMeasurements`/`performFactoryReset` producing the correct, order-accurate message) was not added — it would require injecting a fake/mockable CloudKit layer, and `CloudKitResetService`/`LocalDataWipeService` are concrete classes with no protocol seam for that today. This is a legitimate follow-up (introducing a `CloudKitResetServiceProtocol` for testability) but is a larger structural change than a code-review-fix pass should make unprompted.

## Verification

- **Tier 1 (mandatory, all findings):** every modified file section was re-read after editing to confirm the fix text is present and surrounding code is intact.
- **Tier 2 (stronger than the standard syntax-check bar):** ran `xcodebuild build-for-testing` for the full `StressMonitor` scheme (app + watch + widget + `StressMonitorTests` targets, `iOS Simulator` destination) inside the isolated worktree — **`** TEST BUILD SUCCEEDED **`**. This performs full Swift type-checking and linking of every file touched by this fix pass, including the new/changed public API surface (`deleteMeasurements(in:includeLocal:includeCloud:)`, the reworked `DataExportViewModel` field-selection helpers, and the new test suites).
- **Test execution:** attempted `xcodebuild test-without-building` against a booted iOS 26.2 simulator three times; all three attempts failed with simulator-infrastructure errors (`Mach error -308 (ipc/mig) server died`, stale device UDID in `XCTestDevices`) unrelated to the code changes — this sandboxed environment could not sustain a running simulator test session for the ~2+ minutes XCTest needed. The new tests were logically walked through by hand (in-memory `ModelContainer`, no network calls when `includeCloud`/no-toggle paths are exercised) and compile/link cleanly against the real production types; they could not be executed to a pass/fail result in this environment. Recommend re-running `StressMonitorTests` (or just the two new suites) in a normal Xcode/CI environment before merging.
- No finding required rollback; no logic-only findings were flagged as "requires human verification" beyond the test-execution caveat above.

## Skipped Issues

None — all 7 in-scope findings were fixed. IN-01 through IN-04 were out of scope for this pass (`fix_scope=critical_warning`) and were not attempted; they remain open in `02-REVIEW.md` for a future `--fix-scope=all` pass or manual follow-up.

---

_Fixed: 2026-08-12T09:34:36Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
