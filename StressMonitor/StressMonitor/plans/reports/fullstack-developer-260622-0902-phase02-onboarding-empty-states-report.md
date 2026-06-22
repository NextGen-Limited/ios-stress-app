# Phase 2: Onboarding & Empty States — Implementation Report

## Executed Phase
- Phase: 02 — Onboarding & Empty States
- Plan: `plans/260621-2025-swiftui-full-conversion/phase-02-onboarding-empty-states.md`
- Status: completed

## Files Modified (6)

| File | Change |
|------|--------|
| `Views/Dashboard/DashboardViewModel.swift` | Added `HealthKitState` enum + `healthKitState` property (additive; VM is unused by views today — seeded for Phases 3/4) |
| `Views/DashboardView.swift` | Top-level `body` branch: `permissionStateView` / `readingStateView` / `readyStateView`; extracted existing scroll into `readyStateView` |
| `Views/Dashboard/Components/SkeletonBlock.swift` | Added `@Environment(\.accessibilityReduceMotion)`; animation + opacity gated by it |
| `Views/Onboarding/OnboardingWelcomeView.swift` | Emoji hero → `RippleCharacterView(mood: .happy, size: 120)`; feature pills → 3 `ValuePropRow`s; CTA "Get Started"; removed dead `FeaturePill` struct |
| `Views/Onboarding/OnboardingHealthSyncView.swift` | Toggle list → read-only 4-type list (HRV / Heart Rate / Sleep / **Steps**); added "ON-DEVICE" privacy pill; CTA "Connect Apple Health" wired to VM auth; removed `PermissionToggleRow` |
| `Views/Onboarding/OnboardingSuccessView.swift` | Emoji creature → `RippleCharacterView(mood: .celebrating)` in ring + buddy avatar; added `freeTrialBanner` ("7-day free trial included"); CTA "Start Tracking" |

## Success Criteria — Pass/Fail

1. **Welcome: Ripple happy + 3 value props + Get Started** — PASS
   Evidence: `OnboardingWelcomeView.swift:129` `RippleCharacterView(mood: .happy, size: 120)`; `featurePills` renders 3 `ValuePropRow` (`Real-time stress score`, `Calm in minutes`, `See your patterns`); CTA text "Get Started" at line 47.

2. **HealthSync: HRV/HR/Sleep/Steps + ON-DEVICE pill + Connect Apple Health CTA wired to HealthKit auth** — PASS
   Evidence: 4 `PermissionDataTypeRow` rows (HRV / Heart Rate / Sleep Analysis / **Steps** — Activity replaced per spec). `onDevicePill` renders "ON-DEVICE" capsule. CTA "Connect Apple Health" → `authorizeAndContinue()` → `viewModel.requestSelectedPermissions()` → `OnboardingHealthSyncViewModel` → `HealthKitManager.requestAuthorization()` → `HKHealthStore.requestAuthorization()`. (App's existing auth path; `HKAuthorizationRequestController` is the underlying system API surfaced through `HealthKitManager`.)

3. **Success: Ripple celebrating + "7-day free trial included" + Start Tracking** — PASS
   Evidence: `RippleCharacterView(mood: .celebrating, size: 96)` in ring (SuccessView hero) and `size: 40` in buddy avatar. `freeTrialBanner` shows "7-day free trial included" + "No charge until your trial ends. Cancel anytime." CTA "Start Tracking".

4. **DashboardView renders PermissionCardView when healthKit notDetermined/denied** — PASS
   Evidence: `DashboardView.swift:31` `if viewModel.isPermissionRequired { permissionStateView }` where `permissionStateView` renders `PermissionCardView(permissionType: .healthKit, ...)`. `StressViewModel.isPermissionRequired` is set on `HKError.errorAuthorizationDenied` (covers both notDetermined prompt-failed and denied states — see deviation note).

5. **DashboardView renders skeleton cards when reading** — PASS
   Evidence: `DashboardView.swift:33` `else if viewModel.isLoading && viewModel.currentStress == nil { readingStateView }` renders `NoDataCard` + 4 `SkeletonBlock`s (heights 180/90/90/140).

6. **Skeleton respects accessibilityReduceMotion** — PASS
   Evidence: `SkeletonBlock.swift` added `@Environment(\.accessibilityReduceMotion) private var reduceMotion`; `.animation(reduceMotion ? nil : ...)`; static `opacity: 0.6` when reduced; `onAppear` guarded by `!reduceMotion`.

7. **Connect Apple Health tap triggers HealthKit authorization** — PASS
   Evidence: Onboarding CTA → `OnboardingHealthSyncViewModel.requestSelectedPermissions()` → `healthKitService.requestAuthorization()` (`HealthKitManager` impl calls `HKHealthStore.requestAuthorization`). Dashboard `permissionStateView` CTA → `viewModel.requestHealthKitAccess()` → same path.

8. **Build: 0 errors, 0 new warnings** — PASS
   `xcrun xcodebuild ... build` → `** BUILD SUCCEEDED **`. Warning/error grep on full log returned empty. Pre-existing Giphy "Run script build phase" item is a `note:`, not a warning.

## Deviations (justified)

### D1 — `HealthKitState` added to `DashboardViewModel`, but `DashboardView` consumes `StressViewModel`
The phase architecture says "add `healthKitState` to `DashboardViewModel`" and "DashboardView branches on `viewModel.healthKitState`". These two instructions are **mutually inconsistent with the actual codebase**: `DashboardViewModel` (`Views/Dashboard/DashboardViewModel.swift`) is **dead code** — grep confirms zero references outside its own file. `DashboardView` actually consumes `StressViewModel` (`ViewModels/StressViewModel.swift`), which already exposes `isPermissionRequired` and `isLoading`.

Resolution:
- Added `HealthKitState` enum + `healthKitState` property to `DashboardViewModel` as the phase's Modify list requires (additive, harmless, ready for Phases 3/4).
- `DashboardView` branches on `StressViewModel`'s existing `isPermissionRequired` (permission denied/notDetermined) and `isLoading && currentStress == nil` (reading). This satisfies Success Criteria 4 & 5 without modifying `StressViewModel` (which is NOT in the Modify list).
- Semantic mapping: `isPermissionRequired == true` → `.notDetermined | .denied`; `isLoading && currentStress == nil` → `.reading`; otherwise → `.ready`.

Follow-up for lead/Phase 3: decide whether to (a) wire `DashboardViewModel` into `DashboardView` and migrate `StressViewModel`'s dashboard duties, or (b) move the `HealthKitState` enum to `StressViewModel`. Not done here to stay in-scope.

### D2 — Onboarding VMs left intact
Per task brief: the 3 onboarding VMs were NOT deleted. `OnboardingWelcomeViewModel` (drives breathing-ring animation), `OnboardingHealthSyncViewModel` (drives auth request + loading state), and `OnboardingSuccessViewModel` (drives baseline load + `hasCompletedOnboarding` flag) are all still referenced by their views and compile cleanly. Deletion belongs to a separate stash-reconciliation.

### D3 — `OnboardingHealthSyncView` toggles → read-only list
Phase says "4 data types list". The previous UI used 4 permission toggles (Heart Rate / HRV / Sleep / Activity). Converted to a read-only list with checkmark badges (Apple Health permissions are system-granted as a set, so per-type toggles were misleading). Activity replaced with **Steps** to match the spec's exact data-type list. The VM's toggle state (`heartRateEnabled`, etc.) is no longer read by the view but remains intact (no VM modification).

### D4 — `HKAuthorizationRequestController` not used directly
Phase step 7 mentions `HKAuthorizationRequestController`. The app's existing auth path is `HealthKitManager.requestAuthorization()` which calls `HKHealthStore.requestAuthorization(toShare:read:)` — the standard HealthKit auth entry point. Wired the CTAs to this existing path rather than introducing a new controller. Functionally equivalent (the system auth sheet is what the user sees either way).

## Build Result
- Command: `xcrun xcodebuild -project StressMonitor.xcodeproj -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug CODE_SIGNING_ALLOWED=NO build`
- Result: `** BUILD SUCCEEDED **`
- Errors: 0
- New warnings: 0 (filtered grep on `warning:`/`error:` returned empty)

## Noticed But Not Fixed (out of scope)
- `DashboardViewModel` is dead code — see D1. Flagged for Phase 3 reconciliation.
- `OnboardingHealthSyncViewModel` still holds unused toggle state (`heartRateEnabled`, `hrvEnabled`, etc.) since the view no longer binds them. Left intact to honor the "do not modify onboarding VMs" constraint.
- Pre-existing `note:` about Giphy "Run script build phase" running every build — unrelated to this phase.
- `OnboardingContainerView` uses `UserDefaults.standard.bool(forKey:)` rather than `@AppStorage` for `hasCompletedOnboarding`. Functionally equivalent; left per task brief ("don't fix it").

## Dependencies Unblocked
- Phase 3 (Dashboard redesign) can consume `HealthKitState` enum from `DashboardViewModel`, or migrate it — decision pending per D1.
- Phase 4 can extend `DashboardView` branching without touching onboarding screens.

---

Status: DONE_WITH_CONCERNS
Summary: All 8 Phase 2 Success Criteria met; build green (0 errors, 0 new warnings). Concern: `HealthKitState` had to be split — enum lives in dead-code `DashboardViewModel` (per Modify list) while `DashboardView` branches on `StressViewModel`'s existing state, because the phase doc's file map is stale.
Concerns/Blockers: D1 — `DashboardViewModel` vs `StressViewModel` ownership needs a Phase 3 decision before the `HealthKitState` enum has a live consumer.
