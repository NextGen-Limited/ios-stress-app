import Foundation

enum StoreKitError: LocalizedError, Equatable {
    case purchaseFailed
    case purchaseCancelled
    case purchasePending
    case restoreFailed
    case productNotFound
    case productFetchFailed
    case receiptValidationFailed
    case missingProductConfiguration
    case noActiveSubscription

    var errorDescription: String? {
        switch self {
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        case .purchaseCancelled:
            return "Purchase cancelled."
        case .purchasePending:
            return "Your purchase is pending approval. Premium will unlock after Apple completes it."
        case .restoreFailed:
            return "Could not restore purchases."
        case .productNotFound:
            return "Product not found."
        case .productFetchFailed:
            return "Could not load subscription products. Please try again later."
        case .receiptValidationFailed:
            return "Could not verify purchase. Please restore purchases or contact support."
        case .missingProductConfiguration:
            return "Premium purchases are not configured for this build."
        case .noActiveSubscription:
            return "No restorable subscription was found for this Apple ID. Credit packs are one-time purchases and can't be restored — if a pack you bought didn't reach your balance, contact purchase support."
        }
    }
}

protocol StoreKitServiceProtocol {
    var availablePlans: [SubscriptionPlan] { get async }
    var isPremiumUser: Bool { get async }
    func purchase(_ plan: SubscriptionPlan) async throws
    func purchase(pack: CreditPack) async throws
    func restorePurchases() async throws
    func fetchPurchaseHistory() async -> [String]
    func refreshEntitlements() async
    func isEligibleForIntroOffer(for period: SubscriptionPeriod) async -> Bool
}
