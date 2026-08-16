import Foundation

// MARK: - Credits API Errors

/// Typed errors for the credits endpoints. 401 keeps its own case so callers
/// can distinguish a stale session (the AUTH-02 probe) from server faults.
enum CreditsAPIError: Error, LocalizedError, Equatable, Sendable {
    case unauthorized
    case invalidResponse
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please sign in to view your credits."
        case .invalidResponse:
            return "Couldn't load credits (invalid server response)."
        case .server(let statusCode):
            return "Couldn't load credits (server error \(statusCode))."
        }
    }
}

// MARK: - StressAPIClient + Credits

extension StressAPIClient {

    /// GET /credits — the server-authoritative balance.
    func getBalance() async throws -> CreditBalance {
        let request = try await authorizedRequest(path: "credits", method: "GET")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditsAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(CreditBalance.self, from: data)
        case 401:
            throw CreditsAPIError.unauthorized
        default:
            throw CreditsAPIError.server(statusCode: httpResponse.statusCode)
        }
    }
}
