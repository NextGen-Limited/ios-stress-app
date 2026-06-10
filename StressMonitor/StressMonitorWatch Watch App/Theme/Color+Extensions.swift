import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alphaVal, redVal, greenVal, blueVal: UInt64
        switch hex.count {
        case 3:
            (alphaVal, redVal, greenVal, blueVal) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (alphaVal, redVal, greenVal, blueVal) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (alphaVal, redVal, greenVal, blueVal) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alphaVal, redVal, greenVal, blueVal) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(redVal) / 255,
            green: Double(greenVal) / 255,
            blue: Double(blueVal) / 255,
            opacity: Double(alphaVal) / 255
        )
    }

    init(light: Color, dark: Color) {
        // On watchOS, dynamic color provider is not available
        // Use the light variant as base - watchOS will handle appearance with system colors
        // For stress colors, the hex values are already appropriate for both modes
        self = light
    }
}
