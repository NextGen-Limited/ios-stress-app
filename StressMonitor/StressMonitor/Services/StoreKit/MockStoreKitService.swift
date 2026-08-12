import Foundation

#if DEBUG
final class MockStoreKitService: StoreKitServiceProtocol {
    private let premiumState: PremiumState

    let availablePlans: [SubscriptionPlan] = SubscriptionPlan.defaultPlans

    var isPremiumUser: Bool { premiumState.isPremiumUser }

    init(premiumState: PremiumState) {
        self.premiumState = premiumState
    }

    func purchase(_ plan: SubscriptionPlan) async throws {
        try await Task.sleep(for: .seconds(1))
        premiumState.isPremiumUser = true
    }

    func restorePurchases() async throws {
        try await Task.sleep(for: .seconds(1))
        premiumState.isPremiumUser = true
    }

    func fetchPurchaseHistory() async -> [String] {
        return []
    }

    func refreshEntitlements() async {
        // No-op for mock
    }

    func isEligibleForIntroOffer(for period: SubscriptionPeriod) async -> Bool {
        availablePlans.first(where: { $0.period == period })?.hasIntroductoryOffer ?? false
    }
}
#endif
