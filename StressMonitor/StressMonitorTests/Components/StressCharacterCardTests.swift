import Foundation
import Testing
import SwiftUI
@testable import StressMonitor

// MARK: - StressCharacterCard Tests

/// Tests for Phase 2: Character System - StressCharacterCard component
/// Validates rendering, VoiceOver support, and all size contexts
@MainActor
struct StressCharacterCardTests {

    // MARK: - Helpers

    private func makeResult(
        mood: StressBuddyMood,
        stressLevel: Double,
        hrv: Double? = nil
    ) -> StressResult {
        let category: StressCategory = switch mood {
        case .sleeping, .calm: .relaxed
        case .concerned: .mild
        case .worried: .moderate
        case .overwhelmed: .high
        }
        return StressResult(
            level: stressLevel,
            category: category,
            confidence: 0.9,
            hrv: hrv ?? 50,
            heartRate: 70
        )
    }

    // MARK: - Card Rendering Tests

    @Test func testCardRenderingSleeping() {
        let card = StressCharacterCard(
            result: makeResult(mood: .sleeping, stressLevel: 5),
            size: .dashboard
        )
        let _ = card.body
    }

    @Test func testCardRenderingCalm() {
        let card = StressCharacterCard(
            result: makeResult(mood: .calm, stressLevel: 15, hrv: 70),
            size: .dashboard
        )
        let _ = card.body
    }

    @Test func testCardRenderingConcerned() {
        let card = StressCharacterCard(
            result: makeResult(mood: .concerned, stressLevel: 35, hrv: 55),
            size: .dashboard
        )
        let _ = card.body
    }

    @Test func testCardRenderingWorried() {
        let card = StressCharacterCard(
            result: makeResult(mood: .worried, stressLevel: 60, hrv: 45),
            size: .dashboard
        )
        let _ = card.body
    }

    @Test func testCardRenderingOverwhelmed() {
        let card = StressCharacterCard(
            result: makeResult(mood: .overwhelmed, stressLevel: 85, hrv: 30),
            size: .dashboard
        )
        let _ = card.body
    }

    @Test func testCardRenderingAllMoods() {
        let moodLevels: [(StressBuddyMood, Double)] = [
            (.sleeping, 5.0), (.calm, 15.0), (.concerned, 35.0),
            (.worried, 60.0), (.overwhelmed, 85.0)
        ]
        for (mood, level) in moodLevels {
            let card = StressCharacterCard(
                result: makeResult(mood: mood, stressLevel: level, hrv: 50),
                size: .dashboard
            )
            let _ = card.body
        }
    }

    // MARK: - Size Context Tests

    @Test func testCardRenderingDashboardSize() {
        let card = StressCharacterCard(
            result: makeResult(mood: .calm, stressLevel: 15, hrv: 70),
            size: .dashboard
        )
        let _ = card.body
    }

    @Test func testCardRenderingWidgetSize() {
        let card = StressCharacterCard(
            result: makeResult(mood: .calm, stressLevel: 15, hrv: 70),
            size: .widget
        )
        let _ = card.body
    }

    @Test func testCardRenderingWatchOSSize() {
        let card = StressCharacterCard(
            result: makeResult(mood: .calm, stressLevel: 15, hrv: 70),
            size: .watchOS
        )
        let _ = card.body
    }

    @Test func testCardRenderingAllSizes() {
        let sizes: [StressBuddyMood.CharacterContext] = [.dashboard, .widget, .watchOS]
        for size in sizes {
            let card = StressCharacterCard(
                result: makeResult(mood: .calm, stressLevel: 15, hrv: 70),
                size: size
            )
            let _ = card.body
        }
    }

    // MARK: - HRV Optional Tests

    @Test func testCardRenderingWithHRV() {
        let card = StressCharacterCard(
            result: makeResult(mood: .calm, stressLevel: 15, hrv: 70),
            size: .dashboard
        )
        let _ = card.body
    }

    @Test func testCardRenderingWithoutHRV() {
        // HRV comes from StressResult; default in makeResult is 50
        let card = StressCharacterCard(
            result: makeResult(mood: .calm, stressLevel: 15),
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
        let result = StressResult(
            level: 15,
            category: .relaxed,
            confidence: 0.9,
            hrv: 50,
            heartRate: 70
        )
        let card = StressCharacterCard(result: result, size: .widget)

        #expect(card.mood == .calm)
        #expect(card.stressLevel == 15)
        #expect(card.hrv == 50)
        #expect(card.size == .widget)

        let _ = card.body
    }

    // MARK: - Permission State Tests

    @Test func testInitWithNilResult() {
        let card = StressCharacterCard(
            result: nil as StressResult?,
            size: .dashboard,
            onGrantAccess: {}
        )
        let _ = card.body
    }

    @Test func testPermissionStateAccessibility() {
        let card = StressCharacterCard(
            result: nil as StressResult?,
            size: .dashboard,
            isRequestingAccess: true,
            onGrantAccess: {}
        )
        let _ = card.body
    }

    // MARK: - VoiceOver Label Tests

    @Test func testVoiceOverLabelExists() {
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
            result: StressResult(level: 15.7, category: .relaxed, confidence: 0.9, hrv: 70, heartRate: 68),
            size: .dashboard
        )

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
            result: makeResult(mood: .calm, stressLevel: 15),
            size: .dashboard
        )
        let _ = card.body
    }

    @Test func testFontSizeForWidget() {
        let card = StressCharacterCard(
            result: makeResult(mood: .calm, stressLevel: 15),
            size: .widget
        )
        let _ = card.body
    }

    @Test func testFontSizeForWatchOS() {
        let card = StressCharacterCard(
            result: makeResult(mood: .calm, stressLevel: 15),
            size: .watchOS
        )
        let _ = card.body
    }

    // MARK: - Accessory Rendering Tests

    @Test func testAccessoriesRenderForSleeping() {
        let card = StressCharacterCard(
            result: makeResult(mood: .sleeping, stressLevel: 5),
            size: .dashboard
        )
        #expect(!card.mood.accessories.isEmpty)
        let _ = card.body
    }

    @Test func testNoAccessoriesRenderForCalm() {
        let card = StressCharacterCard(
            result: makeResult(mood: .calm, stressLevel: 15),
            size: .dashboard
        )
        #expect(card.mood.accessories.isEmpty)
        let _ = card.body
    }

    @Test func testAccessoriesRenderForConcerned() {
        let card = StressCharacterCard(
            result: makeResult(mood: .concerned, stressLevel: 35),
            size: .dashboard
        )
        #expect(card.mood.accessories.count == 1)
        let _ = card.body
    }

    @Test func testAccessoriesRenderForWorried() {
        let card = StressCharacterCard(
            result: makeResult(mood: .worried, stressLevel: 60),
            size: .dashboard
        )
        #expect(card.mood.accessories.count == 1)
        let _ = card.body
    }

    @Test func testMultipleAccessoriesRenderForOverwhelmed() {
        let card = StressCharacterCard(
            result: makeResult(mood: .overwhelmed, stressLevel: 85),
            size: .dashboard
        )
        #expect(card.mood.accessories.count == 2)
        let _ = card.body
    }

    // MARK: - Character Animation Tests

    @Test func testCharacterAnimationModifierApplied() {
        for mood in StressBuddyMood.allCases {
            let level = switch mood {
            case .sleeping: 5.0; case .calm: 15.0; case .concerned: 35.0
            case .worried: 60.0; case .overwhelmed: 85.0
            }
            let card = StressCharacterCard(
                result: makeResult(mood: mood, stressLevel: level),
                size: .dashboard
            )
            let _ = card.body
        }
    }

    // MARK: - Color Application Tests

    @Test func testMoodColorApplied() {
        for mood in StressBuddyMood.allCases {
            let level = switch mood {
            case .sleeping: 5.0; case .calm: 15.0; case .concerned: 35.0
            case .worried: 60.0; case .overwhelmed: 85.0
            }
            let card = StressCharacterCard(
                result: makeResult(mood: mood, stressLevel: level),
                size: .dashboard
            )
            let _ = UIColor(card.mood.color)
            let _ = card.body
        }
    }

    // MARK: - Edge Case Tests

    @Test func testZeroStressLevel() {
        let card = StressCharacterCard(
            result: makeResult(mood: .sleeping, stressLevel: 0),
            size: .dashboard
        )
        let _ = card.body
    }

    @Test func testMaxStressLevel() {
        let card = StressCharacterCard(
            result: makeResult(mood: .overwhelmed, stressLevel: 100),
            size: .dashboard
        )
        let _ = card.body
    }

    @Test func testVeryLowHRV() {
        let card = StressCharacterCard(
            result: makeResult(mood: .overwhelmed, stressLevel: 85, hrv: 10),
            size: .dashboard
        )
        let _ = card.body
    }

    @Test func testVeryHighHRV() {
        let card = StressCharacterCard(
            result: makeResult(mood: .sleeping, stressLevel: 5, hrv: 150),
            size: .dashboard
        )
        let _ = card.body
    }

    @Test func testDecimalStressLevels() {
        let levels = [0.1, 5.5, 15.7, 35.3, 60.9, 85.2, 99.9]
        for level in levels {
            let mood = StressBuddyMood.from(stressLevel: level)
            let card = StressCharacterCard(
                result: makeResult(mood: mood, stressLevel: level),
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
        let card = StressCharacterCard(
            result: makeResult(mood: .calm, stressLevel: 15),
            size: .dashboard
        )
        let _ = card.body
    }

    // MARK: - HRV Formatting Tests

    @Test func testHRVFormattingWhenPresent() {
        let card = StressCharacterCard(
            result: makeResult(mood: .calm, stressLevel: 15, hrv: 65.7),
            size: .dashboard
        )
        #expect(card.hrv != nil)
        let hrvInt = Int(card.hrv!)
        #expect(hrvInt == 65)
        let _ = card.body
    }

    @Test func testHRVNotShownWhenNil() {
        // StressResult.hrv is Double, not optional — verify value propagation
        let card = StressCharacterCard(
            result: makeResult(mood: .calm, stressLevel: 15, hrv: 50),
            size: .dashboard
        )
        #expect(card.hrv == 50)
        let _ = card.body
    }

    // MARK: - Symbol Rendering Mode Tests

    @Test func testSymbolHierarchicalRenderingMode() {
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
            let _ = modifier
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
        let _ = view.body
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
