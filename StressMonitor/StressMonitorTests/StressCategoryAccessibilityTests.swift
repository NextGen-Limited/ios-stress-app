import Testing
@testable import StressMonitor

@Suite("StressCategory accessibility label/hint agreement")
struct StressCategoryAccessibilityTests {

    @Test("accessibilityDescription names every tier the same as displayName", arguments: StressCategory.allCases)
    func accessibilityDescriptionMatchesDisplayName(category: StressCategory) {
        #expect(category.accessibilityDescription.hasPrefix(category.displayName))
    }

    @Test("iOS boundary contract the watch StressCategory.category(for:) must mirror exactly")
    func iOSBoundaryContract() {
        #expect(StressResult.category(for: 24.9) == .relaxed)
        #expect(StressResult.category(for: 25.0) == .mild)
        #expect(StressResult.category(for: 49.9) == .mild)
        #expect(StressResult.category(for: 50.0) == .moderate)
        #expect(StressResult.category(for: 74.9) == .moderate)
        #expect(StressResult.category(for: 75.0) == .high)
        #expect(StressResult.category(for: 89.9) == .high)
        #expect(StressResult.category(for: 90.0) == .severe)
    }
}
