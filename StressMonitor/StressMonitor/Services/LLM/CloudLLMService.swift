import Foundation

// MARK: - Cloud LLM Service

/// LLM service that calls a self-hosted FastAPI gateway via HTTP/SSE.
/// Falls back gracefully when server is unreachable.
final class CloudLLMService: LLMServiceProtocol, Sendable {

    // TODO: Update to production URL before release
    private let apiKey: String

    init(apiKey: String = "") {
        self.apiKey = apiKey
    }

    // MARK: - Availability

    nonisolated func isAvailable() -> Bool {
        guard let url = URL(string: "https://hyperpolysyllabically-saronic-mee.ngrok-free.app/health") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 3

        let semaphore = DispatchSemaphore(value: 0)
        var available = false

        URLSession.shared.dataTask(with: request) { _, response, _ in
            available = (response as? HTTPURLResponse)?.statusCode == 200
            semaphore.signal()
        }.resume()

        _ = semaphore.wait(timeout: .now() + 4)
        return available
    }

    // MARK: - Send

    nonisolated func send(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        let apiKey = self.apiKey
        let encodedMessages = messages.map { ["role": $0.role.rawValue, "content": $0.content] as [String: String] }

        return AsyncThrowingStream { (continuation: AsyncThrowingStream<String, Error>.Continuation) in
            let task = Task {
                do {
                    guard let url = URL(string: "https://hyperpolysyllabically-saronic-mee.ngrok-free.app/v1/chat/completions") else {
                        continuation.finish(throwing: LLMServiceError.unavailable(reason: "Invalid server URL"))
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.timeoutInterval = 60

                    // Build messages array with system prompt as first message
                    var allMessages = [["role": "system", "content": systemPrompt] as [String: String]]
                    allMessages.append(contentsOf: encodedMessages)

                    let body: [String: Any] = [
                        "model": "deepseek-chat",
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
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))

                        if payload == "[DONE]" { break }

                        if let data = payload.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let token = json["token"] as? String {
                                continuation.yield(token)
                            }
                            if let errorMsg = json["error"] as? String {
                                continuation.finish(throwing: LLMServiceError.unknown(
                                    NSError(domain: "CloudLLM", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMsg])
                                ))
                                return
                            }
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
        case 401: return .unavailable(reason: "Invalid API key")
        case 422: return .unavailable(reason: "Bad request body")
        case 502: return .unavailable(reason: "Provider failure")
        default: return .unavailable(reason: "Server error (\(statusCode))")
        }
    }
}
