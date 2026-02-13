import SwiftUI

// MARK: - Wellness Typography System
extension Font {
    /// Wellness-themed custom fonts with fallbacks to SF Pro
    struct WellnessType {
        // MARK: - Google Fonts Constants

        private static let loraFontName = "Lora"
        private static let ralewayFontName = "Raleway"

        // MARK: - Heading Fonts (Lora - Organic curves, wellness vibe)

        /// Hero number for stress ring center
        static let heroNumber = custom(loraFontName, size: 72, weight: .bold)

        /// Large metric display
        static let largeMetric = custom(loraFontName, size: 48, weight: .bold)

        /// Card titles
        static let cardTitle = custom(loraFontName, size: 28, weight: .bold)

        /// Section headers
        static let sectionHeader = custom(loraFontName, size: 22, weight: .semibold)

        // MARK: - Body Fonts (Raleway - Elegant simplicity, accessible)

        /// Primary content
        static let body = custom(ralewayFontName, size: 17, weight: .regular)

        /// Emphasized text
        static let bodyEmphasized = custom(ralewayFontName, size: 17, weight: .semibold)

        /// Captions and labels
        static let caption = custom(ralewayFontName, size: 13, weight: .regular)

        /// Tiny text
        static let caption2 = custom(ralewayFontName, size: 11, weight: .regular)

        // MARK: - Helper Function

        /// Create custom font with fallback to SF Pro
        private static func custom(_ name: String, size: CGFloat, weight: Font.Weight) -> Font {
            // Try to use custom font first
            if UIFont.familyNames.contains(where: { $0.contains(name) }) {
                return .custom(name, size: size)
            }

            // Fallback to SF Pro system font with same weight
            return .system(size: size, weight: weight, design: .default)
        }
    }
}

// MARK: - Dynamic Type Support
extension View {
    /// Apply Dynamic Type scaling with accessibility support
    /// Limits scaling to accessibility3 and allows minimum 70% scale factor
    func accessibleWellnessType() -> some View {
        self
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
            .minimumScaleFactor(0.7)
            .lineLimit(nil)
    }

    /// Apply Dynamic Type with single line constraint
    /// Useful for buttons and labels that must stay single-line
    func accessibleWellnessTypeSingleLine() -> some View {
        self
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
            .minimumScaleFactor(0.7)
            .lineLimit(1)
    }

    /// Apply Dynamic Type with specific line limit
    /// - Parameter lines: Maximum number of lines
    func accessibleWellnessType(lines: Int) -> some View {
        self
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
            .minimumScaleFactor(0.7)
            .lineLimit(lines)
    }
}

// MARK: - Fallback System Fonts
extension Font {
    /// iOS System Fallback fonts when custom fonts are unavailable
    struct SystemFallback {
        /// Large Title (34pt, Bold)
        static let largeTitle = Font.system(size: 34, weight: .bold)

        /// Title (28pt, Bold)
        static let title = Font.system(size: 28, weight: .bold)

        /// Title 2 (22pt, Bold)
        static let title2 = Font.system(size: 22, weight: .bold)

        /// Body (17pt, Regular)
        static let body = Font.system(size: 17, weight: .regular)

        /// Caption (13pt, Regular)
        static let caption = Font.system(size: 13, weight: .regular)
    }
}

// MARK: - Font Registration Helper
/// Helper to check if custom fonts are loaded
struct WellnessFontLoader {
    /// Check if Lora font family is available
    static var isLoraAvailable: Bool {
        UIFont.familyNames.contains { $0.contains("Lora") }
    }

    /// Check if Raleway font family is available
    static var isRalewayAvailable: Bool {
        UIFont.familyNames.contains { $0.contains("Raleway") }
    }

    /// Check if all wellness fonts are available
    static var areAllFontsAvailable: Bool {
        isLoraAvailable && isRalewayAvailable
    }

    /// Get list of available font families (for debugging)
    static var availableFamilies: [String] {
        UIFont.familyNames.sorted()
    }

    /// Print font status to console (useful for debugging)
    static func printFontStatus() {
        print("=== Wellness Font Status ===")
        print("Lora available: \(isLoraAvailable)")
        print("Raleway available: \(isRalewayAvailable)")
        print("All fonts loaded: \(areAllFontsAvailable)")

        if !areAllFontsAvailable {
            print("⚠️ Using SF Pro system fonts as fallback")
        } else {
            print("✓ All wellness fonts loaded successfully")
        }
    }
}
