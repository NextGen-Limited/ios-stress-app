import XCTest
@testable import StressMonitor

/// Exercises the REST-level auth exchange this app needs to replace the
/// hardcoded, already-expired guest JWT: anonymous sign-in and refresh.
/// Mocked via URLProtocol — no live network call, no dependency on whether
/// the Supabase dashboard providers are actually enabled.
final class SupabaseAuthServiceTests: XCTestCase {

    private func mockedSession(statusCode: Int, json: [String: Any]) -> URLSession {
        MockAuthURLProtocol.responseStatusCode = statusCode
        MockAuthURLProtocol.responseBody = try! JSONSerialization.data(withJSONObject: json)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockAuthURLProtocol.self]
        return URLSession(configuration: config)
    }

    func testSignInAnonymouslyDecodesSession() async throws {
        let session = mockedSession(statusCode: 200, json: [
            "access_token": "test-access-token",
            "refresh_token": "test-refresh-token",
            "expires_in": 3600,
            "user": ["id": "abc-123", "is_anonymous": true]
        ])
        let service = SupabaseAuthService(session: session)

        let result = try await service.signInAnonymously()

        XCTAssertEqual(result.accessToken, "test-access-token")
        XCTAssertEqual(result.refreshToken, "test-refresh-token")
        XCTAssertEqual(result.user?.isAnonymous, true)
    }

    func testSignInAnonymouslyThrowsOnServerError() async {
        let session = mockedSession(statusCode: 500, json: ["error": "internal"])
        let service = SupabaseAuthService(session: session)

        do {
            _ = try await service.signInAnonymously()
            XCTFail("Expected signInAnonymously to throw on a non-2xx response")
        } catch {
            // expected
        }
    }

    func testSignInAnonymouslyThrowsWhenAnonymousSignInsAreDisabled() async {
        // Supabase returns 422 when enable_anonymous_sign_ins is off project-side —
        // exactly the config.toml-vs-live-dashboard ambiguity found in this repo.
        let session = mockedSession(statusCode: 422, json: ["error_code": "anonymous_provider_disabled"])
        let service = SupabaseAuthService(session: session)

        do {
            _ = try await service.signInAnonymously()
            XCTFail("Expected signInAnonymously to throw when the provider is disabled")
        } catch {
            // expected
        }
    }

    func testRefreshSessionDecodesNewTokens() async throws {
        let session = mockedSession(statusCode: 200, json: [
            "access_token": "refreshed-access-token",
            "refresh_token": "refreshed-refresh-token",
            "expires_in": 3600,
            "user": ["id": "abc-123", "is_anonymous": true]
        ])
        let service = SupabaseAuthService(session: session)

        let result = try await service.refreshSession(refreshToken: "old-refresh-token")

        XCTAssertEqual(result.accessToken, "refreshed-access-token")
        XCTAssertEqual(result.refreshToken, "refreshed-refresh-token")
    }

    func testRefreshSessionThrowsOnExpiredRefreshToken() async {
        let session = mockedSession(statusCode: 401, json: ["error_code": "refresh_token_not_found"])
        let service = SupabaseAuthService(session: session)

        do {
            _ = try await service.refreshSession(refreshToken: "stale-token")
            XCTFail("Expected refreshSession to throw when the refresh token is no longer valid")
        } catch {
            // expected — caller falls back to a fresh anonymous sign-in
        }
    }
}

private final class MockAuthURLProtocol: URLProtocol {
    static var responseStatusCode = 200
    static var responseBody = Data()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.responseStatusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseBody)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
