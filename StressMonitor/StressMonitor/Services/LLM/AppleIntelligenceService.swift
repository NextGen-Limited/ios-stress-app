import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Apple Intelligence Service

/// LLM service using Apple's on-device Foundation Models framework (iOS 26+).
/// Gracefully falls back to static tips on unsupported devices.
final class AppleIntelligenceService: LLMServiceProtocol, Sendable {

    // MARK: - Availability

    func isAvailable() -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            return SystemLanguageModel.default.availability == .available
        }
        #endif
        return false
    }

    // MARK: - Send

    func send(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            return AsyncThrowingStream { continuation in
                Task {
                    do {
                        let session = LanguageModelSession(
                            instructions: Instructions(systemPrompt)
                        )

                        guard let lastUserMessage = messages.last(where: { $0.role == .user }) else {
                            continuation.finish()
                            return
                        }

                        let responseStream = session.streamResponse {
                            Prompt(lastUserMessage.content)
                        }

                        for try await partial in responseStream {
                            continuation.yield(partial.content)
                        }
                        continuation.finish()
                    } catch {
                        let mappedError = Self.mapError(error)
                        continuation.finish(throwing: mappedError)
                    }
                }
            }
        }
        #endif
        return AsyncThrowingStream { $0.finish(throwing: LLMServiceError.unavailable(reason: "Foundation Models requires iOS 26 or later.")) }
    }

    // MARK: - Error Mapping

    /// Maps Foundation Models errors to our LLMServiceError
    /// Uses string-based matching to avoid compile-time type dependencies
    private static func mapError(_ error: Error) -> LLMServiceError {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            // Map known GenerationError cases by checking the error description
            let description = error.localizedDescription.lowercased()

            if description.contains("context") && description.contains("exceed") {
                return .exceededContext
            }
            if description.contains("guardrail") {
                return .guardrailViolation
            }
            if description.contains("rate") && description.contains("limit") {
                return .rateLimited
            }
            if description.contains("refused") || description.contains("refuse") {
                return .refused
            }
            if description.contains("concurrent") {
                return .concurrentRequests
            }
            if description.contains("decod") && description.contains("fail") {
                return .decodingFailure
            }
            if description.contains("unsupported") && description.contains("language") {
                return .unavailable(reason: "This language is not supported.")
            }
        }
        #endif
        return .unknown(error)
    }
}
