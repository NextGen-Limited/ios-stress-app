# Phase 2: Data Integrity, Deletion & Consolidation - Context

**Gathered:** 2026-08-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Make "delete" actually delete everywhere the UI claims it does, protect health-data exports at rest and in transit, apply CloudKit field-level encryption so the E2E-encryption claim in docs is true, and collapse the dead duplicate data-management stack so only the live implementation remains. This phase depends on Phase 1's BUILD-02 outcome: the canonical App Group suite ID `group.stress.ai.com` is now consistent across all three targets, so the deletion paths can clear the App Group cache with confidence rather than guessing which suite.

The phase covers four requirements: DATA-01 (complete deletion across all stores), DATA-02 (protected exports), DATA-03 (CloudKit encryptedValues), and WIRE-02 (duplicate stack removal). All five success criteria in the ROADMAP are independently verifiable.

</domain>

<decisions>
## Implementation Decisions

### CloudKit Field Encryption (D2) — PRE-RESOLVED
- **D-01:** Implement `CKRecord.encryptedValues` for `hrv`, `restingHeartRate`, `stressLevel`. The E2E-encryption claim in `CLAUDE.md`, `docs/system-architecture.md`, and the privacy policy stays. The infrastructure already exists in `CloudKitManager.saveMeasurement` (lines 50-55) and `CloudKitSyncEngine.uploadBatch` (lines 82-84) — both already write health fields via `record.encryptedValues[...]`, and `CloudKitManager.convertRecordToMeasurement` (lines 218-220) already reads them back via `record.encryptedValues[...]`. The remaining work is verifying the sync path is exercised end-to-end and removing the stale `CloudKitStressMeasurement` struct in `CloudKitSchema.swift` (lines 16-57) whose plain-key `toCKRecord()` would silently bypass encryption if ever instantiated. — **Reversibility:** one-way — `encryptedValues` is not queryable, so moving a field back to plaintext after launch changes the CloudKit schema contract; get it right now.

### Deletion Architecture (Claude's discretion, auto-resolved per --auto)
- **D-02:** Retarget the live UI (`DataManageView.performDeleteAll`, `DataManageView.performFactoryReset`) onto the existing, correct, but currently-unreferenced `DataDeleterService` chain rather than continuing to patch the inline reimplementation. `DataDeleterService` already orchestrates `CloudKitResetService` + `LocalDataWipeService` with progress tracking and error recovery; the views bypass it and do their own partial SwiftData-only deletes. The retarget closes the gap between what the UI promises ("permanently delete from iCloud") and what it does. — **Reversibility:** reversible — the inline delete is still in git history if the service chain proves insufficient.

### Export Protection (Claude's discretion, auto-resolved per --auto)
- **D-03:** Exports use a hard size cap (reject or truncate exports exceeding a threshold — a reasonable default like 10 MB or 10,000 records, whichever hits first, chosen during planning) and clean up the temp file immediately when the share sheet dismisses (not just the 1-hour stale sweep that exists today). `.completeFileProtection` is already applied at `DataExportView.swift:346-349` — that part is done; the gap is the missing size cap and the missing on-dismiss cleanup. — **Reversibility:** reversible.

### Keychain Clearance (Claude's discretion, auto-resolved per --auto)
- **D-04:** "Delete All" and "Factory Reset" both call `SupabaseLLMService.clearStoredCredentials()` (which already deletes the JWT and refresh token from Keychain via `KeychainService.delete`). `DataManageView.performFactoryReset:194` already calls it; `performDeleteAll:159-176` does not — that path must be added. The acceptance criterion is `SecItemCopyMatching` returning `errSecItemNotFound` after deletion. — **Reversibility:** reversible.

### App Group Cache Clearance (Claude's discretion, auto-resolved per --auto)
- **D-05:** Both delete paths clear the App Group suite (`group.stress.ai.com`) via `UserDefaults(suiteName:)?.removePersistentDomain(forName:)`. `performFactoryReset:195` already does this; `performDeleteAll` must be extended to do it too. This is the dependency on Phase 1's BUILD-02 — before that landed, the suite ID was inconsistent across targets. — **Reversibility:** reversible.

### Claude's Discretion
- Whether "Delete All" (as distinct from "Factory Reset") clears character unlocks and preferences, or only stress measurements + their sync artifacts. The UI copy in `DataManageView` says "Removes every locally stored measurement" for Delete All (measurements-scoped), while Factory Reset says "wipes all data, character unlocks, and preferences" (app-wide). Default: keep the distinction — Delete All clears measurements + CloudKit + Keychain JWT + App Group cache; Factory Reset additionally clears `CharacterUnlock` and preference `UserDefaults`.
- Whether the stale-export sweep interval (currently 1 hour) is kept or tightened. Default: keep the sweep as a backstop, add immediate on-dismiss cleanup as the primary path.
- Whether `CloudKitSchema.swift`'s dead `CloudKitStressMeasurement` and `CloudKitPersonalBaseline` structs (zero call sites, plain-key mapping that would bypass encryption) are deleted entirely or just marked as stale. Default: delete — they have zero call sites and their `toCKRecord()` would silently produce unencrypted records if ever revived.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Primary scope source
- `plans/0808-2042-appstore-submission-remediation/plan.md` lines 80-99 — "Phase 2 — Data integrity & deletion": file-level detail, the specific line numbers of broken delete paths, and the acceptance criteria (two-device verification, Keychain check, export protection)
- `plans/reports/appstore-audit-0808-1520-storage-report.md` — source audit for DATA-01 (delete paths) and DATA-02 (export protection)

### Codebase state
- `.planning/codebase/ARCHITECTURE.md` §"Cross-process boundary" — widget/complication data flow via App Group `UserDefaults` (relevant to App Group cache clearance)
- `.planning/codebase/CONCERNS.md` §"Security Considerations" — corroborates the delete-path gaps independently
- `.planning/phases/01-build-configuration-widget-wiring/01-01-SUMMARY.md` — Phase 1 BUILD-02 outcome: canonical App Group suite ID `group.stress.ai.com` confirmed across all targets

### Project-level
- `.planning/PROJECT.md` §Context — D2 decision framing (harder to change post-launch)
- `.planning/REQUIREMENTS.md` — DATA-01, DATA-02, DATA-03, WIRE-02 acceptance criteria

</canonical_refs>

<code_context>
## Existing Code Insights

### Live Delete Paths (what the user actually touches today)
- `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataManageView.swift` — the hub screen. `performDeleteAll()` (lines 159-176) deletes only local `StressMeasurement` rows + CloudKit records, but does NOT clear Keychain JWT, App Group cache, or character unlocks. `performFactoryReset()` (lines 183-205) clears measurements + characters + Keychain + App Group + CloudKit — this path is the more complete one.
- `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataDeleteView.swift` — the detailed delete-by-range screen. `DataDeleteViewModel.performDelete()` (lines 399-473) handles local deletion and CloudKit deletion by date range, but never touches Keychain or App Group cache. The "Everything" scope in the picker promises more than it delivers.

### Dead/Unreferenced Delete Infrastructure (correct but unused)
- `StressMonitor/StressMonitor/Services/DataManagement/DataDeleterService.swift` — `@Observable @MainActor final class` conforming to `DataDeleter` protocol. Orchestrates `LocalDataWipeService` + `CloudKitResetService` with progress, error recovery, and factory reset. **Zero call sites** — the views reimplement its logic inline and incompletely. This is the canonical target for the retarget (D-02).
- `StressMonitor/StressMonitor/Services/DataManagement/LocalDataWipeService.swift` — handles batch SwiftData deletion with progress tracking. Only referenced by `DataDeleterService` (which is itself unreferenced).
- `StressMonitor/StressMonitor/Services/DataManagement/CloudKitResetService.swift` — handles CloudKit record deletion (batch, by date range, by type) with cursor pagination and error adaptation. Referenced directly by `DataManageView` and `DataDeleteView` (bypassing `DataDeleterService`).

### CloudKit Encryption (D-01 — already implemented, needs verification + dead-code removal)
- `StressMonitor/StressMonitor/Services/CloudKit/CloudKitManager.swift` lines 50-55 — `saveMeasurement` writes `stressLevel`, `hrv`, `restingHeartRate` via `record.encryptedValues[...]`. Lines 218-220 — `convertRecordToMeasurement` reads them back via `record.encryptedValues[...]`. **This is live and correct.**
- `StressMonitor/StressMonitor/Services/CloudKit/CloudKitSyncEngine.swift` lines 82-84 — `uploadBatch` writes the same three fields via `encryptedValues`. **This is live and correct.**
- `StressMonitor/StressMonitor/Services/CloudKit/CloudKitSchema.swift` lines 16-57 — `CloudKitStressMeasurement` struct with `toCKRecord()` that writes plain keys (NOT `encryptedValues`). **Zero call sites, stale, and a latent encryption-bypass risk if revived.** Candidate for deletion (D-02's discretion).

### Export Path (partially done, two gaps remain)
- `StressMonitor/StressMonitor/Views/Settings/DataManagement/DataExportView.swift` — `DataExportViewModel.exportData()` (lines 314-357) already applies `.completeFileProtection` (lines 346-349) and has a 1-hour stale-export sweep (lines 362-375). **Gaps:** no size cap on the generated file, and no cleanup when the share sheet dismisses (only the hourly sweep).
- `StressMonitor/StressMonitor/Models/ExportModels.swift` — `JSONExport`, `StressSnapshot`, `ExportSummary`, `ExportMetadata`, `BaselineData` structs. **Zero call sites outside the file itself** — the live `DataExportViewModel` generates CSV/JSON inline with its own `generateCSV`/`generateJSON` methods rather than using these models. Dead code candidate, but not a WIRE-02 blocker unless the planner wants to consolidate export generation too.

### Credential Clearance
- `StressMonitor/StressMonitor/Services/LLM/SupabaseLLMService.swift` line 39 — `clearStoredCredentials()` deletes JWT + refresh token from Keychain via `KeychainService.delete`, plus clears the expiry from `UserDefaults`. **Live and correct.**
- `StressMonitor/StressMonitor/Services/KeychainService.swift` — `enum KeychainService` with static `retrieve`/`save`/`delete` methods wrapping `SecItem*` calls.

### Duplicate Stack (WIRE-02)
- The remediation plan references `DataManagementService`/`CSVGenerator`/`JSONGenerator` as the duplicate stack. **These classes do not exist in the current codebase** — they were either already removed, or the plan referenced a shape that never materialized. The actual duplicate is structural: `DataDeleterService` (correct, complete, unreferenced) vs. the inline deletes in `DataManageView`/`DataDeleteView` (incomplete, referenced). WIRE-02's resolution is the retarget in D-02 — once the views call `DataDeleterService`, the inline reimplementations are deleted and only one delete path remains. Additionally, the `DataExporter` protocol in `DataExporter.swift` has zero conformers and zero call sites — pure dead code.

### App Group Cache
- `StressMonitor/StressMonitorWidget/Models/WidgetDataProvider.swift` — `appGroupID = "group.stress.ai.com"`, stores latest stress snapshot + history. `removePersistentDomain(forName: "group.stress.ai.com")` is the clearance method (already used in `performFactoryReset:195`).

### Established Patterns
- `@Observable @MainActor final class` for services with progress state (`DataDeleterService`, `CloudKitResetService`, `LocalDataWipeService`).
- Protocol-based DI seam (`DataDeleter` protocol in `DataDeleter.swift`).
- `ObserverIsolated<T>` wrapper for thread-safe progress state in `@MainActor` services.
- `DataManagementLogger` abstraction with `#if DEBUG` print + `os_log`.

### Integration Points
- `DataManageView.performDeleteAll` / `performFactoryReset` — the two entry points that must be retargeted onto `DataDeleterService`.
- `DataDeleteView.DataDeleteViewModel.performDelete` — the range-delete entry point; also needs Keychain + App Group coverage for the "Everything" scope.
- `DataExportView.DataExportViewModel.exportData` — needs size cap + on-dismiss cleanup.
- `SupabaseLLMService.clearStoredCredentials()` — already correct, needs to be called from `performDeleteAll` (currently only `performFactoryReset` calls it).

</code_context>

<specifics>
## Specific Ideas

- The two-device verification criterion (DATA-01 success criterion 1) requires a real-device test: delete on device A, confirm records disappear from device B. This is a manual verification gate — plan it as a `checkpoint:human-verify` task. The simulator's CloudKit behavior does not match real devices.
- The Keychain verification criterion (success criterion 2) can be automated: write a known JWT to Keychain, run the delete path, assert `SecItemCopyMatching` returns `errSecItemNotFound`. This is a unit-test candidate.
- Export size cap: the export generates CSV/JSON from SwiftData measurements. A single user is unlikely to exceed 10 MB, but the cap is a safety rail against unbounded growth. Choose the threshold during planning.

</specifics>

<deferred>
## Deferred Ideas

- **Habit data in deletion scope** — `DataManageView.swift:82` footer says "Habits export is coming soon." Habits are a separate SwiftData model not touched by current delete paths. Out of scope for this phase (no ROADMAP criterion covers it); if the planner needs to address it, surface it rather than silently including it.
- **SwiftData CloudKit sync reconfiguration** (Phase 01.1's criterion 4) — whether the SwiftData `ModelConfiguration` binds `cloudKitContainer` or the app is local-only. That is a Phase 01.1 decision, not Phase 2. This phase treats CloudKit as it exists today (manual `CKRecord` sync via `CloudKitManager`/`CloudKitSyncEngine`).
- **Watch-side deletion mirroring** — the watch target duplicates the algorithm/model code, but deletion is triggered from the iPhone only. No watch-side delete path exists or is required by the ROADMAP criteria.

</deferred>

<verification_notes>
## Verification Constraints

- **Real device required for DATA-01 criterion 1** (two-device CloudKit sync verification). Simulator CloudKit does not exercise the same sync paths.
- **Keychain check (criterion 2) is automatable** — `SecItemCopyMatching` with `kSecClassGenericPassword` after deletion.
- **Export protection (criterion 3) is partially automatable** — assert `FileProtectionType.complete` on the generated file URL via `FileManager.attributesOfItem`, assert the file is absent after share-sheet dismissal.
- **CloudKit encryption (criterion 4)** — verify via code inspection that both write paths (`CloudKitManager.saveMeasurement`, `CloudKitSyncEngine.uploadBatch`) use `encryptedValues` and the dead `CloudKitStressMeasurement.toCKRecord()` is removed. A round-trip integration test (write via `saveMeasurement`, read via `convertRecordToMeasurement`) confirms the encrypted fields decode correctly.
- **Consolidation (criterion 5)** — grep-automatable: after the retarget, assert `DataManageView.performDeleteAll` and `performFactoryReset` call through `DataDeleterService`, and the inline SwiftData delete loops are gone. Assert `DataExporter` protocol and `CloudKitStressMeasurement` have zero references.

</verification_notes>

---
*Phase: 2-Data Integrity, Deletion & Consolidation*
*Context gathered: 2026-08-10*
