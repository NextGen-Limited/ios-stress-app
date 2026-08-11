import StoreKit
import StoreKitTest
import Testing
@testable import StressMonitor

@Suite(.serialized)
@MainActor
struct EntitlementForegroundCorrectionTests {

    private static let annual = "com.stressmonitor.app.premium.annual"

    // Not registered in project.pbxproj / not part of the running test
    // target yet — see StoreKitServiceTests.swift's disabled-suite comment.
    // This test's purchase(annual) call hits the same unresolved
    // productNotFound issue on CI; route through the shared session so it's
    // ready to enable once that issue is diagnosed with a working simulator.
    private func makeSession() -> SKTestSession {
        StoreKitTestSessionProvider.session()
    }

    private func makeService() -> StoreKitService {
        let catalog = StoreKitProductCatalog(
            weeklyProductID: nil,
            monthlyProductID: nil,
            annualProductID: Self.annual,
            subscriptionGroupID: nil
        )
        let suite = "EntitlementForeground-\(UUID().uuidString)"
        let state = PremiumState(defaults: UserDefaults(suiteName: suite)!, key: "isPremiumUser")
        state.isPremiumUser = false
        return StoreKitService(premiumState: state, catalog: catalog)
    }

    @Test("Refresh after refund corrects stale-premium to false")
    func refreshCorrectsStalePremiumAfterRefund() async throws {
        let session = makeSession()
        let service = makeService()

        let annual = try #require(await service.availablePlans.first(where: { $0.period == .annual }))
        try await service.purchase(annual)
        #expect(service.isPremiumUser)

        let transaction = try #require(session.allTransactions().first(where: { $0.productIdentifier == Self.annual }))
        try session.refundTransaction(identifier: transaction.identifier)

        await service.refreshEntitlements()
        #expect(service.isPremiumUser == false)
    }
}
