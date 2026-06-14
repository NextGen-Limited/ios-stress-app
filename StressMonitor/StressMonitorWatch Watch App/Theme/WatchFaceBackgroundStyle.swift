import SwiftUI

// MARK: - WatchFaceBackgroundStyle

/// Background rendering style for watch face complications.
///
/// Each style maps to a different visual treatment applied behind the
/// Ripple character.  The actual colour ramp is driven by
/// `WatchFaceTheme`, so a single style + theme combination fully
/// determines the rendered background.
enum WatchFaceBackgroundStyle: String, CaseIterable, Codable, Sendable {
    /// Flat solid tint — subtle, battery-friendly.
    case solid
    /// Two-stop vertical gradient.
    case gradient
    /// Multi-stop diagonal wash evoking northern lights.
    case aurora
    /// Layered wave-like gradient evoking deep water.
    case ocean

    var displayName: String {
        switch self {
        case .solid:    return "Solid"
        case .gradient: return "Gradient"
        case .aurora:   return "Aurora"
        case .ocean:    return "Ocean"
        }
    }

    /// SF Symbol used in the picker row.
    var iconName: String {
        switch self {
        case .solid:    return "circle.fill"
        case .gradient: return "arrow.up.arrow.down.circle"
        case .aurora:   return "sparkles"
        case .ocean:    return "water.waves"
        }
    }
}

// MARK: - WatchFaceTheme

/// Five preset colour themes, one per StressMonitor character.
///
/// Hex values are kept in sync with `StressCharacterPalette` (the
/// watch-local copy of `HomeCharacterDesignTokens`).  Each theme exposes
/// a primary and secondary colour so gradient styles have a natural
/// ramp.
enum WatchFaceTheme: String, CaseIterable, Codable, Sendable {
    case ripple   // 💧 blue
    case blossom  // 🌿 green
    case ember    // 🔥 orange
    case zephyr   // 🌬️ purple
    case lumi     // 🌙 indigo

    var displayName: String {
        switch self {
        case .ripple:  return "Ripple"
        case .blossom: return "Blossom"
        case .ember:   return "Ember"
        case .zephyr:  return "Zephyr"
        case .lumi:    return "Lumi"
        }
    }

    var emoji: String {
        switch self {
        case .ripple:  return "💧"
        case .blossom: return "🌿"
        case .ember:   return "🔥"
        case .zephyr:  return "🌬️"
        case .lumi:    return "🌙"
        }
    }

    var primaryColor: Color {
        switch self {
        case .ripple:  return Color(hex: "#4FC3F7")
        case .blossom: return Color(hex: "#A5D6A7")
        case .ember:   return Color(hex: "#FFAB91")
        case .zephyr:  return Color(hex: "#B39DDB")
        case .lumi:    return Color(hex: "#7986CB")
        }
    }

    var secondaryColor: Color {
        switch self {
        case .ripple:  return Color(hex: "#0288D1")
        case .blossom: return Color(hex: "#81C784")
        case .ember:   return Color(hex: "#FF8A65")
        case .zephyr:  return Color(hex: "#9575CD")
        case .lumi:    return Color(hex: "#5C6BC0")
        }
    }
}

// MARK: - WatchFaceBackgroundView

/// Renders the chosen background treatment as a SwiftUI `View`.
///
/// Used both in-app (behind the settings preview and the home face)
/// and as the `containerBackground` content for complications.
struct WatchFaceBackgroundView: View {
    let style: WatchFaceBackgroundStyle
    let theme: WatchFaceTheme

    var body: some View {
        switch style {
        case .solid:
            theme.primaryColor.opacity(0.28)

        case .gradient:
            LinearGradient(
                colors: [
                    theme.primaryColor.opacity(0.34),
                    theme.secondaryColor.opacity(0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .aurora:
            LinearGradient(
                stops: [
                    .init(color: theme.primaryColor.opacity(0.38), location: 0.0),
                    .init(color: theme.secondaryColor.opacity(0.20), location: 0.5),
                    .init(color: theme.primaryColor.opacity(0.06), location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .ocean:
            LinearGradient(
                stops: [
                    .init(color: theme.secondaryColor.opacity(0.22), location: 0.0),
                    .init(color: theme.primaryColor.opacity(0.40), location: 0.45),
                    .init(color: theme.secondaryColor.opacity(0.14), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
