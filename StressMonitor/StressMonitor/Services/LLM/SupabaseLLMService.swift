import Foundation

// MARK: - Supabase LLM Service

/// LLM service that connects to the Supabase Edge Function `/chat` endpoint.
/// Streams SSE responses through OpenRouter (OpenAI-compatible format).
/// Reuses the existing `SSEParser` for token extraction.
///
/// The backend handles:
/// - System prompt construction from `stress_context`
/// - Model selection with fallback chain
/// - Credit deduction per message
/// - Session/message persistence
@MainActor
final class SupabaseLLMService: LLMServiceProtocol, @unchecked Sendable {

    // MARK: - Properties

    /// JWT access token from auth. When nil, the service reports unavailable.
    private var accessToken: String?

    // MARK: - Init

    init(accessToken: String? = nil) {
        self.accessToken = accessToken
    }

    /// Update the access token (e.g. after sign-in or token refresh)
    func setAccessToken(_ token: String?) {
        self.accessToken = token
    }

    // MARK: - LLMServiceProtocol

    func isAvailable() -> Bool {
        // Available if we have a token or if in demo mode (no token needed for anon)
        // For now, always available — the Edge Function handles auth validation
        return true
    }

    nonisolated func send(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { (continuation: AsyncThrowingStream<String, Error>.Continuation) in
            let task = _Concurrency.Task {
                do {
                    // Build stress context from ChatViewModel's data
                    // The systemPrompt is ignored — backend builds it from stress_context
                    let stressContext = Self.currentStressContext

                    var request = URLRequest(url: SupabaseConfig.chatURL)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.timeoutInterval = 90

                    // Attach auth token if available
                    if let token = await self.accessToken {
                        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    }

                    // Build request body
                    let encodedMessages = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
                    var body: [String: Any] = [
                        "messages": encodedMessages,
                    ]
                    if let ctx = stressContext {
                        let encoder = JSONEncoder()
                        // CodingKeys already define snake_case — don't double-encode
                        if let ctxData = try? encoder.encode(ctx),
                           let ctxJSON = try? JSONSerialization.jsonObject(with: ctxData) {
                            body["stress_context"] = ctxJSON
                        }
                    }

                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    if let httpResponse = response as? HTTPURLResponse,
                       let error = Self.mapHTTPError(httpResponse.statusCode) {
                        bytes.task.cancel()
                        continuation.finish(throwing: error)
                        return
                    }

                    for try await line in bytes.lines {
                        switch SSEParser.parse(line: line) {
                        case .content(let token):
                            continuation.yield(token)
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

    // MARK: - Stress Context (thread-safe storage)

    /// The latest stress context, set by ChatViewModel before each message.
    /// Using a static to avoid Sendable issues with the nonisolated `send` method.
    nonisolated(unsafe) static var currentStressContext: StressContextPayload?

    // MARK: - Error Mapping

    nonisolated private static func mapHTTPError(_ statusCode: Int) -> LLMServiceError? {
        switch statusCode {
        case 200...299: return nil
        case 401: return .unavailable(reason: "Please sign in to use AI Chat.")
        case 402: return .unavailable(reason: "Out of credits. Monthly credits reset automatically.")
        case 429: return .rateLimited
        case 422: return .unavailable(reason: "Bad request body")
        case 502: return .unavailable(reason: "Provider failure")
        default: return .unavailable(reason: "Server error (\(statusCode))")
        }
    }
}
