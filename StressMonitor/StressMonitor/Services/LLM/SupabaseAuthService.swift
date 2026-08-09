import Foundation

// MARK: - Supabase Auth Service

/// Replaces the hardcoded, already-expired guest JWT with real Supabase Auth
/// sessions: anonymous sign-in for a fresh install, refresh for keeping an
/// existing session alive. Hand-rolled REST calls against Supabase Auth's
/// stable API — matches the existing no-SDK pattern this app already uses
/// for `/chat` in `SupabaseLLMService`.
///
/// Requires `enable_anonymous_sign_ins = true` on the Supabase project. This
/// repo's tracked `stress-app-be/supabase/config.toml` shows it disabled —
/// confirm the live dashboard actually has it on before relying on this.
protocol SupabaseAuthServiceProtocol: Sendable {
    func signInAnonymously() async throws -> SupabaseSession
    func refreshSession(refreshToken: String) async throws -> SupabaseSession
}

final class SupabaseAuthService: SupabaseAuthServiceProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func signInAnonymously() async throws -> SupabaseSession {
        var request = URLRequest(url: SupabaseConfig.url.appendingPathComponent("auth/v1/signup"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONSerialization.data(withJSONObject: [String: Any]())

        return try await perform(request)
    }

    func refreshSession(refreshToken: String) async throws -> SupabaseSession {
        var components = URLComponents(
            url: SupabaseConfig.url.appendingPathComponent("auth/v1/token"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "grant_type", value: "refresh_token")]

        guard let url = components?.url else {
            throw SupabaseAuthError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["refresh_token": refreshToken])

        return try await perform(request)
    }

    private func perform(_ request: URLRequest) async throws -> SupabaseSession {
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw SupabaseAuthError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw SupabaseAuthError.requestFailed(statusCode: http.statusCode)
        }

        do {
            return try JSONDecoder().decode(SupabaseSession.self, from: data)
        } catch {
            throw SupabaseAuthError.decodingFailed(error)
        }
    }
}

enum SupabaseAuthError: Error {
    case invalidRequest
    case invalidResponse
    case requestFailed(statusCode: Int)
    case decodingFailed(Error)

    var localizedDescription: String {
        switch self {
        case .invalidRequest:
            return "Could not build the auth request."
        case .invalidResponse:
            return "Received an unexpected response from the auth server."
        case .requestFailed(let statusCode):
            switch statusCode {
            case 422:
                return "Anonymous sign-in is not enabled for this project."
            case 401:
                return "Session expired. Please try again."
            default:
                return "Auth request failed (\(statusCode))."
            }
        case .decodingFailed:
            return "Could not read the auth server's response."
        }
    }
}
