import Foundation

// MARK: - Feature Flags

/// Build-time feature switches for work that ships dark until its backend
/// contract is live — same idea as `ChatAvailability`, but for whole screens.
/// Flip to `true` to light the feature up everywhere it is gated; the call
/// sites never change.
enum FeatureFlags {
    /// Health Coach chat (`POST /agent/chat`). Ships visible ahead of the
    /// backend Phase B deploy — until `/agent/chat` exists, sends surface
    /// a typed 404 in the chat view instead of hiding the entry.
    static let agentChatEnabled = true
}
