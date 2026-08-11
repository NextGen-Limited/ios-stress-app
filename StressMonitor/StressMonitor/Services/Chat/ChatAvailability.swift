import Foundation

// MARK: - Chat Availability

/// Single source of truth for whether AI Coaching is reachable in this build.
///
/// Read by the two Chat entry points (`ActionView` RippleRecommendationCard CTA,
/// `SettingsView` chat row), by `ChatViewModel.isAvailable`, and by
/// `SupabaseLLMService.isAvailable()`. Flipping `current` to `.enabled` in a
/// Release build re-enables Chat everywhere without touching call sites.
enum ChatAvailability: Sendable, Equatable {
    case enabled
    case disabled(reason: DisabledReason)

    /// Compile-time gate. DEBUG/local-dev keeps Chat reachable; Release ships
    /// honestly disabled until v1.1 wires real Supabase auth + ASC anon key.
    static var current: ChatAvailability {
        #if DEBUG
        return .enabled
        #else
        return .disabled(reason: .comingSoon)
        #endif
    }

    var isAvailable: Bool {
        self == .enabled
    }
}

// MARK: - Disabled Reason

enum DisabledReason: String, Sendable {
    case comingSoon
}
