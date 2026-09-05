import Foundation
import Testing
@testable import StressMonitor

/// Pins the health API client contract (Task 1):
/// - `DailySummaryPayload` encodes the exact snake_case backend keys
/// - `ServerStressScore` decodes the spec's score object
/// - `setHealthConsent` PUTs `{granted}` and returns the server's consent
///   state from the `ConsentStatus` row
/// - `uploadDailySummary` POSTs the payload and decodes the freshly computed
///   `ServerStressScore`
/// - `fetchStressScores` builds the exact query URL via URLComponents — the
///   `?` must never be percent-encoded (`appendingPathComponent` encodes it,
///   which the backend would read as a literal path segment) — and decodes
///   the `{scores: [...]}` envelope
/// - Error mapping mirrors `SessionsAPIError`: 401 → `.unauthorized`;
///   403 with `CONSENT_REQUIRED` → `.consentRequired`; other non-2xx →
///   `.server(statusCode:)`
@MainActor
struct StressAPIClientHealthTests {

    private func makeClient(statusCode: Int, body: Data?) -> StressAPIClient {
        RequestCaptureURLProtocol.lastRequest = nil
        RequestCaptureURLProtocol.statusCode = statusCode
        RequestCaptureURLProtocol.responseBody = body
        RequestCaptureURLProtocol.responseByPath = nil
        RequestCaptureURLProtocol.capturedRequests = []
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

    // MARK: - Models (encode/decode)

    @Test("DailySummaryPayload encodes exact snake_case keys")
    func payloadEncoding() throws {
        let payload = DailySummaryPayload(
            localDate: "2026-09-04",
            timezone: "Asia/Ho_Chi_Minh",
            hrvSdnnMs: 48.2,
            heartRateAvgBpm: 72.4,
            restingHeartRateBpm: 61,
            sampleCounts: .init(hrv: 4, heartRate: 163, restingHeartRate: 1),
            source: "healthkit"
        )
        let json = try JSONEncoder().encode(payload)
        let dict = try JSONSerialization.jsonObject(with: json) as! [String: Any]
        #expect(dict["local_date"] as? String == "2026-09-04")
        #expect(dict["hrv_sdnn_ms"] as? Double == 48.2)
        #expect(dict["resting_heart_rate_bpm"] as? Double == 61)
        let counts = dict["sample_counts"] as! [String: Any]
        #expect(counts["heart_rate"] as? Int == 163)
        #expect(dict["source"] as? String == "healthkit")
    }

    @Test("ServerStressScore decodes the spec's score object")
    func scoreDecoding() throws {
        let fixture = """
        {"local_date":"2026-09-04","score":63,"level":"moderate","confidence":0.82,
         "baseline_version":"personal-14d-v1","formula_version":"stress-score-v1",
         "factors":["HRV below personal baseline"],"warnings":[]}
        """.data(using: .utf8)!
        let score = try JSONDecoder().decode(ServerStressScore.self, from: fixture)
        #expect(score.score == 63)
        #expect(score.level == "moderate")
        #expect(score.factors == ["HRV below personal baseline"])
    }

    // MARK: - setHealthConsent (PUT /health/consent)

    @Test("setHealthConsent PUTs the granted flag and returns the server's consent state")
    func setHealthConsentPutsFlagAndReturnsServerState() async throws {
        let client = makeClient(
            statusCode: 200,
            body: Data(#"{"scope":"health_ingest","granted":true}"#.utf8)
        )

        let granted = try await client.setHealthConsent(true)

        #expect(granted == true)
        let request = try #require(RequestCaptureURLProtocol.lastRequest)
        #expect(request.httpMethod == "PUT")
        #expect(request.url?.absoluteString == "https://api.test/health/consent")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer fake-token")
        let sent = try JSONSerialization.jsonObject(with: body(of: request)) as! [String: Any]
        #expect(sent["granted"] as? Bool == true)
    }

    // MARK: - uploadDailySummary (POST /health/daily-summary)

    @Test("uploadDailySummary posts the payload and decodes the server score")
    func uploadDailySummaryPostsPayloadAndDecodesScore() async throws {
        let response = """
        {"local_date":"2026-09-04","score":63,"level":"moderate","confidence":0.82,
         "baseline_version":"personal-14d-v1","formula_version":"stress-score-v1",
         "factors":["HRV below personal baseline"],"warnings":[]}
        """
        let client = makeClient(statusCode: 200, body: Data(response.utf8))
        let payload = DailySummaryPayload(
            localDate: "2026-09-04",
            timezone: "Asia/Ho_Chi_Minh",
            hrvSdnnMs: 48.2,
            heartRateAvgBpm: 72.4,
            restingHeartRateBpm: 61,
            sampleCounts: .init(hrv: 4, heartRate: 163, restingHeartRate: 1),
            source: "healthkit"
        )

        let score = try await client.uploadDailySummary(payload)

        #expect(score.score == 63)
        let request = try #require(RequestCaptureURLProtocol.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://api.test/health/daily-summary")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer fake-token")
        let sent = try JSONSerialization.jsonObject(with: body(of: request)) as! [String: Any]
        #expect(sent["local_date"] as? String == "2026-09-04")
        let counts = sent["sample_counts"] as! [String: Any]
        #expect(counts["resting_heart_rate"] as? Int == 1)
    }

    // MARK: - fetchStressScores (GET /stress/scores?from=&to=)

    @Test("fetchStressScores GETs the exact query URL and decodes the scores envelope")
    func fetchStressScoresBuildsExactQueryURL() async throws {
        let fixture = """
        {"scores":[
          {"local_date":"2026-09-04","score":63,"level":"moderate","confidence":0.82,
           "baseline_version":"personal-14d-v1","formula_version":"stress-score-v1",
           "factors":["HRV below personal baseline"],"warnings":[]},
          {"local_date":"2026-09-03","score":41,"level":"low","confidence":0.74,
           "baseline_version":"personal-14d-v1","formula_version":"stress-score-v1",
           "factors":[],"warnings":[]}
        ]}
        """
        let client = makeClient(statusCode: 200, body: Data(fixture.utf8))

        let scores = try await client.fetchStressScores(from: "2026-09-01", to: "2026-09-04")

        #expect(scores.count == 2)
        #expect(scores[0].localDate == "2026-09-04")
        #expect(scores[1].score == 41)
        let request = try #require(RequestCaptureURLProtocol.lastRequest)
        #expect(request.httpMethod == "GET")
        // The `?` must survive unencoded — `appendingPathComponent` would
        // percent-encode it into a literal path segment.
        #expect(request.url?.absoluteString == "https://api.test/stress/scores?from=2026-09-01&to=2026-09-04")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer fake-token")
    }

    @Test("fetchStressScores without filters GETs the plain scores URL")
    func fetchStressScoresWithoutFiltersOmitsQueryString() async throws {
        let client = makeClient(
            statusCode: 200,
            body: Data(#"{"scores":[]}"#.utf8)
        )

        let scores = try await client.fetchStressScores()

        #expect(scores.isEmpty)
        let request = try #require(RequestCaptureURLProtocol.lastRequest)
        #expect(request.url?.absoluteString == "https://api.test/stress/scores")
    }

    // MARK: - Error mapping

    @Test("health endpoints map 401 to the unauthorized error case")
    func healthMaps401ToUnauthorized() async throws {
        let client = makeClient(statusCode: 401, body: Data("{}".utf8))

        await #expect(throws: HealthAPIError.unauthorized) {
            try await client.setHealthConsent(true)
        }
    }

    @Test("403 with CONSENT_REQUIRED maps to the consentRequired error case")
    func healthMaps403ConsentRequiredToConsentRequired() async throws {
        let client = makeClient(
            statusCode: 403,
            body: Data(#"{"error":"CONSENT_REQUIRED"}"#.utf8)
        )

        await #expect(throws: HealthAPIError.consentRequired) {
            try await client.uploadDailySummary(DailySummaryPayload(
                localDate: "2026-09-04",
                timezone: "Asia/Ho_Chi_Minh",
                hrvSdnnMs: nil,
                heartRateAvgBpm: nil,
                restingHeartRateBpm: nil,
                sampleCounts: .init(hrv: 0, heartRate: 0, restingHeartRate: 0),
                source: "healthkit"
            ))
        }
    }

    @Test("403 without the consent marker maps to server(statusCode: 403)")
    func healthMaps403WithoutMarkerToServerError() async throws {
        let client = makeClient(statusCode: 403, body: Data(#"{"error":"Forbidden"}"#.utf8))

        await #expect(throws: HealthAPIError.server(statusCode: 403)) {
            try await client.fetchStressScores()
        }
    }

    @Test("other non-2xx statuses map to server(statusCode:)")
    func healthMapsUnexpectedStatusToServerError() async throws {
        let client = makeClient(statusCode: 500, body: Data("{}".utf8))

        await #expect(throws: HealthAPIError.server(statusCode: 500)) {
            try await client.setHealthConsent(true)
        }
    }
}
