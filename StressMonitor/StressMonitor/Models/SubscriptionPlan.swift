import Foundation

enum SubscriptionPeriod: String, CaseIterable {
    case annual
    case monthly
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

    // StoreKit-driven fields
    let productID: String?
    let displayPrice: String?
    let billingSummary: String?

    /// Human-readable period unit for display (e.g. "/month", "/year").
    var periodUnitDisplay: String {
        switch period {
        case .monthly: return "/month"
        case .annual:  return "/year"
        }
    }

    private static let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale.current
        return f
    }()

    /// Prefer StoreKit `displayPrice` when available, otherwise format `pricePerPeriod`
    /// (not `pricePerMonth`) so it aligns with `periodUnitDisplay` ("/month" or "/year").
    var priceDisplay: String {
        if let displayPrice, !displayPrice.isEmpty {
            return displayPrice
        }
        return Self.priceFormatter.string(from: pricePerPeriod as NSDecimalNumber) ?? "$0.00"
    }

    var savingsDisplay: String? {
        guard let savings = savingsPercent, savings > 0 else { return nil }
        return "Save \(savings)%"
    }

    static let defaultPlans: [SubscriptionPlan] = [
        SubscriptionPlan(
            id: .annual,
            displayName: "Annually",
            pricePerMonth: 14.99,
            pricePerPeriod: 179.88,
            period: .annual,
            savingsPercent: 25,
            isBestValue: true,
            subtitle: "Best value option",
            productID: nil,
            displayPrice: nil,
            billingSummary: "Billed annually"
        ),
        SubscriptionPlan(
            id: .monthly,
            displayName: "Monthly",
            pricePerMonth: 19.99,
            pricePerPeriod: 19.99,
            period: .monthly,
            savingsPercent: nil,
            isBestValue: false,
            subtitle: nil,
            productID: nil,
            displayPrice: nil,
            billingSummary: "Billed monthly"
        )
    ]
}
