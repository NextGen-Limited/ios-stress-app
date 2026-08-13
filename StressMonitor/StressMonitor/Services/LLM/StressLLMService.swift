import Foundation

// MARK: - Stress LLM Service

/// LLM service that connects to the standalone StressMonitor backend's
/// `/chat` endpoint via `StressAPIClient`. Streams SSE responses and
/// conforms to `LLMServiceProtocol` so `ChatViewModel` consumes it
/// through the same protocol seam (D-06).
///
/// Auth and request building live in `StressAPIClient` / `FirebaseAuthService`;
/// this type owns the SSE consumption loop, session/credits state, and the
/// HTTP 402 → `insufficientCredits` mapping (D-07).
@MainActor
final class StressLLMService: LLMServiceProtocol, @unchecked Sendable {

    // MARK: - Properties

    private(set) var currentSessionId: UUID?
    private(set) var creditsRemaining: Int?
    private(set) var modelUsed: String?
    private(set) var quickActions: [String]?

    private let stressAPIClient: StressAPIClient

    private static let sessionIdDefaultsKey = "stressChatSessionId"

    /// Clears the persisted chat session. Firebase token cache is owned by the
    /// Firebase SDK; signing out is `FirebaseAuthService.clearStoredCredentials()`.
    static func clearStoredCredentials() {
        UserDefaults.standard.removeObject(forKey: sessionIdDefaultsKey)
    }

    // MARK: - Init

    init(stressAPIClient: StressAPIClient? = nil) {
        self.stressAPIClient = stressAPIClient ?? StressAPIClient()
        if let storedSessionId = UserDefaults.standard.string(forKey: Self.sessionIdDefaultsKey) {
            self.currentSessionId = UUID(uuidString: storedSessionId)
        }
    }

    func resetSession() {
        currentSessionId = nil
        creditsRemaining = nil
        modelUsed = nil
        quickActions = nil
        UserDefaults.standard.removeObject(forKey: Self.sessionIdDefaultsKey)
    }

    // MARK: - LLMServiceProtocol

    func isAvailable() -> Bool {
        ChatAvailability.current.isAvailable
    }

    func send(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { (continuation: AsyncThrowingStream<String, Error>.Continuation) in
            let task = _Concurrency.Task { [stressAPIClient, currentSessionId] in
                do {
                    let stressContext = Self.currentStressContext

                    let (bytes, httpResponse) = try await stressAPIClient.sendChat(
                        messages: messages,
                        sessionId: currentSessionId,
                        stressContext: stressContext
                    )

                    if let error = Self.mapHTTPError(httpResponse.statusCode) {
                        bytes.task.cancel()
                        continuation.finish(throwing: error)
                        return
                    }

                    for try await line in bytes.lines {
                        switch SSEParser.parse(line: line) {
                        case .content(let token):
                            continuation.yield(token)
                        case .metadata(let metadata):
                            await self.apply(metadata: metadata)
                        case .done:
                            break
                        case .error(let msg):
                            continuation.finish(throwing: LLMServiceError.unavailable(reason: msg))
                            return
                        case .none:
                            break
                        }
                    }
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: LLMServiceError.cancelled)
                } catch {
                    continuation.finish(throwing: LLMServiceError.unknown(error))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Metadata Application

    private func apply(metadata: SSEMetadata) {
        if let sessionId = metadata.sessionId {
            currentSessionId = sessionId
            UserDefaults.standard.set(sessionId.uuidString, forKey: Self.sessionIdDefaultsKey)
        }
        creditsRemaining = metadata.creditsRemaining
        modelUsed = metadata.modelUsed
        quickActions = metadata.quickActions
    }

    // MARK: - Stress Context

    /// The latest stress context, set by ChatViewModel before each message.
    /// Static to avoid Sendable issues with the nonisolated `send` contract.
    static var currentStressContext: StressContextPayload?

    // MARK: - Error Mapping

    /// Maps the `/chat` HTTP status code to the `LLMServiceError` case the
    /// chat UI surfaces. Internal so the status-code → error-case contract
    /// (D-07: 402 → `.insufficientCredits`) is pinned by an automated test
    /// rather than only the live streaming path.
    static func mapHTTPError(_ statusCode: Int) -> LLMServiceError? {
        switch statusCode {
        case 200...299: return nil
        case 401: return .unavailable(reason: "Please sign in to use AI Chat.")
        case 402: return .insufficientCredits
        case 429: return .rateLimited
        case 422: return .unavailable(reason: "Bad request body")
        case 502: return .unavailable(reason: "Provider failure")
        default: return .unavailable(reason: "Server error (\(statusCode))")
        }
    }
}
