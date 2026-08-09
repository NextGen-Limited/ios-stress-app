import StoreKit
import StoreKitTest
import Testing
@testable import StressMonitor

@Suite(.serialized)
@MainActor
struct StoreKitServiceTests {

    private static let weekly = "com.stressmonitor.app.premium.weekly"
    private static let monthly = "com.stressmonitor.app.premium.monthly"
    private static let annual = "com.stressmonitor.app.premium.annual"

    private func makeSession() throws -> SKTestSession {
        let session = try SKTestSession(configurationFileNamed: "StressMonitorProducts.storekit")
        session.disableDialogs = true
        session.clearTransactions()
        return session
    }

    private func makeService() -> StoreKitService {
        let catalog = StoreKitProductCatalog(
            weeklyProductID: Self.weekly,
            monthlyProductID: Self.monthly,
            annualProductID: Self.annual,
            subscriptionGroupID: nil
        )
        let suite = "StoreKitServiceTests-\(UUID().uuidString)"
        let state = PremiumState(defaults: UserDefaults(suiteName: suite)!, key: "isPremiumUser")
        state.isPremiumUser = false
        return StoreKitService(premiumState: state, catalog: catalog)
    }

    @Test("Available plans load all three products")
    func availablePlansLoadAllThree() async throws {
        _ = try makeSession()
        let plans = await makeService().availablePlans
        #expect(Set(plans.map(\.period)) == [.weekly, .monthly, .annual])
    }

    @Test("Annual plan carries the introductory offer, monthly does not")
    func introductoryOfferFlag() async throws {
        _ = try makeSession()
        let plans = await makeService().availablePlans
        let annual = try #require(plans.first(where: { $0.period == .annual }))
        let monthly = try #require(plans.first(where: { $0.period == .monthly }))
        #expect(annual.hasIntroductoryOffer)
        #expect(monthly.hasIntroductoryOffer == false)
    }

    @Test("Purchase grants premium entitlement")
    func purchaseGrantsEntitlement() async throws {
        _ = try makeSession()
        let service = makeService()
        #expect(service.isPremiumUser == false)

        let annual = try #require(await service.availablePlans.first(where: { $0.period == .annual }))
        try await service.purchase(annual)

        #expect(service.isPremiumUser)
    }

    @Test("Restore on a fresh service recovers entitlement")
    func restoreRecoversEntitlement() async throws {
        _ = try makeSession()
        let buyer = makeService()
        let annual = try #require(await buyer.availablePlans.first(where: { $0.period == .annual }))
        try await buyer.purchase(annual)

        let fresh = makeService()
        #expect(fresh.isPremiumUser == false)
        try await fresh.restorePurchases()
        #expect(fresh.isPremiumUser)
    }
}
