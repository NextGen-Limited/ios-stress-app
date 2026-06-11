import SwiftUI

/// Home-tab visual tokens derived from `docs/design/character-concept-sheet.html`.
/// Keeps the first redesign focused on Ripple / Water Otter while leaving room
/// for the full Elemental Creatures system.
enum HomeCharacterDesignTokens {
    enum Ripple {
        static let primary = Color(hex: "#4FC3F7")
        static let mid = Color(hex: "#81D4FA")
        static let light = Color(hex: "#B3E5FC")
        static let deep = Color(hex: "#0288D1")
    }

    enum Blossom {
        static let primary = Color(hex: "#A5D6A7")
        static let accent = Color(hex: "#81C784")
    }

    enum Ember {
        static let primary = Color(hex: "#FFAB91")
        static let accent = Color(hex: "#FF8A65")
    }

    enum Zephyr {
        static let primary = Color(hex: "#D1C4E9")
        static let accent = Color(hex: "#B39DDB")
    }

    enum Lumi {
        static let primary = Color(hex: "#7986CB")
        static let accent = Color(hex: "#5C6BC0")
    }

    static let ink = Color(hex: "#101223")
    static let mutedInk = Color(hex: "#777986")
    static let darkCanvas = Color(hex: "#0A0A0F")
    static let darkCard = Color(hex: "#1A1A2E")

    static var homeBackground: LinearGradient {
        LinearGradient(
            colors: [
                Ripple.light.opacity(0.32),
                Color.Wellness.adaptiveBackground,
                Blossom.primary.opacity(0.16)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                Ripple.primary.opacity(0.24),
                Ripple.light.opacity(0.18),
                Color.Wellness.adaptiveCardBackground
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
