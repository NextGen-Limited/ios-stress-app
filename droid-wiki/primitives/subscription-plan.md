# Subscription plan

The display model for a StoreKit subscription tier. One instance per billing period (weekly, monthly, annual).

## Type

File: `StressMonitor/StressMonitor/Models/SubscriptionPlan.swift`.

```swift
enum SubscriptionPeriod: String, CaseIterable {
    case annual
    case monthly
    case weekly
}

struct SubscriptionPlan: Identifiable {
    let id: SubscriptionPeriod
    let displayName: String
    let pricePerMonth: Decimal
    let pricePerPeriod: Decimal
    let period: SubscriptionPeriod
    let savingsPercent: Int?
    let isBestValue: Bool
    let subtitle: String?
    let productID: String?
    let displayPrice: String?
    let billingSummary: String?
}
```

## Default plans

`SubscriptionPlan.defaultPlans` provides three fallback display-only plans so the paywall renders even when StoreKit cannot resolve real products. These have `productID = nil` and `displayPrice = nil`, so attempts to purchase them fail with `StoreKitError.missingProductConfiguration`.

| Period | Monthly equiv | Period price | Savings | Best value |
| --- | --- | --- | --- | --- |
| annual | $4.99/mo | $59.88 | 37% | yes |
| monthly | $7.99/mo | $7.99 | - | no |
| weekly | $12.95/mo equiv | $2.99/wk | - | no |

## Resolution

When StoreKit resolves real products, `StoreKitService.availablePlans` replaces the default plans with `SubscriptionPlan` instances populated from `Product` metadata: localized `displayPrice`, real `productID`, and `billingSummary` derived from the product's subscription period. See [StoreKit IAP](../systems/storekit-iap.md) for the full resolution flow.

## Display helpers

- `priceDisplay`: prefers StoreKit `displayPrice`, falls back to formatted `pricePerPeriod`.
- `periodUnitDisplay`: "/week", "/month", or "/year".
- `savingsDisplay`: "Save N%" or `nil`.
