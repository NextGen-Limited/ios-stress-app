import Foundation

// MARK: - Preferences API Errors

/// Typed errors for the preferences endpoints. `.noValidFields` is the 400
/// the backend answers when a PUT carries no allowlisted field — the client
/// structurally avoids this by sending exactly one known key per call
/// (never a save-all; T-3-05).
enum PreferencesAPIError: Error, LocalizedError, Equatable, Sendable {
    case unauthorized
    case invalidResponse
    case noValidFields
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please sign in to sync your coach preferences."
        case .invalidResponse:
            return "Couldn't load preferences (invalid server response)."
        case .noValidFields:
            return "No valid preference field to update."
        case .server(let statusCode):
            return "Couldn't update preferences (server error \(statusCode))."
        }
    }
}

// MARK: - StressAPIClient + Preferences

extension StressAPIClient {

    /// GET /preferences — the full backend row; `UserPreferences` decodes the
    /// chat-relevant pair and ignores the other five allowlisted fields.
    func getPreferences() async throws -> UserPreferences {
        let request = try await authorizedRequest(path: "preferences", method: "GET")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PreferencesAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(UserPreferences.self, from: data)
        case 401:
            throw PreferencesAPIError.unauthorized
        default:
            throw PreferencesAPIError.server(statusCode: httpResponse.statusCode)
        }
    }

    /// PUT /preferences — the caller passes exactly one allowlisted key
    /// (`"language"` or `"coaching_style"`) per call; never the full row.
    /// The backend's ALLOWED_FIELDS filter drops anything else and 400s on
    /// an empty update, which maps to `.noValidFields`.
    func updatePreferences(fields: [String: String]) async throws -> UserPreferences {
        let body = try JSONSerialization.data(withJSONObject: fields)
        let request = try await authorizedRequest(path: "preferences", method: "PUT", body: body)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PreferencesAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(UserPreferences.self, from: data)
        case 400:
            throw PreferencesAPIError.noValidFields
        case 401:
            throw PreferencesAPIError.unauthorized
        default:
            throw PreferencesAPIError.server(statusCode: httpResponse.statusCode)
        }
    }
}
