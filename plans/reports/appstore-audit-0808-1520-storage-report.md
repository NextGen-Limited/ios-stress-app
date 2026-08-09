# Storage & Data Management Audit — StressMonitor (App Store publish readiness)

**Date:** 2026-08-08
**Scope:** file storage / data management dimension, App Store submission readiness
**Branch:** feature/spm-cache-integration
**Auditor:** axiom storage-auditor

> Persisted by the orchestrator — the audit run had no Write tool available.

## Storage Map

- **Locations:** SwiftData store → default location (Application Support, correctly backed up —
  health measurements are original data, not regenerable). Exports → `Caches/` (live path) and
  `tmp/` (dead-code path). App Group UserDefaults → **3 different suite IDs**, none backed by an
  actual entitlement.
- **App Group:** Required by widget + watch complications, but **no
  `com.apple.security.application-groups` key exists in any entitlements file**, and the widget
  target has no entitlements file at all.
- **Backup exclusion:** 0% explicit usage anywhere (`isExcludedFromBackup` never called) — not
  currently causing bloat, since nothing large sits in Documents/App Support outside the
  appropriately-backed-up SwiftData store, but no hygiene practice exists.
- **File protection:** 0% explicit `FileProtectionType` anywhere — health-derived plaintext
  exports (HRV/HR/stress) inherit only the default `.completeUntilFirstUserAuthentication`.
- **Secrets:** Supabase JWT correctly stored in Keychain
  (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) — good pattern, but never cleared on any
  user-facing "delete/reset" action.
- **App Group / extensions:** Widget + watch complications + character-selection sync all depend
  on App Group sharing, but the write side is either miswired (3 mismatched suite IDs) or never
  called at all (main-app→widget path is dead).

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 4 |
| HIGH | 2 |
| MEDIUM | 3 |
| LOW | 2 |
| **Total** | **11** |

## CRITICAL

### 1. No App Group entitlement anywhere

`StressMonitor/StressMonitor/StressMonitor.entitlements` and
`StressMonitor/StressMonitorWatch Watch App/StressMonitorWatch Watch App.entitlements` contain
only `com.apple.developer.healthkit`; the widget target has zero `CODE_SIGN_ENTITLEMENTS`
(confirmed via `project.pbxproj`). Yet `WidgetDataProvider.swift:45-47` calls `fatalError` if
`UserDefaults(suiteName:)` returns nil — real crash risk on-device without the capability.

### 2. Three mismatched App Group suite IDs, no single source of truth

- `group.com.stressmonitor.app` — `StressMonitorWidget/Models/WidgetDataProvider.swift:10`,
  `StressMonitor/Models/WidgetSharedData.swift:100`
- `group.com.stressmonitor.watch` —
  `.../Complications/Services/ComplicationDataProvider.swift:14`,
  `.../Models/WatchFacePreferences.swift:15`,
  `StressMonitor/ViewModels/CharacterCollectionViewModel.swift:86`
- `group.stress.ai.com` — `StressMonitorWatch Watch App/Services/WatchSharedDataStore.swift:16`

The doc comment at `WatchSharedDataStore.swift:7-10` falsely claims cross-process visibility to
iPhone widgets that does not exist.

### 3. iPhone home-screen widget is 100% disconnected from live data

`WidgetDataProvider.shared.saveLatestStress` / `saveHistory` / `saveBaseline` (write side,
`StressMonitorWidget/Models/WidgetDataProvider.swift:54-131`) is never called anywhere in the main
app target — repo-wide grep confirms it appears only in `README.md`.
`StressWidgetProvider.swift:41-56` always reads empty state and falls back to hardcoded
placeholder/sample entries forever.

### 4. Every user-reachable delete/reset flow is incomplete, and its own UI copy is false

- `DataManageView.performFactoryReset()`
  (`Views/Settings/DataManagement/DataManageView.swift:171-181`) only deletes `StressMeasurement`
  + `CharacterUnlock`; its comment falsely defers CloudKit/Keychain wipe to `DataDeleteView`.
- `DataDeleteViewModel.performDelete()` (`DataDeleteView.swift:398-451`) never calls CloudKit
  regardless of the user-chosen `.cloudOnly` / `.everything` scope; `deleteBaseline()`
  (`:458-464`) is a no-op stub.
- The correctly-built `DataDeleterService` / `CloudKitResetService` / `LocalDataWipeService` chain
  is dead code — the `DataManagementViewModel` that wires it is never instantiated anywhere.
- `SyncManager.swift` / `CloudKitSyncEngine.swift` never propagate local deletes to CloudKit
  (`CKModifyRecordsOperation(..., recordIDsToDelete: nil)` always nil).

Net effect: the UI string "This will permanently delete all data from iCloud"
(`DeleteConfirmationView.swift:98,253`) is **false**. App Group / widget / complication caches and
the Keychain JWT are never cleared either.

### Rating table — CRITICAL

| Finding | Urgency | Blast Radius | Fix Effort | ROI |
|---|---|---|---|---|
| #1 Missing App Group entitlement | Immediate — blocks widget/complications working at all on device | All 3 targets (app, widget, watch) | Low (add capability in Xcode + provisioning profile refresh) | Very High |
| #2 Mismatched App Group IDs | Immediate | Widget, watch complications, character sync | Low (pick one ID, update 5 files) | Very High |
| #3 Widget never fed real data | Immediate — reviewers will see a static/placeholder widget | Widget extension feature entirely | Medium (wire `StressViewModel`/`SyncManager` to call `WidgetDataProvider.save*` + `WidgetCenter.reloadAllTimelines()`) | Very High |
| #4 Deletion incomplete + misleading UI | Immediate — App Store privacy/data-deletion review risk, GDPR-style exposure | Every user who taps Delete/Factory Reset | Medium (wire existing `DataDeleterService` into the views, add App Group + Keychain clear, add CloudKit delete propagation) | Very High |

## HIGH

### 5. Health-derived exports unprotected, uncapped, never cleaned up

- Live path: `DataExportViewModel.exportData()`
  (`Views/Settings/DataManagement/DataExportView.swift:314-348`) writes plaintext HRV/HR/stress
  CSV/JSON to `.cachesDirectory` with no `FileProtectionType` and no cap/cleanup — epoch-named
  files accumulate indefinitely.
- Dead-code path: `DataManagementService.createTempFile()`
  (`Services/DataManagement/DataManagementService.swift:268-278`) writes the same class of data to
  `tmp/`; its own `cleanupTempFiles(olderThan:)` (`:282-294`) is defined but never called
  (grep-confirmed).

### 6. Two fully divergent DataExporter/DataDeleter implementations, correct one orphaned

`CSVGenerator` / `JSONGenerator` / `DataManagementService` / `DataDeleterService` /
`CloudKitResetService` are complete, well-built, and 100% dead code. The wired UI
(`DataExportView`, `DataManageView`, `DataDeleteView`) reimplements a simpler, incomplete version
from scratch — this is why the shipped feature regressed silently.

### Rating table — HIGH

| Finding | Urgency | Blast Radius | Fix Effort | ROI |
|---|---|---|---|---|
| #5 Unprotected/uncleaned health exports | Short-term | Every export action; `Caches/` retains files until OS purge | Low (add `.completeFileProtection` on write, cleanup after share sheet dismiss) | High |
| #6 Duplicate dead-code architecture | Short-term | Whole DataManagement subsystem | Medium (delete dead code OR retarget views onto the correct services — the latter also fixes #4) | High |

## MEDIUM

- CloudKit entitlements (`icloud-container-identifiers` / `icloud-services`) are also absent from
  both entitlements files; cross-reference `icloud-auditor` to confirm sync will even
  authenticate.
- `StressWidgetProvider.getTimeline`
  (`StressMonitorWidget/Providers/StressWidgetProvider.swift:40-65`) has no staleness check on
  `latestStress.timestamp`; stale data (even if #3 were fixed) would display indefinitely with no
  "no data" fallback.
- `WidgetSharedData.swift`'s `WidgetConstants` / `ComplicationSharedData` / `WidgetStressSnapshot`
  (main app target) are fully unused scaffolding tied to the widget disconnection above.

## LOW

- `CharacterIllustrationExporter.exportAll()`
  (`Services/CharacterIllustrationExporter.swift:36-91`) leaves the generated ZIP in `tmp/` after
  share with no cleanup call (non-sensitive character-art export, dev-facing feature).
- Zero explicit `isExcludedFromBackup` usage anywhere; not currently a violation, but no hygiene
  practice for any future regenerable content.

## Positive Findings (no action)

- `StressMonitorApp.swift:19-79` has a correct `VersionedSchema` / `SchemaMigrationPlan` (V1→V2
  lightweight, adds `Habit`), preventing silent store wipes.
- `KeychainService.swift` uses correct accessibility and delete-before-add.
- UserDefaults payloads across all App Group stores are small Codable structs (no >1MB risk).

## Recommendations

1. **Immediate (CRITICAL):** Add the App Group capability + a single canonical suite ID to all 3
   targets' entitlements. Wire the main app to call `WidgetDataProvider.save*` +
   `WidgetCenter.shared.reloadAllTimelines()` on every new stress measurement. Retarget
   `DataManageView` / `DataDeleteView` onto the existing `DataDeleterService` /
   `CloudKitResetService` so delete/reset actually clears CloudKit, Keychain, and all App Group
   caches — and add delete propagation to `SyncManager` / `CloudKitSyncEngine`.
2. **Short-term (HIGH):** Add explicit file protection to export writes; add cleanup-after-share
   for both export paths; remove or consolidate the dead `DataManagementService` / `CSVGenerator`
   / `JSONGenerator` / `DataManagementViewModel` stack once the live paths absorb its correct
   logic.
3. **Long-term:** Verify CloudKit entitlements with `icloud-auditor`; add a staleness threshold to
   the widget timeline; delete the unused `WidgetSharedData.swift` scaffolding once the real
   integration lands.

## Test Plan

Run on a **real device** — App Group behavior differs on simulator.

1. Verify widget shows live data after a measurement.
2. Verify Delete-All / Factory-Reset removes data from a second signed-in device (CloudKit
   propagation).
3. Verify the Keychain token is gone after reset by inspecting `SecItemCopyMatching`.
4. Verify exported CSV/JSON files don't survive app relaunch, if that is the intended lifecycle.

## Unresolved Questions

1. Which App Group ID is canonical — `group.com.stressmonitor.app`,
   `group.com.stressmonitor.watch`, or `group.stress.ai.com`?
2. Was the `DataManagementService` stack intentionally superseded, or did the view-level
   reimplementation land by accident? Determines whether to delete it or retarget onto it.
3. Is the iPhone widget in scope for v1? If yes, #3 is a ship-blocker; if no, the widget target
   should be excluded from the build rather than shipped showing placeholder data.
