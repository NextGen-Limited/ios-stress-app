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
