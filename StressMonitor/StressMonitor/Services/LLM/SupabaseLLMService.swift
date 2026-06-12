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

    /// JWT access token from Supabase Auth. When nil, Edge Functions return 401.
    private var accessToken: String?
    private var sessionId: UUID?
    private(set) var creditsRemaining: Int?
    private(set) var modelUsed: String?
    var currentSessionId: UUID? { sessionId }

    private static let accessTokenDefaultsKey = "supabaseAccessToken"
    private static let sessionIdDefaultsKey = "supabaseChatSessionId"

    // MARK: - Init

    init(accessToken: String? = nil) {
        self.accessToken = accessToken ?? UserDefaults.standard.string(forKey: Self.accessTokenDefaultsKey)
        if let storedSessionId = UserDefaults.standard.string(forKey: Self.sessionIdDefaultsKey) {
            self.sessionId = UUID(uuidString: storedSessionId)
        }
    }

    /// Update the access token (e.g. after sign-in or token refresh)
    func setAccessToken(_ token: String?) {
        self.accessToken = token
        if let token, !token.isEmpty {
            UserDefaults.standard.set(token, forKey: Self.accessTokenDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.accessTokenDefaultsKey)
        }
    }

    func resetSession() {
        sessionId = nil
        creditsRemaining = nil
        modelUsed = nil
        UserDefaults.standard.removeObject(forKey: Self.sessionIdDefaultsKey)
    }

    // MARK: - LLMServiceProtocol

    func isAvailable() -> Bool {
        SupabaseConfig.isConfigured && accessToken?.isEmpty == false
    }

    func send(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { (continuation: AsyncThrowingStream<String, Error>.Continuation) in
            let task = _Concurrency.Task {
                do {
                    // Build stress context from ChatViewModel's data.
                    // The systemPrompt is ignored — backend builds it from stress_context.
                    let stressContext = Self.currentStressContext

                    guard SupabaseConfig.isConfigured else {
                        continuation.finish(throwing: LLMServiceError.unavailable(
                            reason: "Supabase anon key is not configured. Set SUPABASE_ANON_KEY in the app build settings."
                        ))
                        return
                    }

                    guard let token = await self.accessToken, !token.isEmpty else {
                        continuation.finish(throwing: LLMServiceError.unavailable(
                            reason: "Please sign in to use AI Chat."
                        ))
                        return
                    }

                    let currentSessionId = await self.sessionId

                    var request = URLRequest(url: SupabaseConfig.chatURL)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.timeoutInterval = 90

                    // Build request body
                    let encodedMessages = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
                    var body: [String: Any] = [
                        "messages": encodedMessages,
                    ]
                    if let currentSessionId {
                        body["session_id"] = currentSessionId.uuidString
                    }
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

    private func apply(metadata: SSEMetadata) {
        if let sessionId = metadata.sessionId {
            self.sessionId = sessionId
            UserDefaults.standard.set(sessionId.uuidString, forKey: Self.sessionIdDefaultsKey)
        }
        creditsRemaining = metadata.creditsRemaining
        modelUsed = metadata.modelUsed
    }

    // MARK: - Stress Context (thread-safe storage)

    /// The latest stress context, set by ChatViewModel before each message.
    /// Using a static to avoid Sendable issues with the nonisolated `send` method.
    static var currentStressContext: StressContextPayload?

    // MARK: - Error Mapping

    private static func mapHTTPError(_ statusCode: Int) -> LLMServiceError? {
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
