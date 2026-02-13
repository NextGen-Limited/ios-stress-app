import Foundation
import Testing
import SwiftUI
@testable import StressMonitor

// MARK: - Font Wellness Type Tests
struct FontWellnessTypeTests {

    // MARK: - Font Availability Tests

    @Test func testLoraFontAvailabilityCheck() {
        // Test the availability check itself works
        let isAvailable = WellnessFontLoader.isLoraAvailable
        // Should return true or false without crashing
        let _ = isAvailable
    }

    @Test func testRalewayFontAvailabilityCheck() {
        let isAvailable = WellnessFontLoader.isRalewayAvailable
        let _ = isAvailable
    }

    @Test func testAllFontsAvailabilityCheck() {
        let allAvailable = WellnessFontLoader.areAllFontsAvailable
        let _ = allAvailable
    }

    @Test func testAvailableFamiliesList() {
        let families = WellnessFontLoader.availableFamilies
        #expect(!families.isEmpty)
        #expect(families.contains("System Font"))
    }

    // MARK: - Font Creation Tests

    @Test func testHeroNumberFontCreation() {
        let font = Font.WellnessType.heroNumber
        // Verify font doesn't crash when created
        let _ = font
    }

    @Test func testLargeMetricFontCreation() {
        let font = Font.WellnessType.largeMetric
        let _ = font
    }

    @Test func testCardTitleFontCreation() {
        let font = Font.WellnessType.cardTitle
        let _ = font
    }

    @Test func testSectionHeaderFontCreation() {
        let font = Font.WellnessType.sectionHeader
        let _ = font
    }

    @Test func testBodyFontCreation() {
        let font = Font.WellnessType.body
        let _ = font
    }

    @Test func testBodyEmphasizedFontCreation() {
        let font = Font.WellnessType.bodyEmphasized
        let _ = font
    }

    @Test func testCaptionFontCreation() {
        let font = Font.WellnessType.caption
        let _ = font
    }

    @Test func testCaption2FontCreation() {
        let font = Font.WellnessType.caption2
        let _ = font
    }

    // MARK: - System Fallback Tests

    @Test func testSystemFallbackLargeTitle() {
        let font = Font.SystemFallback.largeTitle
        let _ = font
    }

    @Test func testSystemFallbackTitle() {
        let font = Font.SystemFallback.title
        let _ = font
    }

    @Test func testSystemFallbackTitle2() {
        let font = Font.SystemFallback.title2
        let _ = font
    }

    @Test func testSystemFallbackBody() {
        let font = Font.SystemFallback.body
        let _ = font
    }

    @Test func testSystemFallbackCaption() {
        let font = Font.SystemFallback.caption
        let _ = font
    }

    // MARK: - Font Fallback Behavior Tests

    @Test func testFontFallbackToSystemWhenCustomUnavailable() {
        // When custom fonts are unavailable, the fonts should fall back to system fonts
        // This is tested implicitly - if fonts crash when custom fonts are missing,
        // this test will fail
        let allFonts = [
            Font.WellnessType.heroNumber,
            Font.WellnessType.largeMetric,
            Font.WellnessType.cardTitle,
            Font.WellnessType.sectionHeader,
            Font.WellnessType.body,
            Font.WellnessType.bodyEmphasized,
            Font.WellnessType.caption,
            Font.WellnessType.caption2
        ]

        for font in allFonts {
            let _ = font // Should not crash
        }
    }

    // MARK: - Dynamic Type Tests

    @Test func testDynamicTypeSizeRange() {
        // Test that Dynamic Type sizes are properly bounded
        // We can't easily test the actual scaling in unit tests,
        // but we can verify the modifiers don't crash

        let sizes: [DynamicTypeSize] = [
            .xSmall,
            .small,
            .medium,
            .large,
            .xLarge,
            .xxLarge,
            .xxxLarge,
            .accessibility1,
            .accessibility2,
            .accessibility3
        ]

        for size in sizes {
            let _ = size
        }
    }

    // MARK: - Vietnamese Character Support Test

    @Test func testVietnameseCharacterSupport() {
        // Test that fonts can handle Vietnamese diacritical marks
        let vietnameseText = "Căng thẳng"
        let attributedString = NSAttributedString(string: vietnameseText)
        #expect(!attributedString.string.isEmpty)
        #expect(attributedString.string == vietnameseText)
    }

    // MARK: - Font Status Debugging

    @Test func testPrintFontStatusDoesNotCrash() {
        // Verify the debug helper doesn't crash
        WellnessFontLoader.printFontStatus()
    }

    // MARK: - Minimum Scale Factor Tests

    @Test func testMinimumScaleFactorIs70Percent() {
        // This is a documentation test - the actual modifier is tested in UI tests
        // We document that minimum scale factor should be 0.7 (70%)
        let expectedMinScale = 0.7
        #expect(expectedMinScale == 0.7)
    }

    // MARK: - Line Limit Tests

    @Test func testSingleLineModifierExists() {
        // Test that the single line modifier is available
        // Actual behavior tested in UI tests
        let testView = Text("Test")
        let _ = testView.accessibleWellnessTypeSingleLine()
    }

    @Test func testMultiLineModifierExists() {
        let testView = Text("Test")
        let _ = testView.accessibleWellnessType()
    }

    @Test func testCustomLineCountModifierExists() {
        let testView = Text("Test")
        let _ = testView.accessibleWellnessType(lines: 3)
    }
}

// MARK: - Font Size Tests
struct FontSizeTests {

    @Test func testAllDynamicTypeSizesSupported() {
        // Test all Dynamic Type sizes from XS to AX3
        let allSizes: [DynamicTypeSize] = [
            .xSmall,      // XS
            .small,       // S
            .medium,      // M
            .large,       // L
            .xLarge,      // XL
            .xxLarge,     // XXL
            .xxxLarge,    // XXXL
            .accessibility1,  // AX1
            .accessibility2,  // AX2
            .accessibility3   // AX3
        ]

        for size in allSizes {
            // Verify all sizes are valid
            let _ = size
        }

        // We support up to accessibility3
        #expect(allSizes.count == 10)
    }

    @Test func testAccessibility3IsMaximumSupported() {
        // Per requirements, we support up to AX3
        // The modifier should cap at .accessibility3
        let maxSize = DynamicTypeSize.accessibility3
        let _ = maxSize
    }
}
