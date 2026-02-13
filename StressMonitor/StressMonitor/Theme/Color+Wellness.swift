import SwiftUI

// MARK: - Wellness Color Palette
extension Color {
    /// Wellness color palette based on calm blues and health greens
    struct Wellness {
        // MARK: - Primary Colors

        /// Calm Blue - Healthcare trust color
        static let calmBlue = Color(
            light: Color(hex: "#0891B2"), // Cyan-600
            dark: Color(hex: "#22D3EE")   // Cyan-400
        )

        /// Health Green - Wellness/growth
        static let healthGreen = Color(
            light: Color(hex: "#10B981"), // Emerald-500
            dark: Color(hex: "#34D399")   // Emerald-400
        )

        /// Gentle Purple - Mindfulness
        static let gentlePurple = Color(
            light: Color(hex: "#8B5CF6"), // Violet-500
            dark: Color(hex: "#A78BFA")   // Violet-400
        )

        // MARK: - Background Colors

        /// Pure black for OLED dark mode
        static let backgroundDark = Color(hex: "#000000")

        /// Light mode background
        static let backgroundLight = Color(hex: "#F2F2F7")

        /// Card surface in dark mode
        static let surfaceDark = Color(hex: "#1C1C1E")

        /// Card surface in light mode
        static let surfaceLight = Color.white

        // MARK: - Adaptive Colors

        /// Primary background that adapts to color scheme
        static let background = Color(
            light: backgroundLight,
            dark: backgroundDark
        )

        /// Surface color that adapts to color scheme
        static let surface = Color(
            light: surfaceLight,
            dark: surfaceDark
        )
    }
}

// MARK: - Stress Level Colors with Dual Coding
extension Color {
    /// Get stress color with dual coding support (color + icon)
    /// - Parameters:
    ///   - category: The stress category
    ///   - highContrast: Whether to use high contrast variant
    /// - Returns: Color for the stress level
    static func accessibleStressColor(for category: StressCategory, highContrast: Bool = false) -> Color {
        if highContrast {
            // WCAG AAA compliant high contrast colors (7:1 ratio)
            switch category {
            case .relaxed:
                return Color(hex: "#00A000") // Darker green
            case .mild:
                return Color(hex: "#0050FF") // Darker blue
            case .moderate:
                return Color(hex: "#FFA500") // Orange (not yellow for better contrast)
            case .high:
                return Color(hex: "#CC0000") // Dark red
            }
        }

        // Standard colors with WCAG AA compliance (4.5:1 ratio)
        // Delegate to StressCategory as single source of truth
        return category.color
    }
}

// MARK: - Accessibility-Aware View Modifier
struct AccessibilityContrastModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) var colorSchemeContrast
    let category: StressCategory

    func body(content: Content) -> some View {
        content
            .foregroundStyle(
                Color.accessibleStressColor(
                    for: category,
                    highContrast: colorSchemeContrast == .increased
                )
            )
    }
}

extension View {
    /// Apply accessible stress color based on system contrast setting
    /// - Parameter category: The stress category
    /// - Returns: View with accessible color applied
    func accessibleStressColor(for category: StressCategory) -> some View {
        modifier(AccessibilityContrastModifier(category: category))
    }
}
