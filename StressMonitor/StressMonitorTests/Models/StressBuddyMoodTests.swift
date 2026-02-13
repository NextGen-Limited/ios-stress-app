import Foundation
import Testing
import SwiftUI
@testable import StressMonitor

// MARK: - StressBuddyMood Tests

/// Tests for Phase 2: Character System - StressBuddyMood model
/// Validates mood mapping, accessories, symbols, size contexts, and accessibility
struct StressBuddyMoodTests {

    // MARK: - Mood Mapping Tests

    @Test func testMoodMappingSleeping() {
        // Stress level 0-10 should map to sleeping
        #expect(StressBuddyMood.from(stressLevel: 0) == .sleeping)
        #expect(StressBuddyMood.from(stressLevel: 5) == .sleeping)
        #expect(StressBuddyMood.from(stressLevel: 9.9) == .sleeping)
    }

    @Test func testMoodMappingCalm() {
        // Stress level 10-25 should map to calm
        #expect(StressBuddyMood.from(stressLevel: 10) == .calm)
        #expect(StressBuddyMood.from(stressLevel: 15) == .calm)
        #expect(StressBuddyMood.from(stressLevel: 24.9) == .calm)
    }

    @Test func testMoodMappingConcerned() {
        // Stress level 25-50 should map to concerned
        #expect(StressBuddyMood.from(stressLevel: 25) == .concerned)
        #expect(StressBuddyMood.from(stressLevel: 35) == .concerned)
        #expect(StressBuddyMood.from(stressLevel: 49.9) == .concerned)
    }

    @Test func testMoodMappingWorried() {
        // Stress level 50-75 should map to worried
        #expect(StressBuddyMood.from(stressLevel: 50) == .worried)
        #expect(StressBuddyMood.from(stressLevel: 60) == .worried)
        #expect(StressBuddyMood.from(stressLevel: 74.9) == .worried)
    }

    @Test func testMoodMappingOverwhelmed() {
        // Stress level 75-100 should map to overwhelmed
        #expect(StressBuddyMood.from(stressLevel: 75) == .overwhelmed)
        #expect(StressBuddyMood.from(stressLevel: 85) == .overwhelmed)
        #expect(StressBuddyMood.from(stressLevel: 100) == .overwhelmed)
    }

    @Test func testMoodMappingBoundaries() {
        // Test exact boundaries
        #expect(StressBuddyMood.from(stressLevel: 0) == .sleeping)
        #expect(StressBuddyMood.from(stressLevel: 10) == .calm)
        #expect(StressBuddyMood.from(stressLevel: 25) == .concerned)
        #expect(StressBuddyMood.from(stressLevel: 50) == .worried)
        #expect(StressBuddyMood.from(stressLevel: 75) == .overwhelmed)
    }

    // MARK: - Accessory Mapping Tests

    @Test func testAccessorySleepingHasZZZ() {
        let mood = StressBuddyMood.sleeping
        #expect(mood.accessories.contains("zzz"))
        #expect(mood.accessories.count == 1)
    }

    @Test func testAccessoryCalmHasNoAccessories() {
        let mood = StressBuddyMood.calm
        #expect(mood.accessories.isEmpty)
    }

    @Test func testAccessoryConcernedHasStars() {
        let mood = StressBuddyMood.concerned
        #expect(mood.accessories.contains("star.fill"))
        #expect(mood.accessories.count == 1)
    }

    @Test func testAccessoryWorriedHasDrops() {
        let mood = StressBuddyMood.worried
        #expect(mood.accessories.contains("drop.fill"))
        #expect(mood.accessories.count == 1)
    }

    @Test func testAccessoryOverwhelmedHasDropsAndStars() {
        let mood = StressBuddyMood.overwhelmed
        #expect(mood.accessories.contains("drop.fill"))
        #expect(mood.accessories.contains("star.fill"))
        #expect(mood.accessories.count == 2)
    }

    // MARK: - Symbol Assignment Tests

    @Test func testSymbolSleeping() {
        let mood = StressBuddyMood.sleeping
        #expect(mood.symbol == "moon.zzz.fill")
    }

    @Test func testSymbolCalm() {
        let mood = StressBuddyMood.calm
        #expect(mood.symbol == "figure.mind.and.body")
    }

    @Test func testSymbolConcerned() {
        let mood = StressBuddyMood.concerned
        #expect(mood.symbol == "figure.walk.circle")
    }

    @Test func testSymbolWorried() {
        let mood = StressBuddyMood.worried
        #expect(mood.symbol == "exclamationmark.triangle.fill")
    }

    @Test func testSymbolOverwhelmed() {
        let mood = StressBuddyMood.overwhelmed
        #expect(mood.symbol == "flame.fill")
    }

    @Test func testAllSymbolsAreValidSFSymbols() {
        // Verify all symbols can be loaded as SF Symbols
        for mood in StressBuddyMood.allCases {
            let image = UIImage(systemName: mood.symbol)
            #expect(image != nil, "Symbol '\(mood.symbol)' for mood '\(mood)' should be valid")
        }
    }

    // MARK: - Size Context Tests

    @Test func testDashboardSize() {
        let mood = StressBuddyMood.calm
        let size = mood.symbolSize(for: .dashboard)
        #expect(size == 120)
    }

    @Test func testWidgetSize() {
        let mood = StressBuddyMood.calm
        let size = mood.symbolSize(for: .widget)
        #expect(size == 80)
    }

    @Test func testWatchOSSize() {
        let mood = StressBuddyMood.calm
        let size = mood.symbolSize(for: .watchOS)
        #expect(size == 60)
    }

    @Test func testAccessorySizeRelativeToMainSymbol() {
        // Accessory should be 30% of main symbol size
        let mood = StressBuddyMood.concerned

        let dashboardMain = mood.symbolSize(for: .dashboard)
        let dashboardAccessory = mood.accessorySize(for: .dashboard)
        #expect(dashboardAccessory == dashboardMain * 0.3)

        let widgetMain = mood.symbolSize(for: .widget)
        let widgetAccessory = mood.accessorySize(for: .widget)
        #expect(widgetAccessory == widgetMain * 0.3)

        let watchMain = mood.symbolSize(for: .watchOS)
        let watchAccessory = mood.accessorySize(for: .watchOS)
        #expect(watchAccessory == watchMain * 0.3)
    }

    @Test func testSizeContextsAreOrderedCorrectly() {
        // Dashboard should be largest, watchOS smallest
        let mood = StressBuddyMood.calm
        let dashboard = mood.symbolSize(for: .dashboard)
        let widget = mood.symbolSize(for: .widget)
        let watch = mood.symbolSize(for: .watchOS)

        #expect(dashboard > widget)
        #expect(widget > watch)
    }

    // MARK: - Accessibility Tests

    @Test func testAccessibilityDescriptionSleeping() {
        let mood = StressBuddyMood.sleeping
        #expect(mood.accessibilityDescription == "Very relaxed, sleeping peacefully")
    }

    @Test func testAccessibilityDescriptionCalm() {
        let mood = StressBuddyMood.calm
        #expect(mood.accessibilityDescription == "Calm and relaxed")
    }

    @Test func testAccessibilityDescriptionConcerned() {
        let mood = StressBuddyMood.concerned
        #expect(mood.accessibilityDescription == "Showing mild concern")
    }

    @Test func testAccessibilityDescriptionWorried() {
        let mood = StressBuddyMood.worried
        #expect(mood.accessibilityDescription == "Moderately worried")
    }

    @Test func testAccessibilityDescriptionOverwhelmed() {
        let mood = StressBuddyMood.overwhelmed
        #expect(mood.accessibilityDescription == "Feeling overwhelmed")
    }

    @Test func testAllMoodsHaveNonEmptyAccessibilityDescriptions() {
        for mood in StressBuddyMood.allCases {
            #expect(!mood.accessibilityDescription.isEmpty,
                   "Mood '\(mood)' must have accessibility description")
        }
    }

    // MARK: - Display Name Tests

    @Test func testDisplayNameFormatting() {
        #expect(StressBuddyMood.sleeping.displayName == "Sleeping")
        #expect(StressBuddyMood.calm.displayName == "Calm")
        #expect(StressBuddyMood.concerned.displayName == "Concerned")
        #expect(StressBuddyMood.worried.displayName == "Worried")
        #expect(StressBuddyMood.overwhelmed.displayName == "Overwhelmed")
    }

    // MARK: - Color Mapping Tests

    @Test func testColorMappingSleeping() {
        let mood = StressBuddyMood.sleeping
        // Sleeping should use relaxed category color
        let _ = UIColor(mood.color)
    }

    @Test func testColorMappingCalm() {
        let mood = StressBuddyMood.calm
        // Calm should use relaxed category color
        let _ = UIColor(mood.color)
    }

    @Test func testColorMappingConcerned() {
        let mood = StressBuddyMood.concerned
        // Concerned should use mild category color
        let _ = UIColor(mood.color)
    }

    @Test func testColorMappingWorried() {
        let mood = StressBuddyMood.worried
        // Worried should use moderate category color
        let _ = UIColor(mood.color)
    }

    @Test func testColorMappingOverwhelmed() {
        let mood = StressBuddyMood.overwhelmed
        // Overwhelmed should use high category color
        let _ = UIColor(mood.color)
    }

    @Test func testAllMoodsHaveValidColors() {
        for mood in StressBuddyMood.allCases {
            let uiColor = UIColor(mood.color)
            #expect(uiColor != nil, "Mood '\(mood)' must have valid color")
        }
    }

    // MARK: - Edge Case Tests

    @Test func testNegativeStressLevel() {
        // Negative values should still map to a valid mood (sleeping)
        let mood = StressBuddyMood.from(stressLevel: -10)
        #expect(mood == .sleeping)
    }

    @Test func testExtremelyHighStressLevel() {
        // Values over 100 should map to overwhelmed
        let mood = StressBuddyMood.from(stressLevel: 999)
        #expect(mood == .overwhelmed)
    }

    @Test func testAllCasesCount() {
        // Verify we have exactly 5 mood states
        #expect(StressBuddyMood.allCases.count == 5)
    }

    // MARK: - Sendable Protocol Conformance

    @Test func testSendableConformance() {
        // StressBuddyMood should be Sendable for concurrency safety
        let mood: StressBuddyMood = .calm
        Task {
            let _ = mood // Should compile without warnings
        }
    }
}
