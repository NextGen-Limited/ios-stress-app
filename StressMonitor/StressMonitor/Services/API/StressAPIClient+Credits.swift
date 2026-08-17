import Foundation

// MARK: - Credits API Errors

/// Typed errors for the credits endpoints. 401 keeps its own case so callers
/// can distinguish a stale session (the AUTH-02 probe) from server faults.
enum CreditsAPIError: Error, LocalizedError, Equatable, Sendable {
    case unauthorized
    case invalidResponse
    case invalidTransaction
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please sign in to view your credits."
        case .invalidResponse:
            return "Couldn't load credits (invalid server response)."
        case .invalidTransaction:
            return "The purchase couldn't be verified. It will retry automatically — if it keeps failing, contact purchase support."
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

    /// POST /credits/redeem — hands an Apple-signed purchase JWS to the
    /// backend, which verifies it independently and grants the credits.
    /// Idempotent server-side on the Apple transaction id, so a retry after
    /// a crash mid-flow never double-credits.
    func redeemPurchase(jws: String) async throws -> CreditBalance {
        try await postTransaction(jws: jws, path: "credits/redeem")
    }

    /// POST /credits/premium/verify — maps an active subscription transaction
    /// to server-side premium (DEC-1). Mirrors the redemption contract; the
    /// endpoint is the server half of the subscription entitlement sync.
    func verifySubscription(jws: String) async throws -> CreditBalance {
        try await postTransaction(jws: jws, path: "credits/premium/verify")
    }

    private func postTransaction(jws: String, path: String) async throws -> CreditBalance {
        let body = try JSONSerialization.data(withJSONObject: ["transaction_jws": jws])
        let request = try await authorizedRequest(path: path, method: "POST", body: body)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditsAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(CreditBalance.self, from: data)
        case 400:
            throw CreditsAPIError.invalidTransaction
        case 401:
            throw CreditsAPIError.unauthorized
        default:
            throw CreditsAPIError.server(statusCode: httpResponse.statusCode)
        }
    }
}
