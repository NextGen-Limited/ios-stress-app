import Testing
import Foundation
@testable import StressMonitor

/// Pins the AUTH-03 streaming lifecycle so it cannot regress before Chat
/// re-enables in v1.1:
/// - mid-stream dismissal cancels the in-flight Task and preserves partial text
/// - a network drop mid-stream preserves the partial text received so far
/// - cancelling with no partial text appends no phantom assistant message
///
/// Uses an injected `FakeLLMService` above the network layer (no URLSession),
/// mirroring the protocol-level substitution pattern in `PremiumViewModelTests`.
@MainActor
struct ChatLifecycleTests {

    private func waitFor(_ predicate: @MainActor () -> Bool, timeoutMS: Int = 2000) async throws {
        let ticks = timeoutMS / 10
        for _ in 0..<ticks {
            if predicate() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        Issue.record("waitFor timed out waiting for condition")
    }

    @Test("cancelResponse preserves partial text, clears state, and ends streaming")
    func cancelResponsePreservesPartialText() async throws {
        let fake = FakeLLMService(tokens: ["partial token text"], shouldThrow: false)
        let viewModel = ChatViewModel(
            stressResult: nil,
            baseline: nil,
            llmService: fake
        )

        viewModel.send("hello")

        try await waitFor { viewModel.currentStreamingText == "partial token text" }
        #expect(viewModel.isStreaming)

        viewModel.cancelResponse()

        let last = viewModel.messages.last
        #expect(last?.role == .assistant)
        #expect(last?.content == "partial token text")
        #expect(viewModel.currentStreamingText.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.isStreaming == false)
    }

    @Test("network error mid-stream preserves partial text and surfaces an error")
    func networkErrorPreservesPartialText() async throws {
        let fake = FakeLLMService(tokens: ["Hello "], shouldThrow: true)
        let viewModel = ChatViewModel(
            stressResult: nil,
            baseline: nil,
            llmService: fake
        )

        viewModel.send("hello")

        // Wait for the terminal state, not `isLoading == false`: isLoading is
        // still false in the gap between send() returning and the streaming
        // task setting it true, so that predicate can pass before the stream
        // starts. errorMessage is set only in the catch block, after the
        // stream has delivered its tokens and the error.
        try await waitFor { viewModel.errorMessage?.isEmpty == false }

        let assistantContents = viewModel.messages
            .filter { $0.role == .assistant }
            .map(\.content)
        #expect(assistantContents.contains("Hello "))
        #expect(viewModel.errorMessage?.isEmpty == false)
    }

    @Test("cancelResponse with no partial text appends no assistant message")
    func cancelResponseWithNoPartialTextAppendsNothing() async throws {
        let fake = FakeLLMService(tokens: [], shouldThrow: false)
        let viewModel = ChatViewModel(
            stressResult: nil,
            baseline: nil,
            llmService: fake
        )

        viewModel.send("hello")
        try await waitFor { viewModel.isStreaming }

        let countBefore = viewModel.messages.count
        viewModel.cancelResponse()

        #expect(viewModel.messages.count == countBefore)
        #expect(viewModel.messages.allSatisfy { $0.role == .user })
    }
}

// MARK: - Fake LLM Service

/// Protocol-level double for `LLMServiceProtocol`. Yields `tokens` then either
/// blocks (simulating an in-flight stream, so cancellation is observable) or
/// throws (simulating a network drop). Sets `onTermination` so the consumer's
/// cancellation propagates to the producer, mirroring `SupabaseLLMService.send`.
@MainActor
final class FakeLLMService: LLMServiceProtocol {
    let tokens: [String]
    let shouldThrow: Bool

    init(tokens: [String], shouldThrow: Bool = false) {
        self.tokens = tokens
        self.shouldThrow = shouldThrow
    }

    func isAvailable() -> Bool { true }

    func send(messages: [ChatMessage], systemPrompt: String) async throws -> AsyncThrowingStream<String, Error> {
        let tokens = self.tokens
        let shouldThrow = self.shouldThrow
        return AsyncThrowingStream { continuation in
            let producer = Task { @MainActor in
                for token in tokens {
                    continuation.yield(token)
                }
                if shouldThrow {
                    continuation.finish(throwing: LLMServiceError.unavailable(reason: "network dropped"))
                } else {
                    try? await Task.sleep(for: .seconds(60))
                    continuation.finish(throwing: CancellationError())
                }
            }
            continuation.onTermination = { _ in producer.cancel() }
        }
    }
}
