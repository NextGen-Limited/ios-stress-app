import SwiftUI

extension Color {
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

    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    // MARK: - Stress Level Colors

    static let stressRelaxed = Color(light: Color(hex: "#34C759"), dark: Color(hex: "#30D158"))
    static let stressMild = Color(light: Color(hex: "#007AFF"), dark: Color(hex: "#0A84FF"))
    static let stressModerate = Color(hex: "#FFD60A")
    static let stressHigh = Color(light: Color(hex: "#FF9500"), dark: Color(hex: "#FF9F0A"))
    static let stressSevere = Color(light: Color(hex: "#FF3B30"), dark: Color(hex: "#FF453A"))

    // MARK: - Semantic Colors

    static let primaryBlue = Color(light: Color(hex: "#007AFF"), dark: Color(hex: "#0A84FF"))
    static let primaryGreen = Color(light: Color(hex: "#34C759"), dark: Color(hex: "#30D158"))
    static let success = Color(light: Color(hex: "#34C759"), dark: Color(hex: "#30D158"))
    static let warning = Color(hex: "#FFB00A")
    static let error = Color(light: Color(hex: "#FF3B30"), dark: Color(hex: "#FF453A"))

    // MARK: - Light Mode Colors

    static let backgroundLight = Color(hex: "#F2F2F7")
    static let surfaceLight = Color.white
    static let cardLight = Color.white
    static let textPrimaryLight = Color.black
    static let textSecondaryLight = Color(hex: "#8E8E93")
    static let dividerLight = Color(hex: "#C6C6C8")

    // MARK: - Dark Mode Colors

    static let backgroundDark = Color.black
    static let surfaceDark = Color(hex: "#1C1C1E")
    static let cardDark = Color(hex: "#1C1C1E")
    static let textPrimaryDark = Color.white
    static let textSecondaryDark = Color(hex: "#EBEBF5")
    static let dividerDark = Color(hex: "#38383A")

    // MARK: - OLED Dark Mode Colors

    /// Deep dark background for OLED displays - #121212
    static let oledBackground = Color(hex: "#121212")
    /// Card background for OLED dark theme - #1E1E1E
    static let oledCardBackground = Color(hex: "#1E1E1E")
    /// Secondary card background for OLED - #2A2A2A
    static let oledCardSecondary = Color(hex: "#2A2A2A")
    /// Secondary text color for OLED - #9CA3AF
    static let oledTextSecondary = Color(hex: "#9CA3AF")

    // MARK: - Accent Colors

    /// HRV accent color (green-teal)
    static let hrvAccent = Color(hex: "#34D399")
    /// Heart rate accent color (red-pink)
    static let heartRateAccent = Color(hex: "#F87171")

    // MARK: - Settings Screen Colors

    /// Settings background (light: #F3F4F8, dark: #1C1C1E)
    static let settingsBackground = Color(light: Color(hex: "F3F4F8"), dark: Color(hex: "1C1C1E"))
    /// Accent teal (light: #85C9C9, dark: #6DB3B3)
    static let accentTeal = Color(light: Color(hex: "85C9C9"), dark: Color(hex: "6DB3B3"))
    /// Premium gold - #FE9901
    static let premiumGold = Color(hex: "FE9901")
    /// Tertiary text - #808080
    static let textTertiary = Color(hex: "808080")
    /// Descriptive text - #848484
    static let textDescriptive = Color(hex: "848484")
    /// Light border - #DBDBDB
    static let borderLight = Color(light: Color(hex: "DBDBDB"), dark: Color(hex: "38383A"))
    /// Widget border - #C0C0C0
    static let widgetBorder = Color(light: Color(hex: "C0C0C0"), dark: Color(hex: "48484A"))
    /// Settings card shadow color - #18274B
    static let settingsCardShadowColor = Color(hex: "18274B")

    // MARK: - Adaptive Colors for Settings

    /// Adaptive background for settings screen
    static var adaptiveSettingsBackground: Color {
        Color(light: Color(hex: "F3F4F8"), dark: Color(hex: "1C1C1E"))
    }

    /// Adaptive card background (white in light, elevated in dark)
    static var adaptiveCardBackground: Color {
        Color(light: .white, dark: Color(hex: "2C2C2E"))
    }

    // MARK: - Color Helpers

    static func stressColor(for level: Double) -> Color {
        switch level {
        case 0...25: return .stressRelaxed
        case 26...50: return .stressMild
        case 51...75: return .stressModerate
        case 76...100: return .stressHigh
        default: return .secondary
        }
    }

    static func stressColor(for category: StressCategory) -> Color {
        // Delegate to StressCategory as single source of truth
        return category.color
    }

    static func stressIcon(for category: StressCategory) -> String {
        // Delegate to StressCategory as single source of truth
        return category.icon
    }
}
