import Foundation
import Testing
@testable import StressMonitor

/// Pins the GET/PUT /preferences client contract (derived-PREF-01):
/// - `getPreferences()` GETs the full backend row and decodes only the
///   chat-relevant pair (language, coaching_style) — the other five allowlisted
///   fields ride the same JSON but are deliberately ignored
/// - `updatePreferences(fields:)` PUTs exactly one JSON key (never a save-all:
///   the backend's ALLOWED_FIELDS filter drops everything else and 400s on an
///   empty update)
/// - 400 maps to `.noValidFields`, 401 to `.unauthorized`
@MainActor
struct StressAPIClientPreferencesTests {

    /// Full backend row (`select * from user_preferences`) carrying the five
    /// fields this app deliberately ignores alongside the synced pair.
    private static let preferencesFixture = """
        {"user_id":"00000000-0000-0000-0000-000000000001","language":"vi","coaching_style":"direct","display_name":"Ripple User","theme":"system","notification_enabled":true,"stress_alert_threshold":80,"custom_settings":{"tone":"warm"}}
        """

    private func makeClient(statusCode: Int, body: Data?) -> StressAPIClient {
        RequestCaptureURLProtocol.lastRequest = nil
        RequestCaptureURLProtocol.capturedRequests = []
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

    // MARK: - getPreferences (GET /preferences)

    @Test("getPreferences decodes the chat-relevant pair from GET preferences with a Bearer header")
    func getPreferencesDecodesPairWithBearerHeader() async throws {
        let client = makeClient(statusCode: 200, body: Data(Self.preferencesFixture.utf8))

        let preferences = try await client.getPreferences()

        #expect(preferences.language == "vi")
        #expect(preferences.coachingStyle == "direct")

        let request = try #require(RequestCaptureURLProtocol.lastRequest)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString == "https://api.test/preferences")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer fake-token")
    }

    // MARK: - updatePreferences (PUT /preferences — single field only)

    @Test("updatePreferences PUTs exactly one language key and decodes the returned row")
    func updatePreferencesPutsExactlyOneLanguageKey() async throws {
        let client = makeClient(statusCode: 200, body: Data(Self.preferencesFixture.utf8))

        let preferences = try await client.updatePreferences(fields: ["language": "vi"])

        #expect(preferences.language == "vi")

        let request = try #require(RequestCaptureURLProtocol.lastRequest)
        #expect(request.httpMethod == "PUT")
        #expect(request.url?.absoluteString == "https://api.test/preferences")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer fake-token")

        let json = try #require(
            JSONSerialization.jsonObject(with: body(of: request)) as? [String: Any]
        )
        #expect(json["language"] as? String == "vi")
        #expect(json.count == 1, "A preferences PUT carries exactly one allowlisted field — never the full row (T-3-05).")
    }

    @Test("updatePreferences PUTs the coaching_style key alone")
    func updatePreferencesPutsCoachingStyleKeyAlone() async throws {
        let client = makeClient(statusCode: 200, body: Data(Self.preferencesFixture.utf8))

        _ = try await client.updatePreferences(fields: ["coaching_style": "educational"])

        let request = try #require(RequestCaptureURLProtocol.lastRequest)
        let json = try #require(
            JSONSerialization.jsonObject(with: body(of: request)) as? [String: Any]
        )
        #expect(json["coaching_style"] as? String == "educational")
        #expect(json.count == 1)
    }

    @Test("updatePreferences maps 400 to the no-valid-fields error case")
    func updatePreferencesMaps400ToNoValidFields() async throws {
        let client = makeClient(
            statusCode: 400,
            body: Data(#"{"error":"No valid fields to update"}"#.utf8)
        )

        await #expect(throws: PreferencesAPIError.noValidFields) {
            try await client.updatePreferences(fields: [:])
        }
    }

    @Test("updatePreferences maps 401 to the unauthorized error case")
    func updatePreferencesMaps401ToUnauthorized() async throws {
        let client = makeClient(statusCode: 401, body: Data("{}".utf8))

        await #expect(throws: PreferencesAPIError.unauthorized) {
            try await client.updatePreferences(fields: ["language": "vi"])
        }
    }

    @Test("getPreferences maps 401 to the unauthorized error case")
    func getPreferencesMaps401ToUnauthorized() async throws {
        let client = makeClient(statusCode: 401, body: Data("{}".utf8))

        await #expect(throws: PreferencesAPIError.unauthorized) {
            try await client.getPreferences()
        }
    }
}
