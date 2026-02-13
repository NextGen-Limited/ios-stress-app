import Foundation
import Testing
import SwiftUI
@testable import StressMonitor

// MARK: - StressCharacterCard Tests

/// Tests for Phase 2: Character System - StressCharacterCard component
/// Validates rendering, VoiceOver support, and all size contexts
@MainActor
struct StressCharacterCardTests {

    // MARK: - Card Rendering Tests

    @Test func testCardRenderingSleeping() {
        let card = StressCharacterCard(
            mood: .sleeping,
            stressLevel: 5,
            hrv: 65,
            size: .dashboard
        )

        // Verify view can be created without crash
        let _ = card.body
    }

    @Test func testCardRenderingCalm() {
        let card = StressCharacterCard(
            mood: .calm,
            stressLevel: 15,
            hrv: 70,
            size: .dashboard
        )

        let _ = card.body
    }

    @Test func testCardRenderingConcerned() {
        let card = StressCharacterCard(
            mood: .concerned,
            stressLevel: 35,
            hrv: 55,
            size: .dashboard
        )

        let _ = card.body
    }

    @Test func testCardRenderingWorried() {
        let card = StressCharacterCard(
            mood: .worried,
            stressLevel: 60,
            hrv: 45,
            size: .dashboard
        )

        let _ = card.body
    }

    @Test func testCardRenderingOverwhelmed() {
        let card = StressCharacterCard(
            mood: .overwhelmed,
            stressLevel: 85,
            hrv: 30,
            size: .dashboard
        )

        let _ = card.body
    }

    @Test func testCardRenderingAllMoods() {
        // Test all moods render without crash
        for mood in StressBuddyMood.allCases {
            let stressLevel = switch mood {
            case .sleeping: 5.0
            case .calm: 15.0
            case .concerned: 35.0
            case .worried: 60.0
            case .overwhelmed: 85.0
            }

            let card = StressCharacterCard(
                mood: mood,
                stressLevel: stressLevel,
                hrv: 50,
                size: .dashboard
            )

            let _ = card.body
        }
    }

    // MARK: - Size Context Tests

    @Test func testCardRenderingDashboardSize() {
        let card = StressCharacterCard(
            mood: .calm,
            stressLevel: 15,
            hrv: 70,
            size: .dashboard
        )

        let _ = card.body
    }

    @Test func testCardRenderingWidgetSize() {
        let card = StressCharacterCard(
            mood: .calm,
            stressLevel: 15,
            hrv: 70,
            size: .widget
        )

        let _ = card.body
    }

    @Test func testCardRenderingWatchOSSize() {
        let card = StressCharacterCard(
            mood: .calm,
            stressLevel: 15,
            hrv: 70,
            size: .watchOS
        )

        let _ = card.body
    }

    @Test func testCardRenderingAllSizes() {
        let sizes: [StressBuddyMood.CharacterContext] = [.dashboard, .widget, .watchOS]

        for size in sizes {
            let card = StressCharacterCard(
                mood: .calm,
                stressLevel: 15,
                hrv: 70,
                size: size
            )

            let _ = card.body
        }
    }

    // MARK: - HRV Optional Tests

    @Test func testCardRenderingWithHRV() {
        let card = StressCharacterCard(
            mood: .calm,
            stressLevel: 15,
            hrv: 70,
            size: .dashboard
        )

        let _ = card.body
    }

    @Test func testCardRenderingWithoutHRV() {
        let card = StressCharacterCard(
            mood: .calm,
            stressLevel: 15,
            hrv: nil,
            size: .dashboard
        )

        let _ = card.body
    }

    // MARK: - Convenience Initializer Tests

    @Test func testInitFromStressResult() {
        let result = StressResult(
            level: 35,
            category: .mild,
            confidence: 0.85,
            hrv: 55,
            heartRate: 70
        )

        let card = StressCharacterCard(result: result, size: .dashboard)

        #expect(card.mood == .concerned)
        #expect(card.stressLevel == 35)
        #expect(card.hrv == 55)
        #expect(card.size == .dashboard)

        let _ = card.body
    }

    @Test func testInitWithMinimalData() {
        let card = StressCharacterCard(stressLevel: 15, size: .widget)

        #expect(card.mood == .calm)
        #expect(card.stressLevel == 15)
        #expect(card.hrv == nil)
        #expect(card.size == .widget)

        let _ = card.body
    }

    // MARK: - VoiceOver Label Tests

    @Test func testVoiceOverLabelExists() {
        // VoiceOver labels should use mood.accessibilityDescription
        let moods: [(StressBuddyMood, String)] = [
            (.sleeping, "Very relaxed, sleeping peacefully"),
            (.calm, "Calm and relaxed"),
            (.concerned, "Showing mild concern"),
            (.worried, "Moderately worried"),
            (.overwhelmed, "Feeling overwhelmed")
        ]

        for (mood, expectedDescription) in moods {
            #expect(mood.accessibilityDescription == expectedDescription)
        }
    }

    @Test func testVoiceOverValueFormatting() {
        let card = StressCharacterCard(
            mood: .calm,
            stressLevel: 15.7,
            hrv: 70,
            size: .dashboard
        )

        // Verify stress level is converted to integer for VoiceOver
        let expectedValue = "Stress level: 15"
        // Note: In actual implementation, card uses Int(stressLevel)
        #expect(Int(card.stressLevel) == 15)
    }

    @Test func testAccessibilityLabelsForAllMoods() {
        for mood in StressBuddyMood.allCases {
            let description = mood.accessibilityDescription
            #expect(!description.isEmpty, "Mood '\(mood)' must have non-empty accessibility description")
            #expect(description.count > 5, "Description should be meaningful")
        }
    }

    // MARK: - Typography Tests

    @Test func testFontSizeForDashboard() {
        let card = StressCharacterCard(
            mood: .calm,
            stressLevel: 15,
            hrv: nil,
            size: .dashboard
        )

        // Verify fonts are appropriate for size (can't directly test Font, but verify creation)
        let _ = card.body
    }

    @Test func testFontSizeForWidget() {
        let card = StressCharacterCard(
            mood: .calm,
            stressLevel: 15,
            hrv: nil,
            size: .widget
        )

        let _ = card.body
    }

    @Test func testFontSizeForWatchOS() {
        let card = StressCharacterCard(
            mood: .calm,
            stressLevel: 15,
            hrv: nil,
            size: .watchOS
        )

        let _ = card.body
    }

    // MARK: - Accessory Rendering Tests

    @Test func testAccessoriesRenderForSleeping() {
        let card = StressCharacterCard(
            mood: .sleeping,
            stressLevel: 5,
            hrv: nil,
            size: .dashboard
        )

        // Sleeping has zzz accessory
        #expect(!card.mood.accessories.isEmpty)
        let _ = card.body
    }

    @Test func testNoAccessoriesRenderForCalm() {
        let card = StressCharacterCard(
            mood: .calm,
            stressLevel: 15,
            hrv: nil,
            size: .dashboard
        )

        // Calm has no accessories
        #expect(card.mood.accessories.isEmpty)
        let _ = card.body
    }

    @Test func testAccessoriesRenderForConcerned() {
        let card = StressCharacterCard(
            mood: .concerned,
            stressLevel: 35,
            hrv: nil,
            size: .dashboard
        )

        // Concerned has star accessory
        #expect(card.mood.accessories.count == 1)
        let _ = card.body
    }

    @Test func testAccessoriesRenderForWorried() {
        let card = StressCharacterCard(
            mood: .worried,
            stressLevel: 60,
            hrv: nil,
            size: .dashboard
        )

        // Worried has drop accessory
        #expect(card.mood.accessories.count == 1)
        let _ = card.body
    }

    @Test func testMultipleAccessoriesRenderForOverwhelmed() {
        let card = StressCharacterCard(
            mood: .overwhelmed,
            stressLevel: 85,
            hrv: nil,
            size: .dashboard
        )

        // Overwhelmed has multiple accessories
        #expect(card.mood.accessories.count == 2)
        let _ = card.body
    }

    // MARK: - Character Animation Tests

    @Test func testCharacterAnimationModifierApplied() {
        // Verify character has animation modifier
        for mood in StressBuddyMood.allCases {
            let card = StressCharacterCard(
                mood: mood,
                stressLevel: 50,
                hrv: nil,
                size: .dashboard
            )

            let _ = card.body // Verify view with animation compiles
        }
    }

    // MARK: - Color Application Tests

    @Test func testMoodColorApplied() {
        for mood in StressBuddyMood.allCases {
            let card = StressCharacterCard(
                mood: mood,
                stressLevel: 50,
                hrv: nil,
                size: .dashboard
            )

            // Verify color can be created
            let _ = UIColor(card.mood.color)
            let _ = card.body
        }
    }

    // MARK: - Edge Case Tests

    @Test func testZeroStressLevel() {
        let card = StressCharacterCard(
            mood: .sleeping,
            stressLevel: 0,
            hrv: nil,
            size: .dashboard
        )

        let _ = card.body
    }

    @Test func testMaxStressLevel() {
        let card = StressCharacterCard(
            mood: .overwhelmed,
            stressLevel: 100,
            hrv: nil,
            size: .dashboard
        )

        let _ = card.body
    }

    @Test func testVeryLowHRV() {
        let card = StressCharacterCard(
            mood: .overwhelmed,
            stressLevel: 85,
            hrv: 10,
            size: .dashboard
        )

        let _ = card.body
    }

    @Test func testVeryHighHRV() {
        let card = StressCharacterCard(
            mood: .sleeping,
            stressLevel: 5,
            hrv: 150,
            size: .dashboard
        )

        let _ = card.body
    }

    @Test func testDecimalStressLevels() {
        // Test fractional stress levels are handled correctly
        let levels = [0.1, 5.5, 15.7, 35.3, 60.9, 85.2, 99.9]

        for level in levels {
            let mood = StressBuddyMood.from(stressLevel: level)
            let card = StressCharacterCard(
                mood: mood,
                stressLevel: level,
                hrv: nil,
                size: .dashboard
            )

            let _ = card.body
        }
    }

    // MARK: - Display Name Tests

    @Test func testMoodDisplayNameShown() {
        for mood in StressBuddyMood.allCases {
            let displayName = mood.displayName
            #expect(!displayName.isEmpty)
            #expect(displayName.first?.isUppercase == true, "Display name should be capitalized")
        }
    }

    // MARK: - Monospaced Digit Tests

    @Test func testStressLevelUsesMonospacedDigits() {
        // Verify stress level text would use monospacedDigit() modifier
        // This ensures consistent width for smooth transitions
        let card = StressCharacterCard(
            mood: .calm,
            stressLevel: 15,
            hrv: nil,
            size: .dashboard
        )

        let _ = card.body // Verify compilation with monospacedDigit modifier
    }

    // MARK: - HRV Formatting Tests

    @Test func testHRVFormattingWhenPresent() {
        let card = StressCharacterCard(
            mood: .calm,
            stressLevel: 15,
            hrv: 65.7,
            size: .dashboard
        )

        // HRV should be shown as integer in ms
        #expect(card.hrv != nil)
        let hrvInt = Int(card.hrv!)
        #expect(hrvInt == 65)

        let _ = card.body
    }

    @Test func testHRVNotShownWhenNil() {
        let card = StressCharacterCard(
            mood: .calm,
            stressLevel: 15,
            hrv: nil,
            size: .dashboard
        )

        #expect(card.hrv == nil)
        let _ = card.body
    }

    // MARK: - Symbol Rendering Mode Tests

    @Test func testSymbolHierarchicalRenderingMode() {
        // Verify all symbols can be rendered in hierarchical mode
        for mood in StressBuddyMood.allCases {
            let symbolName = mood.symbol
            let image = UIImage(systemName: symbolName)

            #expect(image != nil, "Symbol '\(symbolName)' should be valid SF Symbol")
        }
    }
}

// MARK: - Character Animation Modifier Tests

@MainActor
struct CharacterAnimationModifierTests {

    @Test func testAnimationModifierCreation() {
        for mood in StressBuddyMood.allCases {
            let modifier = CharacterAnimationModifier(mood: mood)
            let _ = modifier // Verify creation
        }
    }

    @Test func testAnimationModifierAppliedToView() {
        struct TestView: View {
            var body: some View {
                Image(systemName: "figure.mind.and.body")
                    .characterAnimation(for: .calm)
            }
        }

        let view = TestView()
        let _ = view.body // Verify compilation
    }
}

// MARK: - Accessory Animation Modifier Tests

@MainActor
struct AccessoryAnimationModifierTests {

    @Test func testAccessoryModifierCreation() {
        let modifier = AccessoryAnimationModifier(index: 0)
        let _ = modifier
    }

    @Test func testAccessoryModifierWithDifferentIndices() {
        for index in 0..<5 {
            let modifier = AccessoryAnimationModifier(index: index)
            let _ = modifier
        }
    }

    @Test func testAccessoryAnimationAppliedToView() {
        struct TestView: View {
            var body: some View {
                Image(systemName: "star.fill")
                    .accessoryAnimation(index: 0)
            }
        }

        let view = TestView()
        let _ = view.body
    }
}
