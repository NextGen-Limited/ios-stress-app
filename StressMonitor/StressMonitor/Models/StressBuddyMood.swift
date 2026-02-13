import SwiftUI

/// Stress Buddy character mood states mapped to stress levels
/// Part of Phase 2: Character System with WCAG-compliant dual coding
public enum StressBuddyMood: String, CaseIterable, Sendable {
    case sleeping     // 0-10: very relaxed
    case calm         // 10-25: relaxed
    case concerned    // 25-50: mild stress
    case worried      // 50-75: moderate stress
    case overwhelmed  // 75-100: high stress

    // MARK: - Stress Level Mapping

    /// Map stress level (0-100) to character mood
    /// - Parameter stressLevel: Stress level from 0-100
    /// - Returns: Corresponding mood
    public static func from(stressLevel: Double) -> StressBuddyMood {
        switch stressLevel {
        case ..<10:
            return .sleeping
        case 10..<25:
            return .calm
        case 25..<50:
            return .concerned
        case 50..<75:
            return .worried
        default:
            return .overwhelmed
        }
    }

    // MARK: - Visual Representation

    /// SF Symbol for this mood
    public var symbol: String {
        switch self {
        case .sleeping:
            return "moon.zzz.fill"
        case .calm:
            return "figure.mind.and.body"
        case .concerned:
            return "figure.walk.circle"
        case .worried:
            return "exclamationmark.triangle.fill"
        case .overwhelmed:
            return "flame.fill"
        }
    }

    /// Accessory symbols to display alongside character
    public var accessories: [String] {
        switch self {
        case .sleeping:
            return ["zzz"]
        case .calm:
            return []
        case .concerned:
            return ["star.fill"]
        case .worried:
            return ["drop.fill"]
        case .overwhelmed:
            return ["drop.fill", "star.fill"]
        }
    }

    /// Color for the mood
    public var color: Color {
        switch self {
        case .sleeping, .calm:
            return StressCategory.relaxed.color
        case .concerned:
            return StressCategory.mild.color
        case .worried:
            return StressCategory.moderate.color
        case .overwhelmed:
            return StressCategory.high.color
        }
    }

    // MARK: - Size Variants

    /// Context for character display size
    public enum CharacterContext {
        case dashboard
        case widget
        case watchOS
    }

    /// Size for symbol based on context
    /// - Parameter context: Display context
    /// - Returns: Point size for the symbol
    public func symbolSize(for context: CharacterContext) -> CGFloat {
        switch context {
        case .dashboard:
            return 120
        case .widget:
            return 80
        case .watchOS:
            return 60
        }
    }

    /// Accessory size relative to main symbol
    /// - Parameter context: Display context
    /// - Returns: Point size for accessories
    public func accessorySize(for context: CharacterContext) -> CGFloat {
        symbolSize(for: context) * 0.3
    }

    // MARK: - Accessibility

    /// VoiceOver description
    public var accessibilityDescription: String {
        switch self {
        case .sleeping:
            return "Very relaxed, sleeping peacefully"
        case .calm:
            return "Calm and relaxed"
        case .concerned:
            return "Showing mild concern"
        case .worried:
            return "Moderately worried"
        case .overwhelmed:
            return "Feeling overwhelmed"
        }
    }

    /// Display name for UI
    public var displayName: String {
        rawValue.capitalized
    }
}
