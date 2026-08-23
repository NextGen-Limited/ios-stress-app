import Foundation

// MARK: - Quick Actions API Errors

/// Typed errors for the quick-actions suggestions endpoint.
enum QuickActionsAPIError: Error, LocalizedError, Equatable, Sendable {
    case unauthorized
    case invalidResponse
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please sign in to load chat suggestions."
        case .invalidResponse:
            return "Couldn't load chat suggestions (invalid server response)."
        case .server(let statusCode):
            return "Couldn't load chat suggestions (server error \(statusCode))."
        }
    }
}

// MARK: - StressAPIClient + Quick Actions

/// The suggestions fetch for the chat chips (derived-QA-01).
///
/// This extension holds exactly ONE request method and it is a GET. The
/// backend's `POST /quick-actions` is an unmetered 512-token completion with
/// no credit deduction — wiring it would bypass the Phase 2 revenue model,
/// so it must never be called from iOS (COVERAGE row 17). Chip taps resolve
/// their prompt locally via `ChatQuickActions.prompt(forServerActionId:)`
/// and send through the credit-metered `/chat` path.
extension StressAPIClient {

    /// GET /quick-actions?stress_level=&language=&coaching_style= —
    /// deterministic server-side suggestions contextualized to the live
    /// stress level and the user's coach preferences.
    func getQuickActions(
        stressLevel: Int,
        language: String,
        coachingStyle: String
    ) async throws -> [ServerQuickAction] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("quick-actions"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "stress_level", value: String(stressLevel)),
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "coaching_style", value: coachingStyle),
        ]
        guard let url = components?.url else {
            throw QuickActionsAPIError.invalidResponse
        }

        let request = try await authorizedRequest(url: url, method: "GET")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuickActionsAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            let envelope = try JSONDecoder().decode(QuickActionsResponse.self, from: data)
            return envelope.quickActions
        case 401:
            throw QuickActionsAPIError.unauthorized
        default:
            throw QuickActionsAPIError.server(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - Response Envelope

private struct QuickActionsResponse: Codable, Sendable {
    let quickActions: [ServerQuickAction]

    enum CodingKeys: String, CodingKey {
        case quickActions = "quick_actions"
    }
}
