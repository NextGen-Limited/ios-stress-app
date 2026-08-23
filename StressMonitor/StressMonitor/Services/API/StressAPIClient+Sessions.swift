import Foundation

// MARK: - Sessions API Errors

/// Typed errors for the sessions endpoints. `.notFound` carries its own case
/// because a 404 from `GET /sessions/{id}/messages` means the stored session
/// is gone server-side — the restore path starts a fresh chat instead of
/// surfacing an error. `.unauthorized` mirrors the stale-session probe the
/// credits endpoints use.
enum SessionsAPIError: Error, LocalizedError, Equatable, Sendable {
    case unauthorized
    case invalidResponse
    case notFound
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please sign in to view your chat history."
        case .invalidResponse:
            return "Couldn't load chat sessions (invalid server response)."
        case .notFound:
            return "That chat session no longer exists on the server."
        case .server(let statusCode):
            return "Couldn't load chat sessions (server error \(statusCode))."
        }
    }
}

// MARK: - StressAPIClient + Sessions

extension StressAPIClient {

    /// GET /sessions?limit=&offset= — sessions ordered by `updated_at desc`.
    /// The wipe loop (03-04) paginates with this; the default page matches the
    /// backend's.
    func listSessions(limit: Int = 20, offset: Int = 0) async throws -> [ChatSession] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("sessions"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]
        guard let url = components?.url else {
            throw SessionsAPIError.invalidResponse
        }

        let request = try await authorizedRequest(url: url, method: "GET")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SessionsAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            let envelope = try JSONDecoder().decode(SessionsListResponse.self, from: data)
            return envelope.sessions
        case 401:
            throw SessionsAPIError.unauthorized
        default:
            throw SessionsAPIError.server(statusCode: httpResponse.statusCode)
        }
    }

    /// POST /sessions — creates a titled session and returns the full row.
    /// Called by `StressLLMService.send` before the first `/chat` of a new
    /// conversation so the session arrives titled rather than relying on the
    /// backend's "New Conversation" default.
    func createSession(
        title: String,
        stressContext: StressContextPayload?
    ) async throws -> ChatSession {
        var body: [String: Any] = ["title": title]
        if let stressContext {
            let encoder = JSONEncoder()
            if let ctxData = try? encoder.encode(stressContext),
               let ctxJSON = try? JSONSerialization.jsonObject(with: ctxData) {
                body["stress_context"] = ctxJSON
            }
        }
        let bodyData = try JSONSerialization.data(withJSONObject: body)

        let request = try await authorizedRequest(
            url: baseURL.appendingPathComponent("sessions"),
            method: "POST",
            body: bodyData
        )
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SessionsAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(ChatSession.self, from: data)
        case 401:
            throw SessionsAPIError.unauthorized
        default:
            throw SessionsAPIError.server(statusCode: httpResponse.statusCode)
        }
    }

    /// DELETE /sessions?id= — removes the session (messages cascade
    /// server-side). The route answers `{success: true}` even when the id
    /// belongs to another user or already vanished, so a 2xx is terminal:
    /// no follow-up verification request.
    func deleteSession(id: UUID) async throws {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("sessions"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "id", value: id.uuidString),
        ]
        guard let url = components?.url else {
            throw SessionsAPIError.invalidResponse
        }

        let request = try await authorizedRequest(url: url, method: "DELETE")
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SessionsAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw SessionsAPIError.unauthorized
        default:
            throw SessionsAPIError.server(statusCode: httpResponse.statusCode)
        }
    }

    /// GET /sessions/{id}/messages — server-authoritative history in
    /// `created_at asc` order. A 404 means the session is gone (deleted
    /// server-side or a dangling stored id) and maps to `.notFound`.
    func fetchMessages(sessionId: UUID) async throws -> [ChatSessionMessage] {
        let request = try await authorizedRequest(
            url: baseURL.appendingPathComponent("sessions/\(sessionId.uuidString)/messages"),
            method: "GET"
        )
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SessionsAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            let envelope = try JSONDecoder().decode(MessagesListResponse.self, from: data)
            return envelope.messages
        case 401:
            throw SessionsAPIError.unauthorized
        case 404:
            throw SessionsAPIError.notFound
        default:
            throw SessionsAPIError.server(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - Response Envelopes

private struct SessionsListResponse: Codable, Sendable {
    let sessions: [ChatSession]
}

private struct MessagesListResponse: Codable, Sendable {
    let messages: [ChatSessionMessage]
}
