<!-- refreshed: 2026-08-08 -->
# Codebase Concerns

**Analysis Date:** 2026-08-08

Severity scale: **CRITICAL** (ship blocker / data or security exposure) · **HIGH** (likely user-visible breakage or major debt) · **MEDIUM** · **LOW**.

## Tech Debt

**Nested duplicate `.xcodeproj` inside the `.xcodeproj` — HIGH:**
- Issue: A second project bundle exists at `StressMonitor/StressMonitor.xcodeproj/StressMonitor.xcodeproj/project.pbxproj` (848 lines), nested inside the real one at `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` (868 lines). Both declare the same 3 targets (2 applications + 1 app-extension).
- Impact: Tooling that globs for `project.pbxproj` resolves two candidates non-deterministically; edits can land in the copy Xcode never reads. Explains divergent findings between analysis passes.
- Fix approach: Confirm the nested bundle is unreferenced, then delete it in one commit. Verify Xcode still opens and all 3 targets build before committing.

**Duplicate/orphaned legacy source tree — HIGH:**
- Issue: A second, older app tree lives alongside the current one and is tracked in git but referenced by **zero** targets in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`.
- Files: `StressMonitor/Views/` (`ContentView.swift`, `DashboardView.swift`, `SettingsView.swift`, `StressHistoryView.swift` — 840 lines, `MorningReadinessView.swift`, `HRVTrendChartView.swift`, `PlaceholderViews.swift`, `StressScoreView.swift`), `StressMonitor/Services/` (`HealthKitManager.swift`, `CloudKitManager.swift`, `HRVAnalyzer.swift`, `StressPredictor.swift`, `ActivityManager.swift`, `MorningReadinessService.swift`, `MergeBenchmark.swift`), `StressMonitor/StressMonitorApp.swift`, `StressMonitor/StressMonitorSchema.swift`.
- Impact: ~5k lines of dead code that greps/agents mistake for live code; duplicate type names (`HealthKitManager`, `CloudKitManager`, `StressMonitorApp`) make navigation and impact analysis unreliable.
- Fix approach: Confirm no target membership, then delete the legacy tree in one commit (or move to `archive/`).

**Two conflicting SwiftData container definitions — HIGH:**
- Issue: `StressMonitor/StressMonitorSchema.swift` defines a **CloudKit-backed** container (`iCloud.com.stressmonitor.app`) with only `StressMeasurement`; the live entry point `StressMonitor/StressMonitor/StressMonitorApp.swift:67` builds a **non-CloudKit** container with `StressMeasurement`, `CharacterUnlock`, `Habit` and `AppMigrationPlan`.
- Impact: The documented "CloudKit sync" behaviour is not what the shipping container does. Whichever is adopted later changes on-disk store semantics.
- Fix approach: Delete the orphan schema file, or fold `cloudKitContainer:` into the live container and re-test migration.

**Dual stress algorithms with divergent copies — MEDIUM:**
- Issue: `MultiFactorStressCalculator` is the only algorithm wired into UI (`Views/DashboardView.swift:18,24`, `Views/MainTabView.swift:118`); the legacy `StressCalculator` (`StressMonitor/StressMonitor/Services/Algorithm/StressCalculator.swift`) is referenced by no call site on iOS, yet `HealthBackgroundScheduler` calls the protocol's legacy `calculateStress(hrv:heartRate:)` path (`Services/Background/HealthBackgroundScheduler.swift`), so background scores can use a different formula than foreground scores.
- Files: `Services/Algorithm/StressCalculator.swift`, `Services/Algorithm/MultiFactorStressCalculator.swift`, `Services/Background/HealthBackgroundScheduler.swift`, plus watch duplicates `StressMonitorWatch Watch App/Services/StressCalculator.swift` and `.../MultiFactorStressCalculator.swift`.
- Impact: Foreground vs background vs watch scores can disagree for the same biometrics; four copies of the scoring logic to keep in sync.
- Fix approach: Route background refresh through `calculateMultiFactorStress(context:)`, then delete or explicitly mark the legacy path as fallback-only. Share the watch/iOS algorithm via a common target.

**Unfinished journal persistence — MEDIUM:**
- Issue: `// TODO: Implement persistence` — note entry is discarded on save.
- Files: `StressMonitor/StressMonitor/Views/Journal/NoteEntryView.swift:68`.

**CoreML stress prediction never loaded — LOW:**
- Files: `StressMonitor/Services/StressPredictor.swift:113` (`// TODO: Load CoreML model when available`) — in the orphaned legacy tree, so double-dead.

**Repo hygiene — MEDIUM:**
- `StressMonitor/build/` (155 MB of built products, including `.app` and `.dSYM`) exists on disk untracked; a stray `repomix-output.xml` is committed. `DOCUMENTATION_UPDATE_SUMMARY.txt` at repo root is process noise.
- Fix approach: Ensure `build/` is ignored, drop `repomix-output.xml` from tracking.

## Known Bugs

**HealthKit auto-refresh is silently disabled on Simulator — MEDIUM:**
- Symptoms: `startAutoRefresh()` returns immediately under `#if targetEnvironment(simulator)` (`StressMonitor/StressMonitor/ViewModels/StressViewModel.swift:483-486`), so simulator QA never exercises the observer path.
- Trigger: Any simulator run without `-demo-mode`.
- Workaround: Demo mode timer refresh (`startDemoAutoRefresh`, DEBUG only).

**Background refresh reports success on partial failure — MEDIUM:**
- Symptoms: `handleBackgroundRefresh` swallows the fetch error in a `do/catch` that only `print`s, then calls `task.setTaskCompleted(success: !operation.isCancelled)` — a failed refresh is reported to `BGTaskScheduler` as success, degrading future scheduling heuristics.
- Files: `StressMonitor/StressMonitor/Services/Background/HealthBackgroundScheduler.swift` (`handleBackgroundRefresh`, `fetchAndCalculateStress`).
- Fix approach: Propagate the thrown error into the completion flag; replace `print` with the app logger.

**Hard-coded heart-rate fallback pollutes stress scores — MEDIUM:**
- Symptoms: `let heartRateValue = hrData.first?.value ?? 70` in `HealthBackgroundScheduler.fetchAndCalculateStress()` fabricates a 70 bpm reading when HealthKit returns nothing, and the resulting measurement is persisted as real data.
- Fix approach: Skip the measurement (as is already done for missing HRV) instead of substituting a constant.

## Security Considerations

**Backend auth is a shared guest JWT — CRITICAL:**
- Risk: When no per-user token is in Keychain, `SupabaseLLMService` falls back to `SupabaseConfig.guestJWT` — a single shared, long-lived JWT (`StressMonitor/StressMonitor/Services/LLM/SupabaseLLMService.swift:36-38`, `Services/LLM/SupabaseConfig.swift:24-36`). Every install shares one backend identity, so Supabase RLS cannot isolate users, and chat history / credits / preferences are effectively pooled.
- Current mitigation: The JWT literal lives in gitignored `Services/LLM/SupabaseSecrets.swift` (confirmed ignored via `.gitignore:164`) with Info.plist / env / UserDefaults overrides.
- Recommendations: Ship `SupabaseAuthService` (Apple Sign-In / anonymous sign-in) before release, delete the `guestJWT` accessor and `SupabaseSecrets` fallback, and rotate the guest JWT (it may exist in shell history / local builds).

**Config fallbacks embedded in source — HIGH:**
- Risk: `Services/LLM/SupabaseConfig.swift:12` hardcodes the production Supabase project URL and line 22 embeds a literal anon-key fallback. Neither `Info.plist` (`StressMonitor/StressMonitor/Info.plist`) defines `SUPABASE_URL` / `SUPABASE_ANON_KEY`, so the in-source fallbacks are what ships. Verify line 22 is a masked placeholder and not a live key before any release; do not print or copy its value.
- Recommendations: Move both to build settings injected into Info.plist; make `isConfigured` fail loudly rather than silently falling back.

**Health data privacy boundary contradicts the documented contract — CRITICAL:**
- Risk: Root `CLAUDE.md` states HealthKit data is "never sent" to Supabase, but `StressMonitor/StressMonitor/Services/LLM/StressContextPayload.swift` serializes raw biometrics to `/chat`: `hrv`, `heart_rate`, `baseline_hrv`, `baseline_hr`, `sleep_hours`, `sleep_quality`, `active_minutes`, `recovery_score`, plus a per-factor breakdown. `Services/LLM/ChatContextBuilder.swift` assembles it from HealthKit-derived state.
- Impact: Health data leaves the device and reaches OpenRouter via the backend — a privacy-policy, App Store review, and HealthKit-guideline exposure (HealthKit data must not be shared with third parties for advertising/analytics and requires disclosure).
- Recommendations: Either (a) reduce the payload to derived, non-identifying summaries, or (b) update `CLAUDE.md`, `README.md`, `docs/system-architecture*.md`, the privacy policy, and the App Store privacy nutrition label to disclose exactly which health fields are transmitted. Decide and document one boundary; today the code and the docs disagree.

**Force-unwrapped remote config URL — LOW:**
- `Services/LLM/SupabaseConfig.swift:13` force-unwraps `URL(string:)` over a value that can come from UserDefaults/env — a malformed override crashes at launch.

## Performance Bottlenecks

**Repeated calculator/service instantiation in view bodies — MEDIUM:**
- Problem: `MultiFactorStressCalculator()` is constructed inline in view initializers (`Views/DashboardView.swift:18,24`, `Views/MainTabView.swift:118`), creating new instances on view re-creation instead of reusing an injected singleton.
- Improvement path: Hoist services into an environment-injected container created once at app start.

**Very large view files — MEDIUM:**
- Files: `Views/StressHistoryView.swift` (840 lines, legacy tree), `Components/Character/*CharacterView.swift` (5 files, 530–575 lines each), `ViewModels/StressViewModel.swift` (571), `Views/Trends/TrendsViewModel.swift` (550), `Services/DataManagement/CloudKitResetService.swift` (537).
- Cause: Five near-identical character views duplicate the same animation scaffolding (~2,700 lines total).
- Improvement path: Extract a shared `CharacterCanvasView` parameterized by creature traits.

## Fragile Areas

**Swift concurrency escape hatches — HIGH:**
- Files: `Services/LLM/SupabaseLLMService.swift:15` (`@MainActor` **and** `@unchecked Sendable` on the same class — contradictory), `Services/MockServices.swift:7,63`, `Services/HealthKit/SimulatorHealthKitService.swift:10`, `StressMonitorWatch Watch App/Services/StressCalculator.swift:99`, `.../MultiFactorStressCalculator.swift:78`.
- Why fragile: The project builds at `SWIFT_VERSION = 5.0` with no `SWIFT_STRICT_CONCURRENCY` setting in `StressMonitor/StressMonitor.xcodeproj/project.pbxproj`, so these unchecked conformances are unverified. Migrating to Swift 6 will surface real data races here first, and `SupabaseLLMService` mutates `accessToken` / `sessionId` / `creditsRemaining` from streaming callbacks.
- Safe modification: Set `SWIFT_STRICT_CONCURRENCY = complete` in a branch, fix the resulting diagnostics, and delete each `@unchecked` one at a time.

**HKObserverQuery completion handling — MEDIUM:**
- `StressViewModel.startAutoRefresh()` (`ViewModels/StressViewModel.swift:489-508`) calls `completionHandler()` on every path (good), but it dispatches work into a detached `Task { @MainActor }` and completes the handler *before* that work runs. With background delivery this would tell HealthKit the update was consumed prematurely. `Services/HealthKit/HealthKitManager.swift:150-153` uses the safer `defer { completionHandler() }` pattern and explicitly documents foreground-only usage; `StressMonitorWatch Watch App/Services/WatchHealthKitManager.swift:127-130` matches. No `enableBackgroundDelivery(for:)` call exists anywhere in the repo, so HealthKit background delivery is effectively unimplemented despite the docs describing it.
- Fix approach: Standardize on the `defer` pattern; if background delivery is added, complete only after persistence succeeds.

**Force unwraps on date arithmetic and HK types — MEDIUM:**
- Files: `Services/Repository/StressRepository.swift:218`, `Services/Algorithm/BioAgeCalculator.swift:153`, `Services/HealthKit/HealthKitManager+ActivityFetch.swift:11,13`, `+SleepFetch.swift:12,13`, `+RecoveryFetch.swift:59`, `Services/HealthKit/HealthKitManager.swift:9-17`, `Services/LLM/ChatContextBuilder.swift:76,77`, `Services/LLM/StressContextPayload.swift:90,91`.
- Why fragile: `levels.first!` / `levels.last!` crash on an empty trend array; calendar `date(byAdding:)!` can fail across DST/locale edge cases.

**`fatalError` on container creation — MEDIUM:**
- `StressMonitorApp.swift:77` and `StressMonitorSchema.swift:40` crash the app if the store cannot open — a corrupt or unmigratable store becomes an unrecoverable launch crash with no user-facing recovery.

**CloudKit conflict resolution is untested — HIGH:**
- Files: `Services/Sync/ConflictResolver.swift`, `Services/Sync/SyncManager.swift`, `Services/CloudKit/CloudKitSyncEngine.swift`, `Services/DataManagement/CloudKitResetService.swift` (537 lines).
- Why fragile: Default `.devicePriority` strategy picks a winner by device idiom; a wrong decision silently discards a measurement. No tests exist for any resolution branch.

## Scaling Limits

**Migration plan covers only V1→V2 — MEDIUM:**
- `AppMigrationPlan` in `StressMonitor/StressMonitor/StressMonitorApp.swift:49-58` has a single lightweight stage. Any future model change requires a new `VersionedSchema` + stage; adding a property without one risks the iOS 17.0–17.3 silent-store-wipe the file's own comment warns about.

## Dependencies at Risk

- No third-party Swift packages are used (system frameworks only), so external dependency risk is minimal. The runtime dependency of concern is the **Supabase Edge Function contract** (`/chat`, `/sessions`, `/preferences`, `/credits`, `/quick-actions` in `Services/LLM/SupabaseConfig.swift:44-51`) plus the non-standard terminal `metadata` SSE event — a backend-side shape change breaks chat with no version negotiation on the client.

## Missing Critical Features

**Real authentication — CRITICAL:** No `SupabaseAuthService` / Apple Sign-In implementation exists; blocked: per-user chat history, correct credit accounting, RLS isolation, App Store submission.

**HealthKit background delivery — MEDIUM:** Documented but absent; blocked: stress notifications and widget freshness while the app is closed.

**Journal note persistence — MEDIUM:** See `Views/Journal/NoteEntryView.swift:68`.

## Test Coverage Gaps

**No test target exists — CRITICAL:**
- What's not tested: everything. `StressMonitor/StressMonitor.xcodeproj/project.pbxproj` declares only three `PBXNativeTarget`s (`StressMonitor`, `StressMonitorWatch Watch App`, `StressMonitorWidgetExtension`). There is a stale `StressMonitorTests.xctest` product reference and a group at lines 67/119/175/187, but **no unit-test target, no `TEST_HOST`**, so `xcodebuild test` cannot run any of the existing test files.
- Files: `StressMonitor/StressMonitorTests/` (`BioAgeCalculatorTests.swift`, `CharacterAssetResolverTests.swift`, `CharacterCollectionViewModelTests.swift`, `PremiumViewModelTests.swift`, `StoreKitProductCatalogTests.swift`) and a second orphan suite at `StressMonitorTests/` (`HRVAnalyzerTests.swift`, `MorningReadinessServiceTests.swift`, `StressHistoryTests.swift`, `StressPredictorTests.swift`, `StressReadingTests.swift`) that targets the dead legacy tree.
- Risk: Every algorithm, sync, and purchase change ships unverified; CI (`ci_scripts/`, `fastlane/Fastfile`) cannot gate on tests.
- Priority: High — restore a test target before any further phase work.

**Core stress algorithm untested — CRITICAL:**
- Not tested: `MultiFactorStressCalculator` weight redistribution on missing factors, each of the five `StressFactor` implementations (`HRVStressFactor`, `HeartRateStressFactor`, `SleepStressFactor`, `ActivityStressFactor`, `RecoveryStressFactor`), `BaselineCalculator`, `FactorCalibrator`, category boundaries at 25/50/75, and confidence scoring.
- Files: `StressMonitor/StressMonitor/Services/Algorithm/*`.
- Risk: The product's central number can regress silently.

**StoreKit — HIGH:**
- `Services/StoreKit/StoreKitService.swift` handles `.verified` / `.unverified` and calls `transaction.finish()` on both branches (lines 113, 216, 220) — correct, but note that finishing an **unverified** transaction (line 220) discards it without granting entitlement and without server-side receipt validation; there is no backend receipt check anywhere. Untested: purchase, restore, transaction-listener, and entitlement-refresh paths. Only `StoreKitProductCatalogTests` and `PremiumViewModelTests` (mock-only) exist.

**Sync / CloudKit — HIGH:** No tests for `ConflictResolver`, `SyncManager`, `CloudKitSyncEngine`, or `CloudKitResetService` (destructive).

**watchOS and Widget surfaces — MEDIUM:** No tests for `WatchConnectivityManager` (`transferUserInfo` / `sendMessage` guarded only by `isReachable`, no retry or ack), the four complication providers, or `StressMonitorWidget/Providers/StressWidgetProvider.swift`.

**Data export/deletion — MEDIUM:** `Services/DataManagement/DataManagementService.swift` (455 lines), `DataExporter`, `DataDeleter`, `LocalDataWipeService` are untested despite being irreversible and privacy-critical (GDPR/App Store account-deletion requirements).

---

*Concerns audit: 2026-08-08*
