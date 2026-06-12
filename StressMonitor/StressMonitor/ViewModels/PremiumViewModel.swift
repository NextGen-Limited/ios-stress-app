import Foundation

@MainActor
@Observable
final class PremiumViewModel {
    let storeKit: StoreKitServiceProtocol
    let premiumState: PremiumState

    var selectedPlan: SubscriptionPeriod = .annual
    var plans: [SubscriptionPlan] = []
    var isLoading = false
    var showError = false
    var errorMessage: String?
    var showSuccess = false

    init(storeKit: StoreKitServiceProtocol, premiumState: PremiumState) {
        self.storeKit = storeKit
        self.premiumState = premiumState
    }

    var selectedPlanDetails: SubscriptionPlan? {
        plans.first { $0.period == selectedPlan }
    }

    func loadInitialData() async {
        plans = await storeKit.availablePlans

        // Select annual when present, otherwise first available plan
        if plans.contains(where: { $0.period == .annual }) {
            selectedPlan = .annual
        } else if let first = plans.first {
            selectedPlan = first.period
        }
    }

    func purchaseSelectedPlan() async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let plan = selectedPlanDetails else {
                errorMessage = "Plan not available. Please try again."
                showError = true
                return
            }
            try await storeKit.purchase(plan)
            // Derive success from premium state, not from purchase call alone
            showSuccess = premiumState.isPremiumUser
        } catch StoreKitError.purchaseCancelled {
            // User cancelled — silent
        } catch StoreKitError.purchasePending {
            errorMessage = StoreKitError.purchasePending.errorDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await storeKit.restorePurchases()
            if premiumState.isPremiumUser {
                showSuccess = true
            }
        } catch StoreKitError.noActiveSubscription {
            errorMessage = StoreKitError.noActiveSubscription.errorDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func dismissError() {
        showError = false
        errorMessage = nil
    }
}
