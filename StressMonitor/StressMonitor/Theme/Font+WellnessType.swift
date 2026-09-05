import SwiftUI

// MARK: - Wellness Typography System
extension Font {
    /// Wellness-themed type styles backed by SF Pro system fonts.
    ///
    /// UI text uses SF Pro (`.default` design); character moments use
    /// SF Pro Rounded (`.rounded` design). No bundled font assets required.
    /// Text tokens are anchored to system text styles so they ride the
    /// Dynamic Type ramp through AX5; gauge numerals stay fixed and are
    /// labeled through accessibility values instead.
    struct WellnessType {
        // MARK: - Heading Fonts (SF Pro Rounded / SF Pro)

        /// Hero number for stress ring center (SF Pro Rounded 72pt bold) — gauge class, fixed by design
        static var heroNumber: Font { .system(size: 72, weight: .bold, design: .rounded) }

        /// Large metric display (SF Pro Rounded 48pt bold) — gauge class, fixed by design
        static var largeMetric: Font { .system(size: 48, weight: .bold, design: .rounded) }

        /// Card titles (28pt bold, rides the .title ramp)
        static var cardTitle: Font { .system(.title).weight(.bold) }

        /// Section headers (22pt semibold, rides the .title2 ramp)
        static var sectionHeader: Font { .system(.title2).weight(.semibold) }

        // MARK: - Body Fonts (SF Pro)

        /// Primary content (17pt regular, rides the .body ramp)
        static var body: Font { .system(.body) }

        /// Emphasized text (17pt semibold, rides the .headline ramp)
        static var bodyEmphasized: Font { .system(.headline) }

        /// Captions and labels (13pt regular, rides the .footnote ramp)
        static var caption: Font { .system(.footnote) }

        /// Tiny text (11pt regular, rides the .caption2 ramp)
        static var caption2: Font { .system(.caption2) }
    }
}

// MARK: - Fallback System Fonts
extension Font {
    /// iOS System Fallback fonts when custom fonts are unavailable
    struct SystemFallback {
        /// Large Title (34pt, Bold — rides the .largeTitle ramp)
        static let largeTitle = Font.system(.largeTitle).weight(.bold)

        /// Title (28pt, Bold — rides the .title ramp)
        static let title = Font.system(.title).weight(.bold)

        /// Title 2 (22pt, Bold — rides the .title2 ramp)
        static let title2 = Font.system(.title2).weight(.bold)

        /// Body (17pt, Regular — rides the .body ramp)
        static let body = Font.system(.body)

        /// Caption (13pt, Regular — rides the .footnote ramp)
        static let caption = Font.system(.footnote)
    }
}

// MARK: - Font Registration Helper
/// Helper to check if custom fonts are loaded (legacy compatibility).
/// All wellness styles resolve to SF Pro system fonts — no bundled assets.
struct WellnessFontLoader {
    /// Check if Lora font family is available (legacy compatibility)
    static var isLoraAvailable: Bool {
        UIFont.familyNames.contains { $0.contains("Lora") }
    }

    /// Check if Raleway font family is available (legacy compatibility)
    static var isRalewayAvailable: Bool {
        UIFont.familyNames.contains { $0.contains("Raleway") }
    }

    /// Check if all wellness fonts are available (always true — SF Pro is system-bundled)
    static var areAllFontsAvailable: Bool { true }

    /// Get list of available font families (for debugging)
    static var availableFamilies: [String] {
        UIFont.familyNames.sorted()
    }

    /// Print font status to console (useful for debugging)
    static func printFontStatus() {
        print("=== Wellness Font Status ===")
        print("All fonts loaded: \(areAllFontsAvailable)")
        print("✓ All wellness styles resolve to SF Pro system fonts")
    }
}
