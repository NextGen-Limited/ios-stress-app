import SwiftUI

// MARK: - Wellness Typography System
extension Font {
    /// Wellness-themed type styles backed by SF Pro.
    ///
    /// Public API is unchanged from the prior Roboto-backed implementation;
    /// internals now resolve to system fonts (SF Pro / SF Pro Rounded) so the
    /// app ships without bundled font assets.
    struct WellnessType {
        // MARK: - Heading Fonts (SF Pro Rounded / SF Pro)

        /// Hero number for stress ring center (SF Pro Rounded 72pt bold)
        static var heroNumber: Font { .system(size: 72, weight: .bold, design: .rounded) }

        /// Large metric display (SF Pro Rounded 48pt bold)
        static var largeMetric: Font { .system(size: 48, weight: .bold, design: .rounded) }

        /// Card titles (SF Pro 28pt bold)
        static var cardTitle: Font { .system(size: 28, weight: .bold, design: .default) }

        /// Section headers (SF Pro 22pt semibold)
        static var sectionHeader: Font { .system(size: 22, weight: .semibold, design: .default) }

        // MARK: - Body Fonts (SF Pro)

        /// Primary content (SF Pro 17pt regular)
        static var body: Font { .system(size: 17, weight: .regular, design: .default) }

        /// Emphasized text (SF Pro 17pt semibold)
        static var bodyEmphasized: Font { .system(size: 17, weight: .semibold, design: .default) }

        /// Captions and labels (SF Pro 13pt regular)
        static var caption: Font { .system(size: 13, weight: .regular, design: .default) }

        /// Tiny text (SF Pro 11pt regular)
        static var caption2: Font { .system(size: 11, weight: .regular, design: .default) }
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
    /// Roboto is no longer bundled; wellness styles resolve to SF Pro.
    /// Kept for compatibility with existing call sites that gate on font availability.
    static var isRobotoAvailable: Bool { false }

    /// Check if Lora font family is available (legacy compatibility)
    static var isLoraAvailable: Bool {
        UIFont.familyNames.contains { $0.contains("Lora") }
    }

    /// Check if Raleway font family is available (legacy compatibility)
    static var isRalewayAvailable: Bool {
        UIFont.familyNames.contains { $0.contains("Raleway") }
    }

    /// Check if all wellness fonts are available
    static var areAllFontsAvailable: Bool {
        isRobotoAvailable
    }

    /// Get list of available font families (for debugging)
    static var availableFamilies: [String] {
        UIFont.familyNames.sorted()
    }

    /// Print font status to console (useful for debugging)
    static func printFontStatus() {
        print("=== Wellness Font Status ===")
        print("Roboto available: \(isRobotoAvailable)")
        print("All fonts loaded: \(areAllFontsAvailable)")

        if !areAllFontsAvailable {
            print("⚠️ Using SF Pro system fonts as fallback")
        } else {
            print("✓ All wellness fonts loaded successfully")
        }
    }
}
