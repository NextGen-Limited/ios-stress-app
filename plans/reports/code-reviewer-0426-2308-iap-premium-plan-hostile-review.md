# Hostile Plan Review: IAP Premium Subscription Screen

**Date:** 2026-04-26
**Reviewer:** code-reviewer (Assumption Destroyer)
**Plan:** `plans/0426-2258-iap-premium-screen-figma/`

## Findings

### Finding 1: MockStoreKitService uses @AppStorage in a service class -- compile trap and architectural violation
- **Severity:** Critical
- **Location:** Phase 2, section "2.3 Create Mock StoreKit Service"
- **Flaw:** `@AppStorage` is a `DynamicProperty` designed for SwiftUI Views. Using it in a plain `class` (not a View) is undefined behavior. The plan's own note acknowledges this but does not resolve it. Additionally, the concrete `isPremiumUser` getter is synchronous but the protocol declares it `async` -- this is a compile error.
- **Failure scenario:** Developer copies code verbatim. Either compilation fails, or `@AppStorage` does not coalesce across instances as expected and premium state silently desynchronizes between the service and views.
- **Evidence:** `var isPremiumUser: Bool { get { isPremiumStored } }` (sync) vs protocol `var isPremiumUser: Bool { get async }` (async). Note: "consider using UserDefaults.standard" -- unresolved.
- **Suggested fix:** Use `UserDefaults.standard.bool(forKey:)` in the service. Make concrete getter `async` to match protocol.

### Finding 2: Dual premium state -- @AppStorage in service AND stored property in ViewModel
- **Severity:** Critical
- **Location:** Phase 2, section "2.4"; Phase 4, section "4.1"
- **Flaw:** ViewModel has `var isPremiumUser = false` (plain stored property). MockStoreKitService writes `@AppStorage("isPremiumUser")`. Existing views (`PremiumLockOverlay`, `StressOverTimeChart`) read `@AppStorage("isPremiumUser")` directly. Three separate state sources for the same concept.
- **Failure scenario:** Purchase succeeds. ViewModel sets its own `isPremiumUser = true`. Service sets `@AppStorage = true`. User dismisses. ViewModel deallocated. `PremiumLockOverlay` reads `@AppStorage` -- works. But if restore fails partially, ViewModel shows premium while `@AppStorage` says false. No single source of truth.
- **Evidence:** Phase 2: `var isPremiumUser = false` in ViewModel. Phase 2: `isPremiumStored = true` in MockStoreKitService. Existing code: `@AppStorage("isPremiumUser")` in PremiumLockOverlay.
- **Suggested fix:** Eliminate dual state. ViewModel should use `@AppStorage` directly as its `isPremiumUser` property, or always query the service.

### Finding 3: PremiumViewModel default-initializes MockStoreKitService -- hidden singleton bypasses DI
- **Severity:** High
- **Location:** Phase 2, section "2.4"; Phase 4, section "4.1"
- **Flaw:** `init(storeKit: = MockStoreKitService())` makes the mock the invisible default. `IAPPremiumView` uses `@State private var viewModel = PremiumViewModel()` with no injection. No `#if DEBUG` guard, no environment-based switching, no migration path.
- **Failure scenario:** Real StoreKit integration phase arrives. Developer must find and update every call site. If they miss the `@State` init in IAPPremiumView, production silently uses mock. Plan has no compilation strategy to prevent this.
- **Evidence:** `@State private var viewModel = PremiumViewModel()` in Phase 4. Default parameter in Phase 2.
- **Suggested fix:** Use `@Environment` dependency or explicit injection. Do not default to mock.

### Finding 4: Purchase History row is a dead-end no-op button
- **Severity:** High
- **Location:** Phase 4, section "4.1"
- **Flaw:** "Purchase History" row has empty action `{ }`. The chevron implies navigation. Tapping does nothing. No disabled state, no visual treatment, no "Coming soon" label.
- **Failure scenario:** User taps "Purchase History" expecting transaction list. Zero feedback. Erodes trust. May flag in App Store review.
- **Evidence:** `} action: { /* Future: show purchase history sheet */ }` -- effectively `{ }`.
- **Suggested fix:** Remove row entirely until feature is real, or implement a minimal "No purchases yet" sheet.

### Finding 5: All IAP components use hardcoded Color.white -- zero dark mode support
- **Severity:** High
- **Location:** Phase 3 sections 3.3, 3.4, 3.5; Phase 4 section 4.1
- **Flaw:** Plan acknowledges "Figma is light-only. Will add adaptive dark colors" but implements zero adaptive colors. Every component uses `Color.white` for backgrounds. The existing app has full dark mode support via `Color(light:dark:)`.
- **Failure scenario:** Dark mode user navigates to IAP screen. Entire screen is white -- cards, background, everything. Jarring light-mode island in a dark app. Near-black text (`#111827`) on white backgrounds.
- **Evidence:** Plan.md Key Decisions mentions dark mode. Phase 3/4 components all use `Color.white`. No adaptive IAP tokens in Phase 1.
- **Suggested fix:** Define adaptive IAP color tokens in Phase 1. Use `Color(light: .white, dark: ...)` pattern matching existing codebase.

### Finding 6: .constant() binding on error alert prevents dismissal
- **Severity:** High
- **Location:** Phase 4, section "4.1"
- **Flaw:** `.alert("Error", isPresented: .constant(viewModel.errorMessage != nil))` uses `.constant()` which creates a non-mutating binding. When the user taps "OK" and `viewModel.dismiss()` sets `errorMessage = nil`, SwiftUI's alert system cannot dismiss because the binding is constant.
- **Failure scenario:** Error occurs. Alert appears. User taps OK. Alert may not dismiss or may reappear on next render cycle. `.constant()` is a known SwiftUI pitfall for alert bindings.
- **Evidence:** `.alert("Error", isPresented: .constant(viewModel.errorMessage != nil))` in Phase 4.
- **Suggested fix:** Use a proper `@State` or `@Bindable` boolean for alert isPresented.

### Finding 7: Custom IAPNavBar disables iOS swipe-back gesture
- **Severity:** Medium
- **Location:** Phase 3, section "3.1"; Phase 4, section "4.1"
- **Flaw:** `.navigationBarHidden(true)` disables the interactive pop gesture. Custom back button requires tap on a small 36x36 target. One-handed use degraded.
- **Failure scenario:** User navigates to IAP screen. Swipes back (muscle memory). Nothing happens. Must tap the small back button. This is a usability regression from standard NavigationStack behavior.
- **Evidence:** Phase 4: `.navigationBarHidden(true)`. Phase 3: custom IAPNavBar with tap-only back button.
- **Suggested fix:** Consider `.sheet` presentation (matches Figma close button UX better) or re-enable swipe gesture via UINavigationController interop.

### Finding 8: showSuccess flag is set but never consumed by UI
- **Severity:** High
- **Location:** Phase 2, section "2.4"; Phase 4, section "4.1"
- **Flaw:** ViewModel sets `showSuccess = true` after purchase/restore. IAPPremiumView never reads this flag. No success alert, no confirmation, no auto-dismiss.
- **Failure scenario:** User completes purchase. Loading spinner stops. Screen looks identical. User is confused -- did it work? No feedback at all.
- **Evidence:** Phase 2: `showSuccess = true` in purchaseSelectedPlan() and restorePurchases(). Phase 4: no reference to showSuccess.
- **Suggested fix:** Add success UI: alert, auto-dismiss, or confirmation view replacing plan selection.

### Finding 9: PremiumCard rewrite removes widget CTA without migration plan
- **Severity:** Medium
- **Location:** Phase 4, section "4.3"
- **Flaw:** Existing PremiumCard is "Set widget now!" -- the primary widget discovery mechanism at top of Settings. Plan rewrites it as a Premium upsell card. Widget CTA is not relocated.
- **Failure scenario:** Users who discovered widgets via the prominent top card can no longer find it. Widget discovery is buried in the less-visible WidgetCard lower in settings.
- **Evidence:** Current: "Set widget now!" / "Widgets that nudge you with insights". Plan changes to: "Premium" / "Unlock advanced features". No widget CTA migration.
- **Suggested fix:** Document that widget CTA removal is intentional, or relocate widget discovery to another prominent position.

### Finding 10: No wiring of existing premium entry points to new IAP screen
- **Severity:** Medium
- **Location:** Phase 4 (missing scope)
- **Flaw:** The app has three existing premium entry points: (1) `PremiumBanner` on Dashboard with empty "Upgrade Now" action, (2) `PremiumBannerView` in Trends with `action: () -> Void = {}`, (3) `PremiumPlaceholderView` shown via sheet from `PremiumLockOverlay`. The plan only wires the Settings PremiumCard. All other entry points remain dead buttons pointing to the old placeholder.
- **Failure scenario:** User sees "UNLOCK PREMIUM" banner on Dashboard, taps "Upgrade Now". Nothing happens. User sees lock overlay on stress chart, taps "Unlock with Premium", gets the old `PremiumPlaceholderView` -- a completely different premium screen than the new IAP screen. Two inconsistent premium experiences in the same app.
- **Evidence:** PremiumBanner.swift line 25: `Button(action: { /* Premium upgrade action */ })`. PremiumBannerView.swift: `action: () -> Void = {}`. PremiumLockOverlay.swift: `.sheet(isPresented:)` opens `PremiumPlaceholderView`.
- **Suggested fix:** Wire at minimum the `PremiumBannerView` action and `PremiumLockOverlay` sheet to present `IAPPremiumView`. Or document as Phase 5 scope.

## Unresolved Questions

1. What is the compilation/DI strategy for switching from MockStoreKitService to real StoreKit 2? No `#if DEBUG`, no environment key, no factory.
2. Are `PremiumBanner` (Dashboard) and `PremiumBannerView` (Trends) intended to be wired to IAPPremiumView? Currently dead buttons.
3. `PremiumPlaceholderView` (from PremiumLockOverlay) is a separate premium screen. Will it be replaced by IAPPremiumView? Two inconsistent premium experiences is worse than one.
4. Annual pricing: $14.99/mo x 12 = $179.88/yr. "Save 25%" claim requires monthly to be $19.99. Is this pricing final? Hardcoding prices in the model will require app updates to change them.

## Summary

- **Critical:** 2 (state architecture, compile trap)
- **High:** 5 (DI pattern, dead-end UI, dark mode, alert binding, missing success state)
- **Medium:** 3 (swipe gesture, widget CTA loss, unwired entry points)
- **Total:** 10 findings

The plan's core structural risk is the state architecture: three separate holders for `isPremiumUser` with no declared single source of truth. This must be resolved before implementation begins.
