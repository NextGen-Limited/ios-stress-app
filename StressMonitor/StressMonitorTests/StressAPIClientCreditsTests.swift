import Foundation
import Testing
@testable import StressMonitor

/// Pins the GET /credits client contract (derived-CR-01):
/// - `getBalance()` decodes `{total, used, remaining, plan_type, free_reset_at}`
///   from GET credits with a Bearer header present
/// - 401 maps to a typed unauthorized error (stale-session probe, AUTH-02)
/// - 500 maps to a typed server error
@MainActor
struct StressAPIClientCreditsTests {

    private static let balanceFixture = """
        {"total":50,"used":7,"remaining":43,"plan_type":"free","free_reset_at":"2026-09-01T00:00:00Z"}
        """

    private func makeClient(statusCode: Int, body: Data?) -> StressAPIClient {
        RequestCaptureURLProtocol.lastRequest = nil
        RequestCaptureURLProtocol.statusCode = statusCode
        RequestCaptureURLProtocol.responseBody = body
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [RequestCaptureURLProtocol.self]
        return StressAPIClient(
            authService: MockAuthService(token: "fake-token"),
            baseURL: URL(string: "https://api.test")!,
            session: URLSession(configuration: config)
        )
    }

    @Test("getBalance decodes the credit contract from GET credits with a Bearer header")
    func getBalanceDecodesContractWithBearerHeader() async throws {
        let client = makeClient(statusCode: 200, body: Data(Self.balanceFixture.utf8))

        let balance = try await client.getBalance()

        #expect(balance.total == 50)
        #expect(balance.used == 7)
        #expect(balance.remaining == 43)
        #expect(balance.planType == .free)
        #expect(balance.freeResetAt == "2026-09-01T00:00:00Z")

        let request = try #require(RequestCaptureURLProtocol.lastRequest)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString == "https://api.test/credits")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer fake-token")
    }

    @Test("getBalance maps 401 to the unauthorized error case")
    func getBalanceMaps401ToUnauthorized() async throws {
        let client = makeClient(statusCode: 401, body: Data("{}".utf8))

        await #expect(throws: CreditsAPIError.unauthorized) {
            try await client.getBalance()
        }
    }

    @Test("getBalance maps 500 to the server error case")
    func getBalanceMaps500ToServerError() async throws {
        let client = makeClient(statusCode: 500, body: Data("{}".utf8))

        await #expect(throws: CreditsAPIError.self) {
            try await client.getBalance()
        }
    }
}
