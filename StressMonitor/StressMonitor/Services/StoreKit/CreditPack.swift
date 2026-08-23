import Foundation

/// Stable pack identity, independent of the resolved StoreKit product ID —
/// mirrors `SubscriptionPeriod`'s role for subscriptions. DEC-2 (packs-2).
enum CreditPackID: String, CaseIterable {
    case small
    case large
}

/// Display model for a consumable credit pack — the `SubscriptionPlan` analog
/// for the packs era.
struct CreditPack: Identifiable {
    let id: CreditPackID
    let credits: Int
    let displayName: String
    let productID: String?
    let displayPrice: String?
    /// Numeric price for per-unit savings math; `displayPrice` stays the
    /// locale-correct rendering. Nil only for hand-built display packs.
    var pricePerPack: Decimal? = nil

    /// Fallback display packs when no product IDs resolve, mirroring
    /// `SubscriptionPlan.defaultPlans`. Amounts/prices are DEC-2's decision.
    static let defaultPacks: [CreditPack] = [
        CreditPack(
            id: .small,
            credits: 10,
            displayName: "10 Credits",
            productID: nil,
            displayPrice: "$1.99",
            pricePerPack: 1.99
        ),
        CreditPack(
            id: .large,
            credits: 150,
            displayName: "150 Credits",
            productID: nil,
            displayPrice: "$19.99",
            pricePerPack: 19.99
        )
    ]
}
