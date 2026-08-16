import Foundation
import Testing
@testable import StressMonitor

/// Pins the credit-balance convergence contract (derived-CR-04):
/// - `refreshBalance()` populates observable state from GET /credits
/// - metadata `credits_remaining` converges state without any client-side
///   decrement arithmetic — the server is the sole authority
/// - premium `plan_type` renders as "Unlimited" and never formats the
///   backend's 999999 remaining sentinel as a count
@MainActor
struct CreditServiceTests {

    private static let freeFixture = """
        {"total":50,"used":7,"remaining":43,"plan_type":"free","free_reset_at":"2026-09-01T00:00:00Z"}
        """

    private func makeClient(fixture: String, statusCode: Int = 200) -> StressAPIClient {
        RequestCaptureURLProtocol.lastRequest = nil
        RequestCaptureURLProtocol.statusCode = statusCode
        RequestCaptureURLProtocol.responseBody = Data(fixture.utf8)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [RequestCaptureURLProtocol.self]
        return StressAPIClient(
            authService: MockAuthService(token: "fake-token"),
            baseURL: URL(string: "https://api.test")!,
            session: URLSession(configuration: config)
        )
    }

    @Test("refreshBalance populates observable state from GET /credits")
    func refreshBalancePopulatesState() async throws {
        let service = CreditService(apiClient: makeClient(fixture: Self.freeFixture))
        #expect(service.balance == nil)

        try await service.refreshBalance()

        let balance = try #require(service.balance)
        #expect(balance.total == 50)
        #expect(balance.used == 7)
        #expect(balance.remaining == 43)
        #expect(balance.planType == .free)
        #expect(balance.freeResetAt == "2026-09-01T00:00:00Z")
    }

    @Test("apply(creditsRemaining:) converges remaining from chat metadata without local arithmetic")
    func metadataRemainingConvergesWithoutArithmetic() {
        let service = CreditService(
            balance: CreditBalance(total: 50, used: 7, remaining: 43, planType: .free, freeResetAt: nil)
        )

        service.apply(creditsRemaining: 41)

        #expect(service.balance?.remaining == 41)
        #expect(service.balance?.total == 50)
        #expect(service.balance?.used == 7)
    }

    @Test("apply(creditsRemaining:) on premium keeps the sentinel out of the display path")
    func metadataRemainingOnPremiumKeepsUnlimitedDisplay() {
        let service = CreditService(
            balance: CreditBalance(total: 999999, used: 0, remaining: 999999, planType: .premium, freeResetAt: nil)
        )

        service.apply(creditsRemaining: 999999)

        #expect(service.balance?.displayDescription == "Unlimited")
        #expect(service.balance?.displayDescription != "999999 credits")
    }

    @Test("premium plan_type renders as Unlimited, never the raw sentinel")
    func premiumBalanceDisplayRule() {
        let premium = CreditBalance(total: 999999, used: 0, remaining: 999999, planType: .premium, freeResetAt: nil)
        #expect(premium.isUnlimited)
        #expect(premium.displayDescription == "Unlimited")

        let free = CreditBalance(total: 50, used: 7, remaining: 43, planType: .free, freeResetAt: nil)
        #expect(!free.isUnlimited)
        #expect(free.displayDescription == "43 credits")
    }

    @Test("apply(full balance) replaces cached state wholesale")
    func applyFullBalanceReplacesState() {
        let service = CreditService()
        let fresh = CreditBalance(total: 60, used: 10, remaining: 50, planType: .free, freeResetAt: "2026-10-01T00:00:00Z")

        service.apply(fresh)

        #expect(service.balance == fresh)
    }
}
