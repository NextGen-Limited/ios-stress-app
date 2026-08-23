import Foundation
import Testing
@testable import StressMonitor

/// Pins the derived-SES-01/02 tracer path end-to-end at unit level:
/// - the first send of a new conversation creates a titled session BEFORE
///   `/chat` carries its id, so the backend can never auto-create an untitled
///   twin session (Pitfall 5)
/// - a failed session creation is fail-soft: `/chat` still sends, minus
///   `session_id`
/// - the created id survives service reconstruction (UserDefaults write-through)
/// - reopening restores the server history (server order, `isSynced`, no
///   system rows)
/// - a 404 restore clears the stored id and renders an empty chat (Pitfall 3)
/// - a restore landing after the user already sent a message never clobbers
///   the live conversation (Pitfall 4)
@MainActor
struct ChatHistoryRestoreTests {

    private static let sessionIdDefaultsKey = "stressChatSessionId"

    // MARK: - Helpers

    private func makeStubbedClient(
        responseByPath: [String: (statusCode: Int, body: Data?)]
    ) -> StressAPIClient {
        RequestCaptureURLProtocol.lastRequest = nil
        RequestCaptureURLProtocol.statusCode = 200
        RequestCaptureURLProtocol.responseBody = nil
        RequestCaptureURLProtocol.responseByPath = responseByPath
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

    private func jsonBody(of request: URLRequest) throws -> [String: Any] {
        try #require(
            JSONSerialization.jsonObject(with: body(of: request)) as? [String: Any]
        )
    }

    /// SSE stream shaped like the backend's `/chat` response: one content
    /// token event, a terminal metadata event, and `[DONE]` (SSEParserTests
    /// fixture shape).
    private func chatSSEBody(sessionId: UUID?) -> Data {
        var lines = [
            #"data: {"choices":[{"delta":{"content":"Hello"}}]}"#,
        ]
        if let sessionId {
            lines.append(#"data: {"type":"metadata","session_id":"\#(sessionId.uuidString)","credits_remaining":42,"model_used":"test-model"}"#)
        }
        lines.append("data: [DONE]")
        return Data(lines.joined(separator: "\n").utf8)
    }

    private func sessionRowFixture(id: UUID) -> Data {
        Data("""
        {"id":"\(id.uuidString)","user_id":"uid-1","title":"Why is my HRV low?","stress_context":{},"model_used":null,"is_archived":false,"created_at":"2026-08-23T07:39:53.953Z","updated_at":"2026-08-23T07:39:53.953Z"}
        """.utf8)
    }

    @discardableResult
    private func consume(_ stream: AsyncThrowingStream<String, Error>) async throws -> [String] {
        var tokens: [String] = []
        for try await token in stream { tokens.append(token) }
        return tokens
    }

    // MARK: - Titled-session creation ordering (derived-SES-02, Pitfall 5)

    @Test("first send of a new conversation creates a titled session before /chat carries its id")
    func firstSendCreatesTitledSessionBeforeChat() async throws {
        UserDefaults.standard.removeObject(forKey: Self.sessionIdDefaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: Self.sessionIdDefaultsKey) }

        let createdId = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
        let client = makeStubbedClient(responseByPath: [
            "/sessions": (201, sessionRowFixture(id: createdId)),
            "/chat": (200, chatSSEBody(sessionId: createdId)),
        ])
        let service = StressLLMService(stressAPIClient: client)

        // Newlines and repeated spaces must collapse; the title truncates to
        // 50 characters with an ellipsis (this message is 51 chars collapsed).
        let longMessage = "Why is my HRV low\nafter a rough   night of fragmented sleep and too much screen time before bed?"
        let stream = try await service.send(
            messages: [ChatMessage(role: .user, content: longMessage)],
            systemPrompt: "",
            stressContext: nil
        )
        let tokens = try await consume(stream)
        #expect(tokens == ["Hello"])

        let requests = RequestCaptureURLProtocol.capturedRequests
        #expect(requests.count == 2)
        #expect(requests[0].httpMethod == "POST")
        #expect(requests[0].url?.path == "/sessions")
        #expect(requests[1].httpMethod == "POST")
        #expect(requests[1].url?.path == "/chat")

        let createJSON = try jsonBody(of: requests[0])
        #expect(createJSON["title"] as? String == "Why is my HRV low after a rough night of fragmente…")

        let chatJSON = try jsonBody(of: requests[1])
        #expect(chatJSON["session_id"] as? String == createdId.uuidString)
    }

    @Test("failed session creation is fail-soft: /chat still sends without session_id")
    func failedSessionCreationFailsSoft() async throws {
        UserDefaults.standard.removeObject(forKey: Self.sessionIdDefaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: Self.sessionIdDefaultsKey) }

        let client = makeStubbedClient(responseByPath: [
            "/sessions": (500, Data("{}".utf8)),
            "/chat": (200, chatSSEBody(sessionId: nil)),
        ])
        let service = StressLLMService(stressAPIClient: client)

        let stream = try await service.send(
            messages: [ChatMessage(role: .user, content: "hi")],
            systemPrompt: "",
            stressContext: nil
        )
        let tokens = try await consume(stream)
        #expect(tokens == ["Hello"])

        let requests = RequestCaptureURLProtocol.capturedRequests
        #expect(requests.count == 2)
        #expect(requests[0].url?.path == "/sessions")
        #expect(requests[1].url?.path == "/chat")

        let chatJSON = try jsonBody(of: requests[1])
        #expect(chatJSON["session_id"] == nil)
    }

    @Test("created session id persists and survives service reconstruction")
    func createdSessionIdPersistsAcrossServiceReconstruction() async throws {
        UserDefaults.standard.removeObject(forKey: Self.sessionIdDefaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: Self.sessionIdDefaultsKey) }

        let createdId = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
        let client = makeStubbedClient(responseByPath: [
            "/sessions": (201, sessionRowFixture(id: createdId)),
            "/chat": (200, chatSSEBody(sessionId: createdId)),
        ])
        let service = StressLLMService(stressAPIClient: client)

        let stream = try await service.send(
            messages: [ChatMessage(role: .user, content: "hello")],
            systemPrompt: "",
            stressContext: nil
        )
        _ = try await consume(stream)

        #expect(UserDefaults.standard.string(forKey: Self.sessionIdDefaultsKey) == createdId.uuidString)

        let reconstructed = StressLLMService(stressAPIClient: client)
        #expect(reconstructed.currentSessionId == createdId)
    }

    // MARK: - History restore (derived-SES-01)

    private func messagesEnvelope(sessionId: UUID) -> Data {
        Data("""
        {"messages":[
        {"id":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","session_id":"\(sessionId.uuidString)","role":"system","content":"internal system prompt row","tokens_used":null,"created_at":"2026-08-23T07:30:00.000Z"},
        {"id":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","session_id":"\(sessionId.uuidString)","role":"user","content":"Why is my HRV low?","tokens_used":12,"created_at":"2026-08-23T07:39:53.953Z"},
        {"id":"cccccccc-cccc-cccc-cccc-cccccccccccc","session_id":"\(sessionId.uuidString)","role":"assistant","content":"Your HRV dip likely reflects short sleep.","tokens_used":48,"created_at":"2026-08-23T07:40:01.123Z"}
        ]}
        """.utf8)
    }

    @Test("restoreHistory renders server history in order, synced, without system rows")
    func restoreHistoryRendersServerHistory() async throws {
        let sessionId = UUID()
        UserDefaults.standard.set(sessionId.uuidString, forKey: Self.sessionIdDefaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: Self.sessionIdDefaultsKey) }

        let client = makeStubbedClient(responseByPath: [
            "/sessions/\(sessionId.uuidString)/messages": (200, messagesEnvelope(sessionId: sessionId)),
        ])
        let service = StressLLMService(stressAPIClient: client)
        let viewModel = ChatViewModel(stressResult: nil, baseline: nil, llmService: service)
        viewModel.apiClient = client

        await viewModel.restoreHistory()

        #expect(viewModel.messages.count == 2)
        #expect(viewModel.messages[0].role == .user)
        #expect(viewModel.messages[0].content == "Why is my HRV low?")
        #expect(viewModel.messages[0].isSynced)
        #expect(viewModel.messages[0].remoteId == UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"))
        #expect(viewModel.messages[0].sessionId == sessionId)
        #expect(viewModel.messages[0].tokensUsed == 12)
        #expect(viewModel.messages[1].role == .assistant)
        #expect(viewModel.messages[1].content == "Your HRV dip likely reflects short sleep.")
        #expect(viewModel.messages[1].isSynced)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("404 restore clears the stored session id and leaves the chat empty")
    func restoreOn404ClearsStoredIdAndStaysEmpty() async throws {
        let sessionId = UUID()
        UserDefaults.standard.set(sessionId.uuidString, forKey: Self.sessionIdDefaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: Self.sessionIdDefaultsKey) }

        let client = makeStubbedClient(responseByPath: [
            "/sessions/\(sessionId.uuidString)/messages": (404, Data(#"{"error":"Session not found"}"#.utf8)),
        ])
        let service = StressLLMService(stressAPIClient: client)
        let viewModel = ChatViewModel(stressResult: nil, baseline: nil, llmService: service)
        viewModel.apiClient = client

        await viewModel.restoreHistory()

        #expect(viewModel.messages.isEmpty)
        #expect(viewModel.errorMessage == nil)
        #expect(UserDefaults.standard.string(forKey: Self.sessionIdDefaultsKey) == nil)
        #expect(service.currentSessionId == nil)
    }

    @Test("restore landing after a live message never clobbers the live conversation")
    func restoreDoesNotClobberLiveMessages() async throws {
        let sessionId = UUID()
        UserDefaults.standard.set(sessionId.uuidString, forKey: Self.sessionIdDefaultsKey)
        defer { UserDefaults.standard.removeObject(forKey: Self.sessionIdDefaultsKey) }

        // A stub that holds the messages response back long enough for the
        // test to append a live message while the fetch is in flight — pins
        // the post-await `messages.isEmpty` re-check, not just the entry guard.
        DelayedResponseURLProtocol.statusCode = 200
        DelayedResponseURLProtocol.responseBody = messagesEnvelope(sessionId: sessionId)
        DelayedResponseURLProtocol.delayMS = 200
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [DelayedResponseURLProtocol.self]
        let client = StressAPIClient(
            authService: MockAuthService(token: "fake-token"),
            baseURL: URL(string: "https://api.test")!,
            session: URLSession(configuration: config)
        )
        let service = StressLLMService(stressAPIClient: client)
        let viewModel = ChatViewModel(stressResult: nil, baseline: nil, llmService: service)
        viewModel.apiClient = client

        let restoreTask = Task { await viewModel.restoreHistory() }
        // Let the restore pass its entry guard and reach the in-flight fetch.
        try await Task.sleep(for: .milliseconds(40))
        viewModel.messages.append(ChatMessage(role: .user, content: "live message sent during restore"))
        await restoreTask.value

        #expect(viewModel.messages.count == 1)
        #expect(viewModel.messages.first?.content == "live message sent during restore")
        #expect(viewModel.messages.first?.isSynced == false)
    }
}

// MARK: - Delayed Response URLProtocol

/// Single-response `URLProtocol` double whose response is held back by a fixed
/// delay, so a test can act between a request's dispatch and its delivery.
/// Used only by the no-clobber restore test; the shared
/// `RequestCaptureURLProtocol` responds immediately.
final class DelayedResponseURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var statusCode: Int = 200
    nonisolated(unsafe) static var responseBody: Data?
    nonisolated(unsafe) static var delayMS: Int = 0

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let delay = Self.delayMS
        if delay > 0 {
            Thread.sleep(forTimeInterval: TimeInterval(delay) / 1000)
        }
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseBody ?? Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
