import Foundation

// MARK: - Chat Role

/// Role of a chat message participant
enum ChatRole: String, Codable, Sendable {
    case user
    case assistant
    case system
}

// MARK: - Chat Message

/// A single message in the AI chat conversation
struct ChatMessage: Identifiable, Codable, Sendable {
    let id: UUID
    let role: ChatRole
    let content: String
    let timestamp: Date

    // Chat sync metadata. The backend owns remote IDs, session IDs, and token counts.
    // Local messages default to unsynced until the backend persists them.
    var remoteId: UUID?
    var sessionId: UUID?
    var isSynced: Bool
    var tokensUsed: Int?

    init(
        id: UUID = UUID(),
        role: ChatRole,
        content: String,
        timestamp: Date = Date(),
        remoteId: UUID? = nil,
        sessionId: UUID? = nil,
        isSynced: Bool = false,
        tokensUsed: Int? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.remoteId = remoteId
        self.sessionId = sessionId
        self.isSynced = isSynced
        self.tokensUsed = tokensUsed
    }
}
