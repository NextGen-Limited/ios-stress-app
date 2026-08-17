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

    // MARK: - redeemPurchase (POST /credits/redeem — pinned 02-02/02-03 contract)

    /// URLProtocol delivers the request body as a stream, not `httpBody`.
    private func body(of request: URLRequest) -> Data {
        if let data = request.httpBody { return data }
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let capacity = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: capacity)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }

    @Test("redeemPurchase posts the pinned contract to credits/redeem and decodes the balance")
    func redeemPurchasePostsPinnedContract() async throws {
        let client = makeClient(statusCode: 200, body: Data(Self.balanceFixture.utf8))

        let balance = try await client.redeemPurchase(jws: "jws.token.value")

        #expect(balance.total == 50)
        #expect(balance.remaining == 43)

        let request = try #require(RequestCaptureURLProtocol.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://api.test/credits/redeem")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer fake-token")

        let json = try #require(
            JSONSerialization.jsonObject(with: body(of: request)) as? [String: Any]
        )
        #expect(json["transaction_jws"] as? String == "jws.token.value")
        #expect(json.count == 1)
    }

    @Test("redeemPurchase maps the pinned 400 code to the invalid-transaction error")
    func redeemPurchaseMaps400ToInvalidTransaction() async throws {
        let client = makeClient(
            statusCode: 400,
            body: Data(#"{"error":"Invalid transaction","code":"INVALID_TRANSACTION"}"#.utf8)
        )

        await #expect(throws: CreditsAPIError.invalidTransaction) {
            try await client.redeemPurchase(jws: "garbage.jws")
        }
    }

    @Test("redeemPurchase maps 401 to the unauthorized error case")
    func redeemPurchaseMaps401ToUnauthorized() async throws {
        let client = makeClient(statusCode: 401, body: Data("{}".utf8))

        await #expect(throws: CreditsAPIError.unauthorized) {
            try await client.redeemPurchase(jws: "jws")
        }
    }

    // MARK: - verifySubscription (POST /credits/premium/verify — DEC-1 server premium)

    @Test("verifySubscription posts the subscription JWS to credits/premium/verify")
    func verifySubscriptionPostsToCreditsPremiumVerify() async throws {
        let premiumFixture = #"{"total":999999,"used":0,"remaining":999999,"plan_type":"premium","free_reset_at":null}"#
        let client = makeClient(statusCode: 200, body: Data(premiumFixture.utf8))

        let balance = try await client.verifySubscription(jws: "sub.jws")

        #expect(balance.planType == .premium)

        let request = try #require(RequestCaptureURLProtocol.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://api.test/credits/premium/verify")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer fake-token")

        let json = try #require(
            JSONSerialization.jsonObject(with: body(of: request)) as? [String: Any]
        )
        #expect(json["transaction_jws"] as? String == "sub.jws")
        #expect(json.count == 1)
    }
}
