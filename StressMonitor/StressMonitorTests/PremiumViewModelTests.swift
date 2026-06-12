import Foundation
import Testing
@testable import StressMonitor

// MARK: - Fake StoreKit Service

private final class FakeStoreKitService: StoreKitServiceProtocol {
    var _availablePlans: [SubscriptionPlan] = SubscriptionPlan.defaultPlans
    var _isPremiumUser: Bool = false
    var _purchaseResult: (() async throws -> Void)?
    var _restoreResult: (() async throws -> Void)?
    var _refreshCalled = false

    var availablePlans: [SubscriptionPlan] {
        get async { _availablePlans }
    }

    var isPremiumUser: Bool {
        get async { _isPremiumUser }
    }

    func purchase(_ plan: SubscriptionPlan) async throws {
        try await _purchaseResult?()
    }

    func restorePurchases() async throws {
        try await _restoreResult?()
    }

    func fetchPurchaseHistory() async -> [String] {
        return []
    }

    func refreshEntitlements() async {
        _refreshCalled = true
    }
}

// MARK: - Tests

@MainActor
struct PremiumViewModelTests {

    /// Helper to create an isolated PremiumState that doesn't pollute real UserDefaults.
    private func makeIsolatedState(isPremium: Bool = false) -> PremiumState {
        let defaults = UserDefaults(suiteName: "PremiumViewModelTests_\(UUID().uuidString)")!
        let state = PremiumState(defaults: defaults, key: "isPremiumUser")
        state.isPremiumUser = isPremium
        return state
    }

    // MARK: - loadInitialData

    @Test("loadInitialData loads plans")
    func loadInitialDataLoadsPlans() async {
        let service = FakeStoreKitService()
        let state = makeIsolatedState()
        let vm = PremiumViewModel(storeKit: service, premiumState: state)

        await vm.loadInitialData()

        #expect(vm.plans.count == 2)
    }

    @Test("loadInitialData selects annual when present")
    func loadInitialDataSelectsAnnual() async {
        let service = FakeStoreKitService()
        let state = makeIsolatedState()
        let vm = PremiumViewModel(storeKit: service, premiumState: state)

        await vm.loadInitialData()

        #expect(vm.selectedPlan == .annual)
    }

    @Test("loadInitialData selects first plan when annual not present")
    func loadInitialDataSelectsFirstWhenNoAnnual() async {
        let service = FakeStoreKitService()
        service._availablePlans = [
            SubscriptionPlan(
                id: .monthly,
                displayName: "Monthly",
                pricePerMonth: 9.99,
                pricePerPeriod: 9.99,
                period: .monthly,
                savingsPercent: nil,
                isBestValue: false,
                subtitle: nil,
                productID: nil,
                displayPrice: nil,
                billingSummary: nil
            )
        ]
        let state = makeIsolatedState()
        let vm = PremiumViewModel(storeKit: service, premiumState: state)

        await vm.loadInitialData()

        #expect(vm.selectedPlan == .monthly)
    }

    // MARK: - Purchase

    @Test("purchaseSelectedPlan calls purchase and sets success only if Premium state becomes true")
    func purchaseSuccessSetsSuccessOnlyIfPremium() async {
        let service = FakeStoreKitService()
        let state = makeIsolatedState()
        let vm = PremiumViewModel(storeKit: service, premiumState: state)

        await vm.loadInitialData()

        // Simulate purchase succeeding but Premium not yet verified
        service._purchaseResult = { /* no-op, Premium stays false */ }

        await vm.purchaseSelectedPlan()

        #expect(!vm.showSuccess)
        #expect(!vm.showError)
    }

    @Test("purchaseSelectedPlan sets success when Premium state is true after purchase")
    func purchaseSuccessSetsSuccessWhenPremiumTrue() async {
        let service = FakeStoreKitService()
        let state = makeIsolatedState()
        let vm = PremiumViewModel(storeKit: service, premiumState: state)

        await vm.loadInitialData()

        service._purchaseResult = { [weak state] in
            state?.isPremiumUser = true
        }

        await vm.purchaseSelectedPlan()

        #expect(vm.showSuccess)
    }

    @Test("Purchase cancellation does not set showError")
    func purchaseCancellationSilent() async {
        let service = FakeStoreKitService()
        let state = makeIsolatedState()
        let vm = PremiumViewModel(storeKit: service, premiumState: state)

        await vm.loadInitialData()

        service._purchaseResult = {
            throw StoreKitError.purchaseCancelled
        }

        await vm.purchaseSelectedPlan()

        #expect(!vm.showError)
        #expect(!vm.showSuccess)
    }

    @Test("Purchase failure sets showError and errorMessage")
    func purchaseFailureSetsError() async {
        let service = FakeStoreKitService()
        let state = makeIsolatedState()
        let vm = PremiumViewModel(storeKit: service, premiumState: state)

        await vm.loadInitialData()

        service._purchaseResult = {
            throw StoreKitError.purchaseFailed
        }

        await vm.purchaseSelectedPlan()

        #expect(vm.showError)
        #expect(vm.errorMessage != nil)
    }

    @Test("Pending purchase shows friendly alert but does not mark Premium active")
    func pendingPurchaseShowsAlert() async {
        let service = FakeStoreKitService()
        let state = makeIsolatedState()
        let vm = PremiumViewModel(storeKit: service, premiumState: state)

        await vm.loadInitialData()

        service._purchaseResult = {
            throw StoreKitError.purchasePending
        }

        await vm.purchaseSelectedPlan()

        #expect(vm.showError)
        #expect(vm.errorMessage == StoreKitError.purchasePending.errorDescription)
        #expect(!state.isPremiumUser)
    }

    @Test("Missing product configuration shows error")
    func missingConfigShowsError() async {
        let service = FakeStoreKitService()
        let state = makeIsolatedState()
        let vm = PremiumViewModel(storeKit: service, premiumState: state)

        await vm.loadInitialData()

        service._purchaseResult = {
            throw StoreKitError.missingProductConfiguration
        }

        await vm.purchaseSelectedPlan()

        #expect(vm.showError)
        #expect(!state.isPremiumUser)
    }

    // MARK: - Restore

    @Test("Restore success sets success when Premium state is true")
    func restoreSuccessSetsSuccess() async {
        let service = FakeStoreKitService()
        let state = makeIsolatedState()
        let vm = PremiumViewModel(storeKit: service, premiumState: state)

        service._restoreResult = { [weak state] in
            state?.isPremiumUser = true
        }

        await vm.restorePurchases()

        #expect(vm.showSuccess)
    }

    @Test("Restore with no active subscription sets showError")
    func restoreNoActiveSubscriptionSetsError() async {
        let service = FakeStoreKitService()
        let state = makeIsolatedState()
        let vm = PremiumViewModel(storeKit: service, premiumState: state)

        service._restoreResult = {
            throw StoreKitError.noActiveSubscription
        }

        await vm.restorePurchases()

        #expect(vm.showError)
        #expect(vm.errorMessage == StoreKitError.noActiveSubscription.errorDescription)
        #expect(!state.isPremiumUser)
    }

    @Test("Restore failure sets showError")
    func restoreFailureSetsError() async {
        let service = FakeStoreKitService()
        let state = makeIsolatedState()
        let vm = PremiumViewModel(storeKit: service, premiumState: state)

        service._restoreResult = {
            throw StoreKitError.restoreFailed
        }

        await vm.restorePurchases()

        #expect(vm.showError)
    }

    // MARK: - dismissError

    @Test("dismissError clears error state")
    func dismissErrorClearsState() async {
        let service = FakeStoreKitService()
        let state = makeIsolatedState()
        let vm = PremiumViewModel(storeKit: service, premiumState: state)

        vm.showError = true
        vm.errorMessage = "test error"

        vm.dismissError()

        #expect(!vm.showError)
        #expect(vm.errorMessage == nil)
    }
}
