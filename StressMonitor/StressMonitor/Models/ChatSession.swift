import Foundation

// MARK: - Chat Session

/// A server-side chat session row from `GET/POST /sessions`.
///
/// The backend owns session identity; the app only continues or deletes
/// sessions the server issued. Extra row keys (`user_id`, `stress_context`,
/// `model_used`, `is_archived`) are ignored by Codable.
struct ChatSession: Codable, Sendable, Equatable {
    let id: UUID
    let title: String
    /// ISO-8601 timestamp string exactly as the backend delivers it. Postgres
    /// timestamptz serializes with fractional seconds (e.g.
    /// "2026-08-23T07:39:53.953Z"), which `.iso8601` decoding cannot parse —
    /// never decode these as `Date`.
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
