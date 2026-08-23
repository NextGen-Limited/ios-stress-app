import Foundation

// MARK: - Chat Session Message

/// A persisted chat message row from `GET /sessions/{id}/messages`, delivered
/// in server order (`created_at asc`). The server is the authoritative message
/// store — this DTO maps into the in-memory display model (`ChatMessage`) at
/// restore time and is never cached in SwiftData.
struct ChatSessionMessage: Codable, Sendable, Equatable {
    let id: UUID
    let sessionId: UUID
    let role: ChatRole
    let content: String
    let tokensUsed: Int?
    /// ISO-8601 timestamp string with fractional seconds as delivered — kept
    /// as String, never decoded as Date (see `ChatSession.createdAt`).
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case role
        case content
        case tokensUsed = "tokens_used"
        case createdAt = "created_at"
    }
}
