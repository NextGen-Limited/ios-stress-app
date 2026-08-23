import Foundation
import Testing
@testable import StressMonitor

/// Pins the sessions API client contract (derived-SES-01/02):
/// - `fetchMessages(sessionId:)` GETs `/sessions/{id}/messages` with Bearer
///   auth and decodes the `{messages: [...]}` envelope; dates stay String
///   because Postgres timestamptz serializes with fractional seconds (Pitfall 1)
/// - 404 maps to `.notFound` (dangling-session recovery); 401 maps to
///   `.unauthorized`
/// - `createSession(title:stressContext:)` POSTs `{title, stress_context}` and
///   decodes the 201 row
/// - `listSessions(limit:offset:)` / `deleteSession(id:)` build their query
///   URLs via URLComponents — the `?` must never be percent-encoded
///   (`appendingPathComponent` encodes it, which the backend would read as a
///   literal path segment)
@MainActor
struct StressAPIClientSessionsTests {

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

    // MARK: - fetchMessages (GET /sessions/{id}/messages)

    @Test("fetchMessages decodes the messages envelope from the exact session URL with a Bearer header")
    func fetchMessagesDecodesEnvelopeFromExactURL() async throws {
        let sessionId = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
        // Fixtures carry Postgres fractional-second timestamptz values and an
        // extra backend-only key (`stress_data_snapshot`) — decoding must keep
        // dates as String and ignore unknown keys.
        let fixture = """
        {"messages":[{"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","session_id":"12345678-1234-1234-1234-123456789012","role":"user","content":"Why is my HRV low?","tokens_used":12,"stress_data_snapshot":null,"created_at":"2026-08-23T07:39:53.953Z"},{"id":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","session_id":"12345678-1234-1234-1234-123456789012","role":"assistant","content":"Your HRV dip likely reflects last night's short sleep.","tokens_used":48,"stress_data_snapshot":null,"created_at":"2026-08-23T07:40:01.123Z"}]}
        """
        let client = makeClient(statusCode: 200, body: Data(fixture.utf8))

        let messages = try await client.fetchMessages(sessionId: sessionId)

        #expect(messages.count == 2)
        #expect(messages[0].id == UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"))
        #expect(messages[0].sessionId == sessionId)
        #expect(messages[0].role == .user)
        #expect(messages[0].content == "Why is my HRV low?")
        #expect(messages[0].tokensUsed == 12)
        #expect(messages[0].createdAt == "2026-08-23T07:39:53.953Z")
        #expect(messages[1].role == .assistant)
        #expect(messages[1].tokensUsed == 48)
        #expect(messages[1].createdAt == "2026-08-23T07:40:01.123Z")

        let request = try #require(RequestCaptureURLProtocol.lastRequest)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString == "https://api.test/sessions/\(sessionId.uuidString)/messages")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer fake-token")
    }

    @Test("fetchMessages maps 404 to the notFound error case")
    func fetchMessagesMaps404ToNotFound() async throws {
        let client = makeClient(statusCode: 404, body: Data(#"{"error":"Session not found"}"#.utf8))

        await #expect(throws: SessionsAPIError.notFound) {
            try await client.fetchMessages(sessionId: UUID())
        }
    }

    @Test("fetchMessages maps 401 to the unauthorized error case")
    func fetchMessagesMaps401ToUnauthorized() async throws {
        let client = makeClient(statusCode: 401, body: Data("{}".utf8))

        await #expect(throws: SessionsAPIError.unauthorized) {
            try await client.fetchMessages(sessionId: UUID())
        }
    }

    // MARK: - createSession (POST /sessions)

    @Test("createSession posts the title and stress context, and decodes the 201 row")
    func createSessionPostsTitleAndDecodes201Row() async throws {
        // Row is `select *` — extra keys (user_id, model_used, …) must be ignored.
        let fixture = """
        {"id":"12345678-1234-1234-1234-123456789012","user_id":"uid-1","title":"Why is my HRV low?","stress_context":{"language":"en"},"model_used":null,"is_archived":false,"created_at":"2026-08-23T07:39:53.953Z","updated_at":"2026-08-23T07:39:53.953Z"}
        """
        let client = makeClient(statusCode: 201, body: Data(fixture.utf8))
        let payload = StressContextPayload.build(stressResult: nil, baseline: nil)

        let session = try await client.createSession(title: "Why is my HRV low?", stressContext: payload)

        #expect(session.id == UUID(uuidString: "12345678-1234-1234-1234-123456789012"))
        #expect(session.title == "Why is my HRV low?")
        #expect(session.createdAt == "2026-08-23T07:39:53.953Z")
        #expect(session.updatedAt == "2026-08-23T07:39:53.953Z")

        let request = try #require(RequestCaptureURLProtocol.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://api.test/sessions")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer fake-token")

        let json = try #require(
            JSONSerialization.jsonObject(with: body(of: request)) as? [String: Any]
        )
        #expect(json["title"] as? String == "Why is my HRV low?")
        let context = try #require(json["stress_context"] as? [String: Any])
        #expect(context["language"] as? String == "en")
        #expect(context["coaching_style"] as? String == "supportive")
    }

    // MARK: - listSessions (GET /sessions?limit=&offset=)

    @Test("listSessions GETs the exact query URL without percent-encoding the question mark")
    func listSessionsBuildsExactQueryURL() async throws {
        let fixture = """
        {"sessions":[{"id":"12345678-1234-1234-1234-123456789012","user_id":"uid-1","title":"Session one","stress_context":{},"model_used":null,"is_archived":false,"created_at":"2026-08-22T07:39:53.953Z","updated_at":"2026-08-23T07:39:53.953Z"}],"limit":20,"offset":0}
        """
        let client = makeClient(statusCode: 200, body: Data(fixture.utf8))

        let sessions = try await client.listSessions()

        #expect(sessions.count == 1)
        #expect(sessions[0].id == UUID(uuidString: "12345678-1234-1234-1234-123456789012"))
        #expect(sessions[0].title == "Session one")
        #expect(sessions[0].createdAt == "2026-08-22T07:39:53.953Z")

        let request = try #require(RequestCaptureURLProtocol.lastRequest)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString == "https://api.test/sessions?limit=20&offset=0")
        #expect(request.url?.absoluteString.contains("%3F") == false)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer fake-token")
    }

    // MARK: - deleteSession (DELETE /sessions?id=)

    @Test("deleteSession DELETEs the exact query URL and makes no verification round-trip")
    func deleteSessionBuildsExactQueryURLWithoutFollowUp() async throws {
        let id = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
        let client = makeClient(statusCode: 200, body: Data(#"{"success":true}"#.utf8))

        try await client.deleteSession(id: id)

        let request = try #require(RequestCaptureURLProtocol.lastRequest)
        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.absoluteString == "https://api.test/sessions?id=\(id.uuidString)")
        #expect(request.url?.absoluteString.contains("%3F") == false)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer fake-token")
        // `{success: true}` is terminal for the backend route — verifying the
        // deletion with a follow-up GET would be an over-engineered round-trip.
        #expect(RequestCaptureURLProtocol.capturedRequests.count == 1)
    }
}
