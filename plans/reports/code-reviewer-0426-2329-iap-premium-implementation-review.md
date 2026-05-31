# Code Review: IAP Premium Screen Implementation

**Scope:** 17 files (11 new, 6 modified)
**Date:** 2026-04-26
**Reviewer:** code-reviewer

---

## Overall Assessment

Clean implementation across all 4 phases. Red team findings from the plan were properly addressed (PremiumState singleton, alert bindings, navigation wiring). Architecture follows project conventions. A few issues found — one critical, several medium.

---

## Critical Issues

### C1. `MockStoreKitService` used in release navigation paths

**Files:** `SettingsView.swift:77`, `TrendsView.swift:91`

```swift
.navigationDestination(isPresented: $navigateToPremium) {
    IAPPremiumView(storeKit: MockStoreKitService())
}
```

Both `SettingsView` and `TrendsView` directly instantiate `MockStoreKitService()`. While `MockStoreKitService` is `#if DEBUG`-gated, this means the **release build will fail to compile** — `MockStoreKitService` won't exist outside `DEBUG`.

**Fix:** Gate the instantiation:
```swift
.navigationDestination(isPresented: $navigateToPremium) {
    #if DEBUG
    IAPPremiumView(storeKit: MockStoreKitService())
    #else
    IAPPremiumView(storeKit: LiveStoreKitService())
    #endif
}
```
Or better: create a factory/registry that provides the correct service:
```swift
static func makeStoreKitService() -> StoreKitServiceProtocol {
    #if DEBUG
    return MockStoreKitService()
    #else
    return LiveStoreKitService()
    #endif
}
```
The factory approach avoids scattering `#if DEBUG` across every call site.

---

## High Priority

### H1. `PremiumViewModel` missing `@MainActor` — inconsistent with project pattern

**File:** `PremiumViewModel.swift:4`

Every other ViewModel in this project uses `@MainActor` (`StressViewModel`, `ChatViewModel`, `DataManagementViewModel`, `BreathingViewModel`, `MiniWalkViewModel`, `DashboardViewModel`, `OnboardingViewModels`). `PremiumViewModel` does not.

Properties like `isLoading`, `showError`, `errorMessage`, `showSuccess` are mutated from async methods. Without `@MainActor`, these mutations happen on whatever executor the calling Task runs on. SwiftUI `@Observable` tracks access but doesn't guarantee main-thread safety.

This will cause runtime warnings in Swift 6 strict concurrency mode and is a latent data race.

**Fix:** Add `@MainActor`:
```swift
@MainActor
@Observable
final class PremiumViewModel {
```

### H2. `PremiumState` singleton not `@MainActor` — read from view body directly

**File:** `PremiumState.swift:6`, `StressOverTimeChart.swift:42`

`StressOverTimeChart` reads `PremiumState.shared.isPremiumUser` directly in `body`. Since `PremiumState` is `@Observable` but not `@MainActor`, SwiftUI may observe changes from background threads. This is the same pattern that the `PremiumState` singleton was supposed to fix (replacing scattered `@AppStorage`), but it introduces the same thread-safety concern.

**Fix:** Either add `@MainActor` to `PremiumState`, or access it through a ViewModel that is `@MainActor`.

### H3. `PriceDisplay` formatter creates new `NumberFormatter` on every render

**File:** `SubscriptionPlan.swift:19-22`

```swift
var priceDisplay: String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale.current
    return formatter.string(from: pricePerMonth as NSDecimalNumber) ?? "$0.00"
}
```

`NumberFormatter` allocation is expensive (~50us each). This runs on every SwiftUI body evaluation for every plan card. With 2 plan cards in a ScrollView, this fires frequently.

**Fix:** Use a static cached formatter:
```swift
private static let priceFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.locale = Locale.current
    return f
}()

var priceDisplay: String {
    Self.priceFormatter.string(from: pricePerMonth as NSDecimalNumber) ?? "$0.00"
}
```

**Caveat:** Static formatter won't react to locale changes mid-session. For a stress monitoring app this is acceptable — locale rarely changes. If needed, use a cached-but-refreshable approach.

### H4. Dead branch in `StressOverTimeChart` premium check

**File:** `StressOverTimeChart.swift:42-47`

```swift
if PremiumState.shared.isPremiumUser {
    chartContent
} else {
    chartContent
        .overlay(PremiumLockOverlay(onUpgrade: onUpgrade))
}
```

Both branches render `chartContent`. The `if` branch shows the chart without the lock overlay, and the `else` adds the overlay. This is correct functionally, but since `chartContent` is a computed property (not a view builder that differs), the chart data is identical for premium and non-premium users. The only difference is the lock overlay. This means premium users see the same mock data as non-premium users.

This is likely intentional for now (real data integration deferred), but worth flagging — when real data is wired, this structure is ready. Not a bug, just noting.

---

## Medium Priority

### M1. `IAPPremiumView` dismiss not called on successful purchase

**File:** `IAPPremiumView.swift`, `PremiumViewModel.swift`

After `purchaseSelectedPlan()` succeeds, `showSuccess` is set to `true`, but nothing observes it. No `.sheet` or `.fullScreenCover` is presented for success, and `dismiss()` is never called. The user stays on the IAP screen after purchasing.

**Fix:** Add success handling — either auto-dismiss with a delay, or show a success confirmation:
```swift
.onChange(of: viewModel.showSuccess) { _, newValue in
    if newValue {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}
```

### M2. Double-dismiss risk in `IAPNavBar`

**File:** `IAPPremiumView.swift:14`, `IAPNavBar.swift`

Both `onBack` and `onClose` call `dismiss()`. If the IAP screen is presented via `.navigationDestination`, calling `dismiss()` will dismiss the **entire NavigationStack** in some cases, not just the IAP screen. The `dismiss()` environment action dismisses whatever is top of the presentation stack, which can be the parent NavigationStack if the IAP view isn't independently presented.

Since navigation uses `.navigationDestination(isPresented:)`, the proper way to go back is by toggling the binding (`navigateToPremium = false`), not calling `dismiss()`. However, `dismiss()` from inside a pushed view should work correctly for navigation-based pushes.

**Risk:** If the IAP screen is ever presented as a `.sheet` or `.fullScreenCover`, `dismiss()` is correct. If pushed onto a NavigationStack via `navigationDestination`, `dismiss()` may pop the entire stack depending on presentation context.

**Recommendation:** Keep `dismiss()` for now (it's the standard pattern for navigation destination dismissals), but add a comment noting this coupling.

### M3. `restorePurchases` sets `showSuccess` but doesn't verify purchase was actually restored

**File:** `PremiumViewModel.swift:54-55`

```swift
try await storeKit.restorePurchases()
if premiumState.isPremiumUser { showSuccess = true }
```

The real `StoreKit` restore flow should:
1. Call `restorePurchases` on StoreKit
2. StoreKit should verify with Apple's servers
3. If valid, update `premiumState.isPremiumUser`
4. Then check and show success

Currently, the mock sets `premiumState.isPremiumUser = true` unconditionally after restore. The real implementation must ensure the restore result is authoritative, not just trust the local state. This is fine for the mock, but the protocol's `restorePurchases()` should document that it's responsible for updating `PremiumState`.

### M4. `StoreKitServiceProtocol.isPremiumUser` is async but `PremiumState.isPremiumUser` is sync

**File:** `StoreKitServiceProtocol.swift:21`

The protocol declares `var isPremiumUser: Bool { get async }`, but the actual single source of truth (`PremiumState.shared.isPremiumUser`) is a synchronous property. The `MockStoreKitService` bridges this:

```swift
var isPremiumUser: Bool { premiumState.isPremiumUser }
```

But `premiumState.isPremiumUser` is synchronous, and the protocol says `{ get async }`. This is a type mismatch — the property should be `{ get async throws }` or the implementation needs to be truly async.

**Recommendation:** Either:
- Remove `isPremiumUser` from the protocol (since `PremiumState` is the source of truth now)
- Or keep it as a `nonisolated` async accessor for future StoreKit transaction verification

### M5. No accessibility labels on plan cards

**File:** `PlanSelectionCard.swift`

The card has no `.accessibilityLabel` or `.accessibilityValue`. VoiceOver users will hear the individual text elements but not a cohesive description like "Annual plan, $14.99 per month, Save 25%, Best value option, currently selected."

**Fix:** Add accessibility traits:
```swift
.accessibilityElement(children: .combine)
.accessibilityLabel("\(plan.displayName), \(plan.priceDisplay) per month")
.accessibilityAddTraits(.isSelected)
```

### M6. Missing accessibility for IAP nav bar buttons

**File:** `IAPNavBar.swift`

The back and close buttons have no accessibility labels. VoiceOver will read the SF Symbol names ("chevron.left", "xmark") instead of "Go back" and "Close".

**Fix:**
```swift
Image(systemName: "chevron.left")
    .accessibilityLabel("Go back")
// ...
Image(systemName: "xmark")
    .accessibilityLabel("Close")
```

---

## Low Priority

### L1. `defaultPlans` are hardcoded in model — no server/config source

**File:** `SubscriptionPlan.swift:30-51`

Prices are hardcoded. This is fine for now but should be noted for when real StoreKit Product objects are fetched from App Store Connect. The `defaultPlans` will be replaced by `Product.subscription` data.

### L2. `IAPUtilityRow` Purchase History is a no-op

**File:** `IAPPremiumView.swift:62-68`

The "Purchase History" button has an empty action closure with a TODO comment. This is acceptable for now, but the button should either be hidden or show a "Coming soon" state to avoid user confusion.

### L3. `IAPPremiumView` background hardcoded to `.white`

**File:** `IAPPremiumView.swift:90`

```swift
.background(Color.white)
```

This won't adapt to dark mode. Consider using an adaptive color.

### L4. `SubscriptionPeriod` raw value ordering

**File:** `SubscriptionPlan.swift:3-6`

```swift
enum SubscriptionPeriod: String, CaseIterable {
    case annual
    case monthly
}
```

`CaseIterable` iteration will show annual first (correct for UI), but the naming convention puts annual before monthly. If `CaseIterable` order is relied upon for display ordering, this should be explicitly documented.

---

## Edge Cases Found

1. **Race condition on purchase:** If user taps CTA twice quickly before `isLoading` takes effect, two `Task` blocks could execute `purchaseSelectedPlan()` concurrently. The `guard !isLoading` in `IAPCTAButton` combined with `.disabled(isLoading)` should prevent this, but there's a brief window where the button is enabled but `isLoading` hasn't been set yet (since `purchaseSelectedPlan` is called from a detached `Task`).

2. **Task cancellation:** The `Task { await viewModel.purchaseSelectedPlan() }` in `IAPPremiumView` is not stored or cancelled on disappear. If the user navigates back during a purchase, the async work continues. StoreKit purchase operations should typically be allowed to complete even if UI is dismissed, but `isLoading` and `showError` state mutations on a deallocated view context could cause issues.

3. **Locale change:** `priceDisplay` uses `Locale.current` at render time. If user changes device language while on the IAP screen, the formatter will use the new locale. Not a bug, but worth noting.

4. **`restorePurchases` success check reads stale state:** `if premiumState.isPremiumUser` after `restorePurchases()` assumes the restore operation updated the state synchronously. In the real StoreKit flow, transaction updates are asynchronous — the state might not be updated yet when this check runs.

---

## Positive Observations

- **Red team findings properly addressed:** PremiumState singleton, alert bindings, navigation wiring all implemented correctly per the plan's validation log.
- **Protocol-based DI:** `StoreKitServiceProtocol` with constructor injection in `PremiumViewModel` — clean testability.
- **No force unwraps or crash risks** in the new code.
- **No retain cycles:** `@Observable` class uses value types (Bool, String, arrays) — no closure captures of self.
- **Proper error handling:** `StoreKitError` enum with `LocalizedError` conformance, silent handling for user cancellation.
- **`#if DEBUG` gating:** Mock service properly isolated.
- **Consistent with project style:** Typography, shadows, color tokens all follow existing design system patterns.
- **`defer { isLoading = false }`** in both purchase and restore — good defensive pattern.

---

## Recommended Actions

1. **[CRITICAL]** Fix `MockStoreKitService()` instantiation in `SettingsView` and `TrendsView` — create factory or add `#if DEBUG` guards (C1)
2. **[HIGH]** Add `@MainActor` to `PremiumViewModel` (H1)
3. **[HIGH]** Add `@MainActor` to `PremiumState` or access through a ViewModel (H2)
4. **[HIGH]** Cache `NumberFormatter` in `SubscriptionPlan` (H3)
5. **[MEDIUM]** Add success handling (dismiss or confirmation) after purchase (M1)
6. **[MEDIUM]** Add accessibility labels to plan cards and nav buttons (M5, M6)
7. **[MEDIUM]** Fix `StoreKitServiceProtocol.isPremiumUser` async mismatch (M4)
8. **[LOW]** Hide or disable Purchase History button until implemented (L2)
9. **[LOW]** Use adaptive background color in IAPPremiumView (L3)

---

## Metrics

- Type Coverage: N/A (no tests in this PR)
- Test Coverage: 0% (no unit tests for PremiumViewModel)
- Linting Issues: 0 (no SwiftLint violations observed)
- Files: 17 (11 new, 6 modified)
- LOC (new): ~350

## Unresolved Questions

1. Is there a `LiveStoreKitService` implementation planned, or will that be a separate PR? The current code will not compile in release without one.
2. Should `PremiumState` be `@MainActor` given that it's read directly from view bodies? This is the main architectural question for Swift 6 readiness.
3. Is the `showSuccess` flag intended for a future success screen, or should the view auto-dismiss on purchase?
