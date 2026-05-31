# Plan Review: IAP Premium Subscription Screen

**Reviewer:** code-reviewer (hostile / failure-mode analyst)
**Date:** 2026-04-26
**Plan:** `plans/0426-2258-iap-premium-screen-figma/`
**Phases reviewed:** 1-4 (all)

---

## Finding 1: PremiumLockOverlay has its own sheet presentation -- not wired to IAP screen

- **Severity:** Critical
- **Location:** Phase 4, section "4.4 Wire Navigation in SettingsView"; existing `PremiumLockOverlay.swift`
- **Flaw:** The existing `PremiumLockOverlay` (line 37 of `PremiumLockOverlay.swift`) presents `PremiumPlaceholderView` as a `.sheet`. This is the existing upgrade path that users encounter throughout the app (dashboard charts, etc). The plan adds a new `IAPPremiumView` reached via `PremiumCard` in Settings, but never replaces the `PremiumPlaceholderView` sheet with the new IAP screen. Users hitting lock overlays get the old placeholder; only Settings users see the new paywall.
- **Failure scenario:** User taps "Unlock with Premium" on any dashboard chart. Gets the old placeholder with a dead "Subscribe Now" button that just calls `dismiss()`. Revenue = zero. Meanwhile the IAP screen only exists behind a Settings card most users never tap.
- **Evidence:** `PremiumLockOverlay.swift:37` shows `.sheet(isPresented: $showPremiumSheet) { PremiumPlaceholderView() }`. The plan's file map does not list `PremiumLockOverlay.swift` as a modified file. Phase 4 success criteria only check "Navigation from Settings -> PremiumCard -> IAP screen works."
- **Suggested fix:** Add `PremiumLockOverlay.swift` to Phase 4 modified files. Replace `PremiumPlaceholderView()` sheet with `IAPPremiumView()` or a navigation to it. This is the primary conversion funnel -- not a nice-to-have.

## Finding 2: Alert binding uses .constant() -- error alert can never properly dismiss

- **Severity:** Critical
- **Location:** Phase 4, section "4.1 Build Main IAP Screen", line 110
- **Flaw:** `.alert("Error", isPresented: .constant(viewModel.errorMessage != nil))` creates a constant binding that never mutates. When the user taps "OK", `viewModel.dismiss()` sets `errorMessage` to nil, but the Binding does not update -- SwiftUI still sees the alert as presented. The alert either sticks around or re-presents depending on iOS version.
- **Failure scenario:** A purchase fails. Error alert appears. User taps "OK". `viewModel.dismiss()` clears the message. But `.constant()` cannot be set to `false` -- it always evaluates to the initial value. The alert either sticks around permanently or behaves unpredictably. On some iOS versions this creates an infinite alert loop. This is a known SwiftUI anti-pattern.
- **Evidence:** `.alert("Error", isPresented: .constant(viewModel.errorMessage != nil))` -- `.constant()` is explicitly documented as a non-mutable Binding.
- **Suggested fix:** Use a proper computed binding: `Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.dismiss() } })` or add a `@State var showError = false` that mirrors the error state.

## Finding 3: MockStoreKitService uses @AppStorage -- dual-write with ViewModel creates split-brain premium state

- **Severity:** High
- **Location:** Phase 2, section "2.3 Create Mock StoreKit Service" + section "2.4 Create PremiumViewModel"
- **Flaw:** `MockStoreKitService` uses `@AppStorage("isPremiumUser")` which requires `import SwiftUI`. A footnote says "consider using UserDefaults.standard directly" but does not mandate it. Meanwhile `PremiumViewModel` also tracks `isPremiumUser` as a separate `@Observable` property. This creates two writers to the same conceptual state: the ViewModel writes `isPremiumUser = true` after purchase (line 189), and the service writes `isPremiumStored = true` inside `purchase()`. Any view reading `@AppStorage` directly (like `PremiumLockOverlay`) sees a different truth than the ViewModel during the write timing window.
- **Failure scenario:** User completes mock purchase on IAP screen. `PremiumViewModel.isPremiumUser` becomes `true`. User navigates back to Dashboard. `PremiumLockOverlay` reads `@AppStorage("isPremiumUser")` which may still be `false` due to `@AppStorage` write timing. Premium lock overlay still appears. User thinks purchase failed.
- **Evidence:** Phase 2 code: `isPremiumStored = true` inside `MockStoreKitService.purchase()`. Phase 2 ViewModel: `isPremiumUser = true` after `storeKit.purchase(plan)` returns. Two writers, same conceptual state.
- **Suggested fix:** Mandate in Phase 2 step 2.3: use `UserDefaults.standard` directly, not `@AppStorage`. Make `PremiumViewModel` the single source of truth. Or create an `Observable` `PremiumStatusManager` that owns the UserDefaults key and is injected everywhere premium state is needed.

## Finding 4: PremiumViewModel.purchaseSelectedPlan silently swallows the "plan not found" case

- **Severity:** High
- **Location:** Phase 2, section "2.4 Create PremiumViewModel", `purchaseSelectedPlan()` method
- **Flaw:** The guard statement `guard let plan = await selectedPlanDetails else { return }` silently returns if the plan is not found. No error, no user feedback, no logging. The loading spinner stops (via `defer`) but the user has no idea why nothing happened.
- **Failure scenario:** `selectedPlan` is `.annual`. `selectedPlanDetails` calls `storeKit.availablePlans.first { $0.period == selectedPlan }`. If `availablePlans` returns an empty array (network failure, StoreKit not configured, App Store outage), the guard fails, method returns silently. User taps "Unlock Premium", spinner appears briefly, then disappears. No error message. No purchase. User thinks the app is broken.
- **Evidence:** `guard let plan = await selectedPlanDetails else { return }` -- bare `return` with no error path.
- **Suggested fix:** Replace with `guard let plan = await selectedPlanDetails else { errorMessage = "No plan available. Please try again."; return }` or throw `StoreKitError.productNotFound`.

## Finding 5: IAPPremiumView uses @State plans -- ViewModel's async plans property is dead code

- **Severity:** High
- **Location:** Phase 4, section "4.1 Build Main IAP Screen" vs Phase 2 section "2.4 PremiumViewModel"
- **Flaw:** The view declares `@State private var plans: [SubscriptionPlan] = SubscriptionPlan.defaultPlans` directly and uses this in `ForEach(plans)`. The ViewModel's `var plans: [SubscriptionPlan] { get async }` is never read by the view. When real StoreKit replaces the mock, `availablePlans` returns localized products from App Store Connect, but the view still renders hardcoded `defaultPlans`. The ViewModel was supposed to be the data source.
- **Failure scenario:** Real StoreKit integration replaces mock. `availablePlans` returns different plans (different pricing tiers, promotional offers, territory-specific plans). But the view still shows `SubscriptionPlan.defaultPlans` from the hardcoded `@State`. Users see stale/wrong plan data. The ViewModel's async `plans` property is completely dead code.
- **Evidence:** `@State private var plans: [SubscriptionPlan] = SubscriptionPlan.defaultPlans` (Phase 4, line 34). `ForEach(plans)` (Phase 4, line 54). ViewModel `plans` property (Phase 2, lines 167-169) is never referenced.
- **Suggested fix:** Remove the `@State plans` property. Store plans as a regular `[SubscriptionPlan]` on the ViewModel, populated in `loadInitialData()`. Phase 4 should read `viewModel.plans`.

## Finding 6: "Manage Subscriptions" opens real App Store URL for mock users -- no conditional

- **Severity:** High
- **Location:** Phase 4, section "4.1 Build Main IAP Screen", "Manage Subscriptions" utility row
- **Flaw:** The "Manage Subscriptions" row always opens `https://apps.apple.com/account/subscriptions` via `UIApplication.shared.open(url)`. In a mock-only phase with no real StoreKit, there are no actual subscriptions. Users who completed the mock purchase believe they have a subscription and tap "Manage Subscriptions" -- they land on an App Store page showing no active subscriptions.
- **Failure scenario:** Tester completes mock purchase. `isPremiumUser` becomes `true`. Tester taps "Manage Subscriptions". App Store shows no subscriptions. Tester files a bug: "Purchase completed but subscription not showing in App Store." Creates confusion during QA and could mislead beta testers into thinking the purchase is real.
- **Evidence:** `if let url = URL(string: "https://apps.apple.com/account/subscriptions") { UIApplication.shared.open(url) }` -- unconditional, no mock guard.
- **Suggested fix:** Gate behind the service layer. Add `func manageSubscriptions()` to `StoreKitServiceProtocol`. Mock implementation shows an alert "Mock mode -- no real subscription to manage." Real implementation opens the App Store URL.

## Finding 7: IAPHeroSection uses negative padding hack that breaks on non-390pt screens

- **Severity:** Medium
- **Location:** Phase 3, section "3.2 IAPHeroSection"
- **Flaw:** `.padding(.horizontal, -50)` is used to extend the illustration beyond parent margins. This assumes a specific viewport width (390pt, iPhone 14/15). On smaller devices (iPhone SE, 320pt) the negative padding causes overflow; on iPad the image stretches to an absurd width.
- **Failure scenario:** User on iPhone SE 3rd gen (320pt width). Hero image VStack has `.padding(.horizontal, -50)`. Parent ScrollView has `.padding(.horizontal, 16)`. Effective image width: 320 - 32 + 100 = 388pt, overflowing the 320pt screen. SwiftUI clips to bounds -- image is cut off asymmetrically.
- **Evidence:** `.padding(.horizontal, -50) // Extend beyond margins like Figma` (Phase 3, line 88)
- **Suggested fix:** Use `GeometryReader` to compute overflow based on actual width, or set a `maxWidth` on the image, or export the illustration at the correct aspect ratio and let it fill width naturally without negative padding.

## Finding 8: "Purchase History" utility row is a no-op dead button

- **Severity:** Medium
- **Location:** Phase 4, section "4.1 Build Main IAP Screen", lines 93-99
- **Flaw:** The "Purchase History" row has an empty closure: `{ /* Future: show purchase history sheet */ }`. It renders as a fully tappable button with chevron affordance but does absolutely nothing when tapped. No disabled state, no "coming soon" indicator, no toast.
- **Failure scenario:** User taps "Purchase History" expecting to see their transactions. Nothing happens. Taps again. Nothing. Assumes the app is broken or purchase didn't register. Taps "Restore Purchases" frantically. Support ticket filed.
- **Evidence:** `IAPUtilityRow(icon: "receipt", ...) { /* Future: show purchase history sheet */ }` (Phase 4, lines 93-99)
- **Suggested fix:** Either hide the row until the feature exists, or show a sheet/alert saying "Purchase history will be available in a future update." Do not ship a dead button.

## Finding 9: Dark mode explicitly excluded but all colors are hardcoded -- no adaptive tokens

- **Severity:** Medium
- **Location:** Phase 1, section "1.4 Add IAP Color Tokens" + plan.md "Key Decisions"
- **Flaw:** The plan says "Will add adaptive dark colors where existing patterns apply" but Phase 1 adds only hardcoded hex colors. The IAP screen background is `Color.white` (Phase 4). Every card background is `Color.white`. Text is `#111827` (near-black). If a user has dark mode enabled, the IAP screen is a jarring white rectangle in an otherwise dark app. No Phase or TODO exists for dark mode.
- **Failure scenario:** User has system dark mode enabled. Navigates to IAP screen. Blinding white background. Near-black text on white cards. Looks broken compared to the rest of the app which uses `adaptiveBackground`, `adaptivePrimaryText`. Apple may flag during App Review.
- **Evidence:** `static let iapTextPrimary = Color(hex: "111827")` and Phase 4: `.background(Color.white)`. Plan.md: "Dark mode: Figma is light-only. Will add adaptive dark colors where existing patterns apply." -- no phase or TODO for this.
- **Suggested fix:** Add `.environment(\.colorScheme, .light)` on `IAPPremiumView` to force light mode for this screen. This matches Figma and avoids the broken appearance. Document the decision and add a TODO for dark mode adaptation in a future phase.

## Finding 10: PriceDisplay creates new NumberFormatter on every SwiftUI body re-evaluation

- **Severity:** Medium
- **Location:** Phase 2, section "2.1 Create SubscriptionPlan Model", `priceDisplay` computed property
- **Flaw:** `NumberFormatter()` is expensive to create. The property is computed, so every SwiftUI body re-evaluation that reads `plan.priceDisplay` allocates a new formatter. With `ForEach(plans)` in a `ScrollView`, this formatter is created on every scroll frame.
- **Failure scenario:** User scrolls the IAP screen. Each frame re-evaluates `PlanSelectionCard` body, which reads `plan.priceDisplay`. Two plans x 60fps = 120 `NumberFormatter` allocations per second. On older devices this contributes to scroll jank.
- **Evidence:** `var priceDisplay: String { let formatter = NumberFormatter(); ... }` (Phase 2, lines 43-47)
- **Suggested fix:** Make `priceDisplay` a stored property initialized in `init`, or use a static `NumberFormatter` configured once. `NumberFormatter` is thread-safe for read-only use after configuration.

---

## Unresolved Questions

1. What happens to the existing `PremiumPlaceholderView`? It is never mentioned in the plan but is the active upgrade screen today via `PremiumLockOverlay`.
2. Is the plan intentionally leaving `StressOverTimeChart.swift` (which also reads `@AppStorage("isPremiumUser")`) untouched? It gates chart features behind premium -- should it route to the new IAP screen?
3. Who owns the premium state? Currently `@AppStorage` is read independently in `PremiumLockOverlay` and `StressOverTimeChart`. The plan adds a ViewModel and a mock service as additional writers. No single owner is established.
4. Real StoreKit migration path is never specified. The plan says "deferred" but does not identify which interfaces change and which stay stable. A migration note would reduce integration risk.
5. `iapCTATeal` is documented as "same as accentTeal, explicit alias." Why add a duplicate token instead of using the existing `accentTeal`?

## Summary

10 findings: 2 Critical, 4 High, 4 Medium.

The primary Critical finding is that the existing premium upgrade funnel (`PremiumLockOverlay` -> `PremiumPlaceholderView`) is completely disconnected from the new IAP screen. Building a paywall that only a fraction of users can reach (via Settings > PremiumCard) while the primary conversion trigger (lock overlay on dashboard charts) still shows a dead placeholder is a fundamental flow gap.

The second Critical finding is a non-functional alert binding that will either loop or never dismiss properly.

The High findings are: dual-write premium state, silent error swallowing, dead-code ViewModel plans property, and a real App Store URL in mock mode.

The plan is implementable as-written but will produce a feature that looks correct in screenshots while failing its primary business purpose (converting users to premium).
