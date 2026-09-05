import Foundation
import Testing
@testable import StressMonitor

/// Pins the Health Coach chat contract (Task 6):
/// - streamed content events accumulate into ONE assistant bubble, and the
///   terminal metadata adopts credits before `.done` stops streaming
/// - `send` appends the user message before the stream starts (test seam)
/// - a failing stream (402 from the URLProtocol stub) surfaces the typed
///   error text and removes the empty assistant placeholder bubble
/// - `startNewConversation` resets the conversation, credits, and error
/// - a mid-stream `New` (reset) drops in-flight events, never adopts the
///   stale session id, and never traps on the reset list
/// - a generic (non-API) stream failure behaves like the typed failure path
/// - `streamAgentChat` maps HTTP status to `AgentChatAPIError` (401/402/other)
///   and replays the SSE line contract (`/chat`-identical) into events,
///   returning the first-seen session id
@MainActor
struct AgentChatViewModelTests {

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

    // MARK: - View model (handle seam)

    @Test("streamed events accumulate into one assistant message with metadata")
    func streamAccumulates() {
        let vm = AgentChatViewModel()
        vm.handle(.content("Hel"))
        vm.handle(.content("lo"))
        vm.handle(.metadata(
            UUID(uuidString: "00000000-0000-0000-0000-000000000001"), 41, "gemini-3-flash"))
        vm.handle(.done)

        #expect(vm.messages.map(\.role) == ["assistant"])
        #expect(vm.messages.first?.text == "Hello")
        #expect(vm.creditsRemaining == 41)
        #expect(vm.isStreaming == false)
    }

    @Test("send appends the user message before streaming starts")
    func userMessageFirst() async {
        let vm = AgentChatViewModel()
        await vm.sendForTesting("hi", stream: { _ in })
        #expect(vm.messages.first?.role == "user")
        #expect(vm.messages.first?.text == "hi")
    }

    @Test("failing stream surfaces the error and drops the empty assistant bubble")
    func failingStreamRemovesEmptyAssistantBubble() async {
        let vm = AgentChatViewModel(client: makeClient(statusCode: 402, body: nil))
        await vm.send("hello")

        #expect(vm.errorText == AgentChatAPIError.insufficientCredits.errorDescription)
        #expect(vm.messages.map(\.role) == ["user"])
        #expect(vm.messages.first?.text == "hello")
        #expect(vm.isStreaming == false)
    }

    @Test("startNewConversation clears messages and error but keeps account credits")
    func startNewConversationResetsState() {
        let vm = AgentChatViewModel()
        vm.handle(.content("partial"))
        vm.handle(.metadata(nil, 12, nil))
        vm.errorText = "Coach chat failed. Try again."

        vm.startNewConversation()

        #expect(vm.messages.isEmpty)
        // Credits are the account's display state from the last metadata —
        // a new conversation must not pretend the balance vanished.
        #expect(vm.creditsRemaining == 12)
        #expect(vm.errorText == nil)
    }

    // MARK: - Mid-stream reset & generic failure (hardening)

    @Test("mid-stream New drops stale events and skips the stale session id")
    func midStreamNewDropsStaleEventsAndSessionAdoption() async {
        let vm = AgentChatViewModel() // real client unused — stream is injected
        let onEventBox = LockedBox<@Sendable (AgentChatEvent) -> Void>()
        let gate = Gate()
        let staleID = UUID()
        let turn = Task { await vm.send("hi", stream: { _, _, onEvent in
            onEventBox.append(onEvent)
            await gate.wait()
            return staleID
        }) }
        while onEventBox.items.isEmpty { await Task.yield() }

        vm.startNewConversation() // New mid-stream: reset while the stream is open
        onEventBox.items[0](.content("ghost")) // stale event from the old turn
        await Task.yield()
        await Task.yield()
        #expect(vm.messages.isEmpty) // dropped — no crash, no stray bubble

        gate.open() // let the old turn finish and return its session id
        await turn.value
        #expect(vm.sessionID == nil) // old conversation's id not adopted
        #expect(vm.isStreaming == false)
    }

    @Test("generic stream error surfaces fallback text and drops the empty bubble")
    func genericErrorRemovesEmptyAssistantBubble() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [FailingURLProtocol.self]
        let vm = AgentChatViewModel(client: StressAPIClient(
            authService: MockAuthService(token: "fake-token"),
            baseURL: URL(string: "https://api.test")!,
            session: URLSession(configuration: config)))
        await vm.send("hello")

        // A transport URLError is not an AgentChatAPIError — the generic
        // catch must behave like the typed one: fallback text, placeholder
        // removed, only the user message left.
        #expect(vm.errorText == "Coach chat failed. Try again.")
        #expect(vm.messages.map(\.role) == ["user"])
        #expect(vm.messages.first?.text == "hello")
        #expect(vm.isStreaming == false)
    }

    @Test("stale assistant id drops content instead of crashing")
    func staleAssistantIDDropsContent() {
        let vm = AgentChatViewModel()
        vm.handle(.content("live"))
        vm.handle(.content("ghost"), assistantID: UUID()) // id from a removed turn

        #expect(vm.messages.count == 1)
        #expect(vm.messages[0].text == "live")
    }

    // MARK: - streamAgentChat (POST /agent/chat)

    @Test("streamAgentChat replays the SSE contract and returns the first session id")
    func streamAgentChatReplaysSSEContract() async throws {
        let metadata: [String: Any] = [
            "type": "metadata",
            "session_id": "00000000-0000-0000-0000-000000000001",
            "credits_remaining": 41,
            "model_used": "gemini-3-flash",
        ]
        let metadataLine = "data: " + String(
            data: try JSONSerialization.data(withJSONObject: metadata), encoding: .utf8)!
        let sse = """
            data: {"choices":[{"delta":{"content":"Hel"}}]}

            data: {"choices":[{"delta":{"content":"lo"}}]}

            \(metadataLine)

            data: [DONE]

            """
        let collector = EventCollector()
        let client = makeClient(statusCode: 200, body: Data(sse.utf8))

        let session = try await client.streamAgentChat(
            sessionID: nil, message: "hi", onEvent: { collector.append($0) })

        #expect(session == UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        #expect(collector.all.count == 4)
        #expect(collector.all[0] == .content("Hel"))
        #expect(collector.all[1] == .content("lo"))
        #expect(collector.all[2] == .metadata(
            UUID(uuidString: "00000000-0000-0000-0000-000000000001"), 41, "gemini-3-flash"))
        #expect(collector.all[3] == .done)
    }

    @Test("streamAgentChat maps 402 to insufficientCredits")
    func streamAgentChatMaps402ToInsufficientCredits() async {
        let client = makeClient(statusCode: 402, body: nil)
        do {
            _ = try await client.streamAgentChat(sessionID: nil, message: "hi", onEvent: { _ in })
            Issue.record("Expected insufficientCredits, got success")
        } catch let error as AgentChatAPIError {
            #expect(error == .insufficientCredits)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("streamAgentChat maps 401 to unauthorized")
    func streamAgentChatMaps401ToUnauthorized() async {
        let client = makeClient(statusCode: 401, body: nil)
        do {
            _ = try await client.streamAgentChat(sessionID: nil, message: "hi", onEvent: { _ in })
            Issue.record("Expected unauthorized, got success")
        } catch let error as AgentChatAPIError {
            #expect(error == .unauthorized)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}

/// Thread-safe sink for `onEvent` callbacks delivered from the streaming
/// loop — `@Sendable` closures may not mutate captured locals.
private final class EventCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [AgentChatEvent] = []

    func append(_ event: AgentChatEvent) {
        lock.lock()
        defer { lock.unlock() }
        events.append(event)
    }

    var all: [AgentChatEvent] {
        lock.lock()
        defer { lock.unlock() }
        return events
    }
}

/// Thread-safe box for values captured across `@Sendable` boundaries.
private final class LockedBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var _items: [T] = []

    var items: [T] {
        lock.lock(); defer { lock.unlock() }
        return _items
    }

    func append(_ item: T) {
        lock.lock(); defer { lock.unlock() }
        _items.append(item)
    }
}

/// One-shot gate: parks a fake stream mid-turn while the test mutates
/// conversation state on the main actor.
private final class Gate: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Never>?

    func wait() async {
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            lock.lock(); continuation = c; lock.unlock()
        }
    }

    func open() {
        lock.lock()
        let c = continuation
        continuation = nil
        lock.unlock()
        c?.resume()
    }
}

/// Fails every request with a transport error — drives the view model's
/// generic (non-`AgentChatAPIError`) catch path.
private final class FailingURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
    }

    override func stopLoading() {}
}
