import Foundation

enum HealthAPIError: Error, LocalizedError, Equatable, Sendable {
    case unauthorized
    case consentRequired
    case invalidResponse
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please sign in to sync health data."
        case .consentRequired:
            return "Health syncing needs your permission in Settings."
        case .invalidResponse:
            return "Health sync got an invalid server response."
        case .server(let statusCode):
            return "Health sync failed (server error \(statusCode))."
        }
    }
}

extension StressAPIClient {

    /// PUT /health/consent — records or revokes the health_ingest consent.
    /// The server row is the single source of truth; the app keeps no
    /// parallel consent state beyond UI display.
    @discardableResult
    func setHealthConsent(_ granted: Bool) async throws -> Bool {
        let body = try JSONSerialization.data(withJSONObject: ["granted": granted])
        let request = try await authorizedRequest(
            path: "health/consent", method: "PUT", body: body)
        let (data, response) = try await session.data(for: request)
        try throwHealthError(response, data: data)
        let status = try JSONDecoder().decode(ConsentStatus.self, from: data)
        return status.granted
    }

    /// POST /health/daily-summary — uploads one local day's aggregates and
    /// returns the freshly computed server score.
    func uploadDailySummary(_ payload: DailySummaryPayload) async throws -> ServerStressScore {
        let body = try JSONEncoder().encode(payload)
        let request = try await authorizedRequest(
            path: "health/daily-summary", method: "POST", body: body)
        let (data, response) = try await session.data(for: request)
        try throwHealthError(response, data: data)
        return try JSONDecoder().decode(ServerStressScore.self, from: data)
    }

    /// GET /stress/scores?from=&to= — newest first, default latest 30.
    func fetchStressScores(from: String? = nil, to: String? = nil) async throws -> [ServerStressScore] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("stress/scores"),
            resolvingAgainstBaseURL: false)
        var items: [URLQueryItem] = []
        if let from { items.append(URLQueryItem(name: "from", value: from)) }
        if let to { items.append(URLQueryItem(name: "to", value: to)) }
        if !items.isEmpty { components?.queryItems = items }
        guard let url = components?.url else { throw HealthAPIError.invalidResponse }

        let request = try await authorizedRequest(url: url, method: "GET")
        let (data, response) = try await session.data(for: request)
        try throwHealthError(response, data: data)
        return try JSONDecoder().decode(ScoresListResponse.self, from: data).scores
    }

    private func throwHealthError(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw HealthAPIError.invalidResponse
        }
        switch http.statusCode {
        case 200...299: return
        case 401: throw HealthAPIError.unauthorized
        case 403:
            if String(data: data, encoding: .utf8)?.contains("CONSENT_REQUIRED") == true {
                throw HealthAPIError.consentRequired
            }
            throw HealthAPIError.server(statusCode: 403)
        default: throw HealthAPIError.server(statusCode: http.statusCode)
        }
    }
}

struct ConsentStatus: Codable, Equatable, Sendable {
    let scope: String
    let granted: Bool
}

struct ScoresListResponse: Codable, Sendable {
    let scores: [ServerStressScore]
}
