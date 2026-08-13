import Foundation

// MARK: - Chat Availability

/// Single source of truth for whether AI Coaching is reachable in this build.
///
/// Read by the two Chat entry points (`ActionView` RippleRecommendationCard CTA,
/// `SettingsView` chat row), by `ChatViewModel.isAvailable`, and by
/// `StressLLMService.isAvailable()`. Flipping `current` to `.enabled` in a
/// Release build re-enables Chat everywhere without touching call sites.
enum ChatAvailability: Sendable, Equatable {
    case enabled
    case disabled(reason: DisabledReason)

    /// v1.1 wires real Firebase auth, so Chat is reachable in every config.
    static var current: ChatAvailability { .enabled }

    var isAvailable: Bool {
        self == .enabled
    }
}

// MARK: - Disabled Reason

enum DisabledReason: String, Sendable {
    case comingSoon
}
