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
            premiumState.isPremiumUser = true
            showSuccess = true
        } catch StoreKitError.purchaseCancelled {
            // User cancelled — silent
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
            if premiumState.isPremiumUser { showSuccess = true }
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
