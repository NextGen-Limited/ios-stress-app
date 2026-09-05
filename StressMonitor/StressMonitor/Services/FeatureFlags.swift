import Foundation

// MARK: - Feature Flags

/// Build-time feature switches for work that ships dark until its backend
/// contract is live — same idea as `ChatAvailability`, but for whole screens.
/// Flip to `true` to light the feature up everywhere it is gated; the call
/// sites never change.
enum FeatureFlags {
    /// Health Coach chat (POST /agent/chat). The endpoint is not deployed to
    /// every backend yet, so the Settings entry stays hidden until it is.
    static let agentChatEnabled = true
}
