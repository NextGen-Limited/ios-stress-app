# Paywall and premium

The premium subscription surface. A single `PaywallController` singleton owns full-screen paywall presentation from anywhere in the app. The paywall view itself renders plan selection, trust rows, and a purchase CTA backed by StoreKit 2.

## Presentation

`PaywallController` (at `StressMonitor/StressMonitor/Services/Premium/PaywallController.swift`) is mounted once at the app root:

```swift
.fullScreenCover(item: $paywall.presentation) { presentation in
    PaywallView(reason: presentation.reason)
}
```

Any view can trigger the paywall:

```swift
@Environment(PaywallController.self) private var paywall
paywall.present(reason: .trendsLongRange)
```

`present(reason:)` is a no-op when the user already has premium, so gating code can call it unconditionally. The `PaywallReason` enum captures why the paywall was shown and drives analytics and header copy.

## Views

| View | File | Purpose |
| --- | --- | --- |
| `PaywallView` | `StressMonitor/StressMonitor/Views/Premium/PaywallView.swift` | Thin wrapper that presents `IAPPremiumView` with a reason |
| `IAPPremiumView` | `StressMonitor/StressMonitor/Views/Premium/IAPPremiumView.swift` | Main paywall: hero, benefits, plan selection, CTA |
| `PurchaseSuccessView` | `StressMonitor/StressMonitor/Views/Premium/PurchaseSuccessView.swift` | Post-purchase confirmation |
| `IAPHeroSection` | `StressMonitor/StressMonitor/Views/Premium/Components/IAPHeroSection.swift` | Hero with character |
| `IAPBenefitsCard` | `StressMonitor/StressMonitor/Views/Premium/Components/IAPBenefitsCard.swift` | Benefits list |
| `PlanCard` / `PlanSelectionCard` | `StressMonitor/StressMonitor/Views/Premium/Components/` | Plan display and selection |
| `IAPCTAButton` | `StressMonitor/StressMonitor/Views/Premium/Components/IAPCTAButton.swift` | Purchase button |
| `IAPNavBar` | `StressMonitor/StressMonitor/Views/Premium/Components/IAPNavBar.swift` | Close / restore |
| `IAPUtilityRow` | `StressMonitor/StressMonitor/Views/Premium/Components/IAPUtilityRow.swift` | Terms / privacy row |
| `TrustRow` | `StressMonitor/StressMonitor/Views/Premium/Components/TrustRow.swift` | Trust signals |
| `RippleTransformationHero` | `StressMonitor/StressMonitor/Views/Premium/Components/RippleTransformationHero.swift` | Animated character hero |
| `PremiumBanner` | `StressMonitor/StressMonitor/Views/Dashboard/Components/PremiumBanner.swift` | Dashboard upsell banner |
| `PremiumLockOverlay` | `StressMonitor/StressMonitor/Views/Dashboard/Components/PremiumLockOverlay.swift` | Lock overlay on gated cards |

## View model

`PremiumViewModel` (at `StressMonitor/StressMonitor/ViewModels/PremiumViewModel.swift`) drives plan loading, purchase, and restore. It wraps `StoreKitService` and exposes `availablePlans`, `isPremiumUser`, and purchase state to `IAPPremiumView`. See [StoreKit IAP](../systems/storekit-iap.md) for the service layer.

## Premium state

`PremiumState` (at `StressMonitor/StressMonitor/Services/StoreKit/PremiumState.swift`) is an observable singleton consulted by `PaywallController` and by feature gates throughout the UI. It is refreshed by `StoreKitService.refreshEntitlements()` on launch and whenever `Transaction.updates` emits.

## Entry points for modification

- **Change plan display order or copy**: edit `IAPPremiumView.swift` and the `PlanCard` / `PlanSelectionCard` components.
- **Add a new paywall entry point**: call `paywall.present(reason: .feature(named: "..."))` from the gating view.
- **Change the no-op-on-premium rule**: edit `PaywallController.present(reason:)`.
