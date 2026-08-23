import Foundation

// MARK: - User Preferences

/// The chat-relevant pair of the backend's `user_preferences` row.
///
/// The row carries five more allowlisted fields (display_name, theme,
/// notification_enabled, stress_alert_threshold, custom_settings) that this
/// app deliberately ignores: they have no iOS owner mapping, are never read
/// into state, and are never sent back (Phase 3 CONTEXT lock). Extra JSON
/// keys are dropped silently by Codable on decode.
struct UserPreferences: Codable, Sendable, Equatable {
    let language: String
    let coachingStyle: String

    enum CodingKeys: String, CodingKey {
        case language
        case coachingStyle = "coaching_style"
    }
}
