import Testing
@testable import StressMonitor

/// Pins the Phase 1 decision D-02: AI Chat is reachable in every build
/// configuration — real Firebase auth shipped in v1.1 Phase 01, so
/// `ChatAvailability.current` resolves `.enabled` unconditionally and the
/// chat entry points (`ActionView` CTA, `SettingsView` chat row) stay open.
struct ChatAvailabilityTests {

    @Test("ChatAvailability resolves .enabled unconditionally (D-02)")
    func chatAvailabilityIsEnabled() {
        #expect(ChatAvailability.current == .enabled)
        #expect(ChatAvailability.current.isAvailable)
    }
}
