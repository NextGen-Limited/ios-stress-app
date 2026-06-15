import Foundation
import Testing
@testable import StressMonitor

// MARK: - Fake StoreKit Service

private final class FakeStoreKitService: StoreKitServiceProtocol {
    var stubbedPlans: [SubscriptionPlan] = SubscriptionPlan.defaultPlans
    var stubbedIsPremiumUser: Bool = false
    var purchaseStub: (() async throws -> Void)?
    var restoreStub: (() async throws -> Void)?
    var didCallRefresh = false

    var availablePlans: [SubscriptionPlan] {
        get async { stubbedPlans }
    }

    var isPremiumUser: Bool {
        get async { stubbedIsPremiumUser }
    }

    func purchase(_ plan: SubscriptionPlan) async throws {
        try await purchaseStub?()
    }

    func restorePurchases() async throws {
        try await restoreStub?()
    }

    func fetchPurchaseHistory() async -> [String] {
        return []
    }

    func refreshEntitlements() async {
        didCallRefresh = true
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

        #expect(vm.plans.count == 3)
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
        service.stubbedPlans = [
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
        service.purchaseStub = { /* no-op, Premium stays false */ }

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

        service.purchaseStub = { [weak state] in
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

        service.purchaseStub = {
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

        service.purchaseStub = {
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

        service.purchaseStub = {
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

        service.purchaseStub = {
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

        service.restoreStub = { [weak state] in
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

        service.restoreStub = {
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

        service.restoreStub = {
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
