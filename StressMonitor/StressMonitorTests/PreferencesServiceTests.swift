import Foundation
import Testing
@testable import StressMonitor

/// Pins the `PreferencesService` semantics (derived-PREF-01):
/// - defaults before any seed match the backend migration ("en"/"supportive")
/// - seed-once: two `seedIfNeeded()` calls issue exactly one GET (the
///   `hasSeeded` guard) and map the server pair into state
/// - a failing seed stays silent (best-effort hydration) and leaves the seed
///   open for a retry by a later surface
/// - `update(language:)` optimistically sets state, PUTs a single field, and
///   reverts to the prior value + surfaces `errorMessage` on failure
@MainActor
struct PreferencesServiceTests {

    private static let seededFixture = """
        {"user_id":"00000000-0000-0000-0000-000000000001","language":"vi","coaching_style":"educational","display_name":"Ripple User","theme":"system"}
        """

    private func makeService(statusCode: Int, body: Data?) -> PreferencesService {
        RequestCaptureURLProtocol.lastRequest = nil
        RequestCaptureURLProtocol.capturedRequests = []
        RequestCaptureURLProtocol.statusCode = statusCode
        RequestCaptureURLProtocol.statusCodeSequence = []
        RequestCaptureURLProtocol.responseByPath = nil
        RequestCaptureURLProtocol.responseBody = body
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [RequestCaptureURLProtocol.self]
        return PreferencesService(
            apiClient: StressAPIClient(
                authService: MockAuthService(token: "fake-token"),
                baseURL: URL(string: "https://api.test")!,
                session: URLSession(configuration: config)
            )
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

    private var capturedPutRequests: [URLRequest] {
        RequestCaptureURLProtocol.capturedRequests.filter { $0.httpMethod == "PUT" }
    }

    /// `async let` guarantees no child-task start order — on CI runners the
    /// second update occasionally reached the serialized chain first and
    /// consumed the 500, flipping the scenario. Gate on the first PUT
    /// reaching the wire before dispatching the second update; the updates
    /// still overlap (PUT #1 is mid-flight, unsettled), so the
    /// serialization contract stays exercised deterministically.
    private static func waitUntilCapturedPutCount(_ count: Int) async {
        let deadline = Date().addingTimeInterval(5)
        while RequestCaptureURLProtocol.capturedRequests.filter({ $0.httpMethod == "PUT" }).count < count,
              Date() < deadline {
            await Task.yield()
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
    }

    @Test("defaults before any seed match the backend migration defaults")
    func defaultsMatchBackendMigration() {
        let service = makeService(statusCode: 200, body: Data(Self.seededFixture.utf8))

        #expect(service.language == "en")
        #expect(service.coachingStyle == "supportive")
        #expect(service.hasSeeded == false)
    }

    @Test("seedIfNeeded issues exactly one GET across two calls and maps the server pair")
    func seedIfNeededSeedsOnce() async throws {
        let service = makeService(statusCode: 200, body: Data(Self.seededFixture.utf8))

        await service.seedIfNeeded()
        await service.seedIfNeeded()

        #expect(service.language == "vi")
        #expect(service.coachingStyle == "educational")
        #expect(service.hasSeeded == true)

        let gets = RequestCaptureURLProtocol.capturedRequests.filter { $0.httpMethod == "GET" }
        #expect(gets.count == 1, "The hasSeeded guard must prevent a second GET on repeated surfaces.")
        #expect(gets.first?.url?.absoluteString == "https://api.test/preferences")
    }

    @Test("a failing seed stays silent, keeps defaults, and retries on a later surface")
    func failingSeedStaysSilentAndRetries() async throws {
        let service = makeService(statusCode: 500, body: Data("{}".utf8))

        await service.seedIfNeeded()

        #expect(service.language == "en")
        #expect(service.coachingStyle == "supportive")
        #expect(service.hasSeeded == false)
        #expect(service.errorMessage == nil, "Seeding is best-effort background hydration — never a user-facing error.")

        // The server recovers; a later surface's seedIfNeeded() must retry.
        RequestCaptureURLProtocol.statusCode = 200
        RequestCaptureURLProtocol.responseBody = Data(Self.seededFixture.utf8)
        await service.seedIfNeeded()

        #expect(service.hasSeeded == true)
        #expect(service.language == "vi")
        #expect(service.coachingStyle == "educational")
    }

    @Test("update(language:) optimistically sets state, PUTs one field, and reverts on failure")
    func updateLanguageRevertsOnFailure() async throws {
        let service = makeService(statusCode: 500, body: Data("{}".utf8))

        await service.update(language: "vi")

        #expect(service.language == "en", "A failed PUT must revert the optimistic value.")
        #expect(service.errorMessage != nil, "The revert must be user-visible (T-3-08).")

        let puts = capturedPutRequests
        #expect(puts.count == 1)
        #expect(puts.first?.url?.absoluteString == "https://api.test/preferences")
        let json = try #require(
            JSONSerialization.jsonObject(with: body(of: puts[0])) as? [String: Any]
        )
        #expect(json["language"] as? String == "vi")
        #expect(json.count == 1, "The update must PUT exactly one field — never a save-all.")
    }

    @Test("update(coachingStyle:) keeps the optimistic value and clears the error on success")
    func updateCoachingStyleSucceeds() async throws {
        let service = makeService(statusCode: 200, body: Data(Self.seededFixture.utf8))

        await service.update(coachingStyle: "direct")

        #expect(service.coachingStyle == "direct")
        #expect(service.errorMessage == nil)

        let puts = capturedPutRequests
        #expect(puts.count == 1)
        let json = try #require(
            JSONSerialization.jsonObject(with: body(of: puts[0])) as? [String: Any]
        )
        #expect(json["coaching_style"] as? String == "direct")
        #expect(json.count == 1)
    }

    @Test("overlapping updates serialize: a failed first PUT never reverts past a newer value")
    func overlappingUpdatesSerializeSoStaleRevertsCannotClobber() async throws {
        // PUT #1 (vi) fails, PUT #2 (fr) succeeds — dispatched in tap order.
        RequestCaptureURLProtocol.statusCodeSequence = [500, 200]
        let service = makeService(statusCode: 200, body: Data(Self.seededFixture.utf8))

        async let first: Void = service.update(language: "vi")
        await Self.waitUntilCapturedPutCount(1)
        async let second: Void = service.update(language: "fr")
        _ = await (first, second)

        // Both updates settled. The server kept "fr" (PUT #2 succeeded) —
        // the local value must match it. Unserialized, the first failure
        // reverts to the value captured before either tap ("en") and local
        // state silently contradicts the server row (WR-04).
        #expect(service.language == "fr")
        #expect(service.errorMessage == nil)

        let puts = capturedPutRequests
        #expect(puts.count == 2)
        let firstPayload = try #require(
            JSONSerialization.jsonObject(with: body(of: puts[0])) as? [String: Any]
        )
        #expect(firstPayload["language"] as? String == "vi")
        let secondPayload = try #require(
            JSONSerialization.jsonObject(with: body(of: puts[1])) as? [String: Any]
        )
        #expect(secondPayload["language"] as? String == "fr")
    }
}
