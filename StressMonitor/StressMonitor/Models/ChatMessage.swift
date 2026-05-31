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

    init(
        id: UUID = UUID(),
        role: ChatRole,
        content: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}
