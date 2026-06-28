# Debugging

Common issues and where to look when something goes wrong.

## Build logs

- Xcode build log: `StressMonitor/build_output.log`.
- Test output log: `StressMonitor/test_output.log`.
- The `xc-all` MCP plugin surfaces build/test output inline if you are driving Xcode through MCP.

## HealthKit

- **Authorization denied on simulator**: expected. Use `-demo-mode` or test on a real device with Health access granted under Settings > Privacy & Security > Health > StressMonitor.
- **`fetchLatestHRV()` returns nil**: the user has no HRV data in HealthKit (common on the simulator). The stress calculator returns `.noData`; the dashboard shows `NoDataCard`.
- **Double-resume crashes in HealthKit queries**: the async wrappers in `HealthKitManager` guard against this with a `queryHasReturned` flag. If you add a new query wrapper, follow the same pattern.
- **Observer query not firing**: ensure the HealthKit Background Delivery capability is enabled and the observer is started in `StressViewModel.startAutoRefresh()`.

## SwiftData

- **Store wiped on schema change**: iOS 17.0-17.3 can silently wipe the store when the model set changes without an explicit migration plan. The app declares `AppSchemaV1` and `AppSchemaV2` with a lightweight stage in `StressMonitorApp.swift` to force in-place migration. Always add new `@Model` types through a new `VersionedSchema` and migration stage.
- **`ModelContext` accessed off the main actor**: `StressRepository` is `@MainActor` because it owns the context. Do not pass the context across actors.

## CloudKit

- **Sync not running**: ensure an iCloud account is signed in on the device/simulator. Private database sync requires an active account.
- **Conflicts merging incorrectly**: inspect the `ConflictResolver.strategy` (default `.devicePriority`) and the `cloudKitModTime` values on the conflicting records. Timestamp ties are broken by device priority.
- **`CloudKitResetService` taking too long**: it batches `CKModifyRecordsOperation` calls. Progress is surfaced through callbacks in `DataManagementViewModel`.

## LLM chat

- **`SupabaseLLMService.isAvailable()` returns false**: the anon key is not configured. Check Info.plist build settings or the `SUPABASE_ANON_KEY` environment variable.
- **401 from the Edge Function**: the JWT is missing or expired. The guest JWT fallback in `SupabaseSecrets.swift` has a 1-week expiration; replace with real Apple Sign-In before production.
- **Stream hangs**: the Edge Function has a 90-second timeout (set in `URLRequest.timeoutInterval`). Check backend logs in the Supabase dashboard.
- **SSE tokens not appearing**: verify the backend emits OpenAI-compatible `data: {"choices":[{"delta":{"content":"..."}}]}` lines. Other shapes are ignored by `SSEParser`.

## StoreKit

- **Products not loading**: product IDs resolve from Info.plist, env, or UserDefaults (see [StoreKit IAP](../systems/storekit-iap.md)). Unresolved `$(...)` placeholders are treated as nil. `availablePlans` falls back to `SubscriptionPlan.defaultPlans` when no products resolve.
- **Purchase silently fails**: check that the `StoreKitProductCatalog` has a product ID for the selected `SubscriptionPeriod`. `purchase(_:)` throws `StoreKitError.missingProductConfiguration` otherwise.
- **Premium state not updating**: `PremiumState.shared.isPremiumUser` is refreshed by `StoreKitService.refreshEntitlements()` on launch and on `Transaction.updates`. Restart the app if testing a sandbox purchase.

## Navigation

- **`NavigationPath` not restoring**: `@SceneStorage` keys must match across launches. `AppRouter.decodePath` drops corrupt data rather than crashing; check the encoded blob if state unexpectedly resets.
- **Deep link does not switch tabs**: use `router.deepLink(to:in:)` which sets `selectedTab` before appending to the per-tab path. Plain `path.append` does not switch tabs.

## UI

- **Stress color invisible to a user**: always pair the color with the category icon and pattern. Use `StressCategory.accessibilityDescription` for VoiceOver.
- **Custom fonts not loading**: `FontBlaster.blast()` runs in a background `Task` on first dashboard appear. There may be a brief font flash on cold start; this is accepted.
- **Chart crashes with unsupported annotation**: SwiftUI Charts annotation overflow strategy was removed in commit `db0d1d8`. Avoid `.annotation(overflowResolution:)`.
