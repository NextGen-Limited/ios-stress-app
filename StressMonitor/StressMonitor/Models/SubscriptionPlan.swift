import Foundation

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
    var savingsPercent: Int?
    let isBestValue: Bool
    let subtitle: String?

    // StoreKit-driven fields
    let productID: String?
    let displayPrice: String?
    let billingSummary: String?
    let hasIntroductoryOffer: Bool
    let introOfferPeriodUnit: String?

    /// Human-readable period unit for display (e.g. "/week", "/month", "/year").
    var periodUnitDisplay: String {
        switch period {
        case .weekly:  return "/week"
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
            pricePerMonth: 4.99,
            pricePerPeriod: 59.88,
            period: .annual,
            savingsPercent: 37,
            isBestValue: true,
            subtitle: "Best value option",
            productID: nil,
            displayPrice: nil,
            billingSummary: "Billed annually",
            hasIntroductoryOffer: false,
            introOfferPeriodUnit: nil
        ),
        SubscriptionPlan(
            id: .monthly,
            displayName: "Monthly",
            pricePerMonth: 7.99,
            pricePerPeriod: 7.99,
            period: .monthly,
            savingsPercent: nil,
            isBestValue: false,
            subtitle: "Most popular",
            productID: nil,
            displayPrice: nil,
            billingSummary: "Billed monthly",
            hasIntroductoryOffer: false,
            introOfferPeriodUnit: nil
        ),
        SubscriptionPlan(
            id: .weekly,
            displayName: "Weekly",
            pricePerMonth: 12.95,
            pricePerPeriod: 2.99,
            period: .weekly,
            savingsPercent: nil,
            isBestValue: false,
            subtitle: "Try it out, cancel anytime",
            productID: nil,
            displayPrice: nil,
            billingSummary: "Billed weekly",
            hasIntroductoryOffer: false,
            introOfferPeriodUnit: nil
        )
    ]
}
