import Foundation

// MARK: - Stress API Client

/// Centralized HTTP client for the standalone StressMonitor backend.
/// Injects a Firebase Bearer token into every authenticated request via
/// `AuthServiceProtocol`. The `/health` liveness probe is the one endpoint
/// that carries no Authorization header.
@MainActor
final class StressAPIClient {

    private let authService: AuthServiceProtocol
    private let baseURL: URL
    private let session: URLSession

    init(
        authService: AuthServiceProtocol? = nil,
        baseURL: URL? = nil,
        session: URLSession = .shared
    ) {
        self.authService = authService ?? FirebaseAuthService()
        self.baseURL = baseURL ?? StressAPIConfig.baseURL
        self.session = session
    }

    // MARK: - Request Builder

    /// Builds an authenticated URLRequest against the backend. Every
    /// non-`/health` endpoint requires a Firebase ID token (backend verifies
    /// via Firebase Admin `verifyIdToken`).
    func authorizedRequest(
        path: String,
        method: String,
        body: Data? = nil,
        accept: String? = nil
    ) async throws -> URLRequest {
        let token = try await authService.getIDToken()

        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accept {
            request.setValue(accept, forHTTPHeaderField: "Accept")
        }
        request.timeoutInterval = 90
        if let body {
            request.httpBody = body
        }
        return request
    }

    // MARK: - GET /health

    /// Liveness probe — public, no auth. Returns true only on HTTP 200.
    func getHealth() async throws -> Bool {
        var request = URLRequest(url: StressAPIConfig.healthURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        let (_, response) = try await session.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }

    // MARK: - POST /chat

    /// Opens the SSE streaming `/chat` response. The caller (StressLLMService)
    /// owns line-by-line consumption; this method only attaches the Bearer
    /// token and encodes the body, mirroring the request shape the backend's
    /// `src/routes/chat.ts` expects.
    func sendChat(
        messages: [ChatMessage],
        sessionId: UUID?,
        stressContext: StressContextPayload?
    ) async throws -> (URLSession.AsyncBytes, HTTPURLResponse) {
        let encodedMessages = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        var body: [String: Any] = [
            "messages": encodedMessages,
        ]
        if let sessionId {
            body["session_id"] = sessionId.uuidString
        }
        if let stressContext {
            let encoder = JSONEncoder()
            if let ctxData = try? encoder.encode(stressContext),
               let ctxJSON = try? JSONSerialization.jsonObject(with: ctxData) {
                body["stress_context"] = ctxJSON
            }
        }

        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let request = try await authorizedRequest(
            path: "chat",
            method: "POST",
            body: bodyData,
            accept: "text/event-stream"
        )

        let (bytes, response) = try await session.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            bytes.task.cancel()
            throw LLMServiceError.unavailable(reason: "Invalid response from server.")
        }
        return (bytes, httpResponse)
    }
}
