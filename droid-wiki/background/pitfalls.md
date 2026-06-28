# Pitfalls

Known danger zones and footguns in the codebase.

## SwiftData schema changes

**Pitfall**: iOS 17.0-17.3 can silently wipe the on-disk SwiftData store when the model set changes without an explicit migration plan.

**Mitigation**: always declare a new `VersionedSchema` and add a `MigrationStage.lightweight` to `AppMigrationPlan` in `StressMonitor/StressMonitor/StressMonitorApp.swift` before adding or removing a `@Model`. The existing V1-to-V2 migration adding `Habit` is the reference.

## HealthKit authorization re-prompt

**Pitfall**: calling `requestAuthorization()` repeatedly does not re-show the permission sheet after the user has made a choice. The system remembers the user's response per authorization type.

**Mitigation**: the dashboard tracks `isPermissionRequired` based on catching `HKError.errorAuthorizationDenied`. The `PermissionCardView` directs the user to Settings > Privacy & Security > Health > StressMonitor to change the permission; it does not attempt to re-prompt programmatically.

## CloudKit account status

**Pitfall**: CloudKit sync silently does nothing when no iCloud account is signed in. Operations do not necessarily throw; they may just never complete.

**Mitigation**: `CloudKitManager` exposes `syncStatus` and surfaces errors through `onSyncError` callbacks on `StressRepository`. The Settings view shows sync status. If you are debugging missing sync, first confirm an iCloud account is signed in on the device.

## Actor isolation and PersonalBaseline

**Pitfall**: `PersonalBaseline` contains a `Dictionary` (`hourlyHRVBaseline`). Reading it across actor boundaries can cause data races because `Dictionary` is a reference type under the hood before COW snapshots it.

**Mitigation**: `HRVStressFactor.calculate` and `StressCalculator.normalizeHRV` both extract the dictionary into a local variable before any cross-actor call. Follow the same pattern if you add a new factor that reads baseline state.

## Double-resume in HealthKit async wrappers

**Pitfall**: `HKSampleQuery` can invoke its completion handler more than once in edge cases, which crashes `withCheckedThrowingContinuation` on the second resume.

**Mitigation**: every wrapper in `HealthKitManager` guards with a `queryHasReturned` flag. If you add a new HealthKit query wrapper, copy this pattern exactly.

## SwiftUI Charts annotation overflow

**Pitfall**: the `.annotation(overflowResolution:)` modifier crashed on certain iOS versions. Removed in commit `db0d1d8`.

**Mitigation**: avoid that modifier. Use custom `overlay` or `annotation(position:)` without overflow resolution if you need chart annotations.

## Stress color in isolation

**Pitfall**: using a stress category color without its icon and pattern fails WCAG dual-coding requirements and is invisible to color-blind users.

**Mitigation**: always pair the color with `StressCategory.icon` and `StressCategory.pattern`. Use `StressCategory.accessibilityDescription` for VoiceOver. The lint to enforce this is manual; code review must check.

## `PaywallController` infinite recursion

**Pitfall**: if a paywall presentation itself triggers another `paywall.present(reason:)` call (for example, a locked component inside `PaywallView`), the controller will re-present in a loop.

**Mitigation**: `present(reason:)` is a no-op when `premiumState.isPremiumUser` is true, but it does not guard against re-presenting while already presenting. Paywall view code must not call `present(reason:)` on itself.

## Guest JWT expiration

**Pitfall**: the guest JWT fallback in `SupabaseSecrets.swift` has a 1-week expiration. After it expires, all chat requests return 401 until it is rotated.

**Mitigation**: rotate the guest JWT before it expires, or replace with real Apple Sign-In. The TODO in `SupabaseConfig.swift` calls this out.
