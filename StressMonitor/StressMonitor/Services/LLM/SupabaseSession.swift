import Foundation

/// A Supabase Auth session — the response shape of both `/auth/v1/signup`
/// (anonymous sign-in) and `/auth/v1/token?grant_type=refresh_token`.
struct SupabaseSession: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: SupabaseUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }

    /// Wall-clock expiry, computed at decode time rather than trusting a
    /// server-provided absolute timestamp (clock skew).
    var expiresAt: Date {
        Date().addingTimeInterval(TimeInterval(expiresIn))
    }
}

struct SupabaseUser: Codable, Sendable {
    let id: String
    let isAnonymous: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case isAnonymous = "is_anonymous"
    }
}
