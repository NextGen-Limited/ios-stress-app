import SwiftUI

// MARK: - Color(hex:)

extension Color {
    /// Parse a `#RRGGBB` / `#RGB` / `#AARRGGBB` hex string into a Color.
    /// Mirrors the iOS app's `Color(hex:)` so token values match exactly.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Adaptive light/dark colour.  watchOS does not expose
    /// `UIColor(dynamicProvider:)`, so we resolve to the light variant —
    /// the watch app targets the iOS light design system.  The dark
    /// argument is retained for API symmetry with the iOS app.
    init(light: Color, dark: Color) {
        self = light
    }

    // MARK: - Stress-scale convenience accessors (iOS-aligned)

    /// 5-tier stress scale, light-set hexes mirrored from the iOS app's
    /// `StressCategory.color` (no shared framework — mirror convention).
    static let stressRelaxed  = Color(hex: "#00A000")
    static let stressMild     = Color(hex: "#007AFF")
    static let stressModerate = Color(hex: "#8A5A00")
    static let stressHigh     = Color(hex: "#B25400")
    static let stressSevere   = Color(hex: "#FF3B30")

    /// Resolve the stress colour for a raw 0–100+ level.
    static func stressColor(for level: Double) -> Color {
        StressCategory.category(for: level).color
    }

    /// Resolve the stress colour for a category.
    static func stressColor(for category: StressCategory) -> Color {
        category.color
    }
}
