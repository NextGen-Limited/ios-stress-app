import StoreKit
import StoreKitTest
import Testing
@testable import StressMonitor

@Suite(.serialized)
@MainActor
struct EntitlementForegroundCorrectionTests {

    private static let annual = "com.stressmonitor.app.premium.annual"

    // StoreKitTest connects one SKTestSession to the process-wide daemon at
    // a time; a second file's own SKTestSession(configurationFileNamed:)
    // silently detaches any session already active (e.g. StoreKitServiceTests'
    // shared session), and this file's own purchase consumes the annual
    // product's introductory-offer eligibility for the rest of the process.
    // Route through the single shared session in StoreKitTestSessionProvider
    // so every StoreKit-backed test file resets the same daemon connection.
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
