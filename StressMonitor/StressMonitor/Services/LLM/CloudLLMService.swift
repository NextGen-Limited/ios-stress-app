import Foundation
import Moya

// MARK: - Cloud LLM Service

/// LLM service using Moya for endpoint definitions (health check)
/// and URLSession for SSE streaming (Moya lacks native SSE support).
/// Falls back gracefully when server is unreachable.
@MainActor
final class CloudLLMService: LLMServiceProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let provider: MoyaProvider<LLMAPITarget>

    // MARK: - Init

    init(provider: MoyaProvider<LLMAPITarget>) {
        self.provider = provider
    }

    convenience init() {
        self.init(provider: MoyaProvider())
    }

    // MARK: - Availability

    func isAvailable() -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var available = false

        provider.request(.healthCheck) { result in
            if case .success(let response) = result {
                available = response.statusCode == 200
            }
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 4)
        return available
    }

    // MARK: - Send

    nonisolated func send(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        let encodedMessages = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        var allMessages = [["role": "system", "content": systemPrompt]]
        allMessages.append(contentsOf: encodedMessages)

        return AsyncThrowingStream { (continuation: AsyncThrowingStream<String, Error>.Continuation) in
            let task = _Concurrency.Task {
                do {
                    guard let url = URL(string: "https://hyperpolysyllabically-saronic-mee.ngrok-free.app/v1/chat/completions") else {
                        continuation.finish(throwing: LLMServiceError.unavailable(reason: "Invalid server URL"))
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer changeme", forHTTPHeaderField: "Authorization")
                    request.timeoutInterval = 60

                    let body: [String: Any] = [
                        "model": "auto",
                        "messages": allMessages,
                        "stream": true,
                    ]
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

    // MARK: - Error Mapping

    nonisolated private static func mapHTTPError(_ statusCode: Int) -> LLMServiceError? {
        switch statusCode {
        case 200...299: return nil
        case 422: return .unavailable(reason: "Bad request body")
        case 502: return .unavailable(reason: "Provider failure")
        default: return .unavailable(reason: "Server error (\(statusCode))")
        }
    }
}
