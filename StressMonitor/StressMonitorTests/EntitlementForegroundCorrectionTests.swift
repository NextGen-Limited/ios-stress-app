import StoreKit
import StoreKitTest
import Testing
@testable import StressMonitor

// DISPOSITION 2026-09-04 (ENV-lineage / WINDOWS #6, 02-04 Task 3 isolation-
// matrix confirmation): purchase(annual) throws productNotFound — the same
// StoreKitTest session-isolation failure documented in
// StoreKitServiceTests.swift's header. Failure signature: exit 65, 1 issue,
// `Caught error: productNotFound` at the purchase(annual) call site (not a
// #expect mismatch). Ruled out this session: CI-runner specificity — the
// suite was re-enabled and run targeted with GSD_CI unset on TWO local
// simulators (current iPhone 17 5DD825B4-…, and a disposable fresh iPhone
// 16) and failed identically both times, so this reproduces locally, not
// only on the macos-15 CI runner. Previously ruled out (per the IAP-01
// investigation this suite's original comment cited): product-ID
// registration was fixed in phase 02 plan 02-03 (StoreKitProductCatalogLiveTests
// now resolves live catalog IDs, verified green this session — see
// 02-04-SUMMARY.md), so the residual cause is the same StoreKitTest
// daemon/session-isolation issue as StoreKitServiceTests, not unresolved
// product IDs. Residual risk: the refund → refreshEntitlements →
// stale-premium-correction path this suite pins has no automated coverage;
// needs a working local CoreSimulator/XCTestDevices layer to diagnose
// further (WINDOWS.md item #3). WINDOWS.md #6 stays open with this updated
// disposition (ledger CLI has no update-description verb — the file header
// is the authoritative bar-meeting record; see 02-04-SUMMARY.md).
@Suite(.serialized, .disabled("StoreKitTest session-isolation bug — reproduces locally, see file header (2026-09-04 disposition)"))
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
