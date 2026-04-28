import Foundation

enum StoreKitError: LocalizedError {
    case purchaseFailed
    case purchaseCancelled
    case restoreFailed
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .purchaseFailed: return "Purchase failed. Please try again."
        case .purchaseCancelled: return "Purchase cancelled."
        case .restoreFailed: return "Could not restore purchases."
        case .productNotFound: return "Product not found."
        }
    }
}

protocol StoreKitServiceProtocol {
    var availablePlans: [SubscriptionPlan] { get async }
    var isPremiumUser: Bool { get async }
    func purchase(_ plan: SubscriptionPlan) async throws
    func restorePurchases() async throws
    func fetchPurchaseHistory() async -> [String]
}
