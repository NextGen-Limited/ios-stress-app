import Testing
@testable import StressMonitor

/// Pins the Phase 3 auth/chat-availability contracts:
/// - `SupabaseSecrets.guestJWT` stays reachable under DEBUG (Task 1, D-02)
/// - `ChatAvailability` is the single source of truth for the v1 chat gate (Task 2, D-03)
/// - `SupabaseConfig.isConfigured` rejects the masked anon-key fallback (Task 2)
///
/// The test target always compiles under DEBUG (`SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG`),
/// so these tests exercise the DEBUG branch of every `#if DEBUG`-gated symbol.
struct ChatAvailabilityTests {

    // MARK: - Task 1: #if DEBUG wrap did not remove the local-dev fallback (D-01, D-02)

    @Test("DEBUG build still resolves the guest JWT fallback after the #if DEBUG wrap")
    func debugBuildStillCompilesSupabaseSecrets() {
        #expect(SupabaseSecrets.guestJWT.isEmpty == false)
    }

    // MARK: - Task 2: ChatAvailability single source of truth + honest isConfigured (D-03, AUTH-02)

    @Test("ChatAvailability exposes enabled/disabled states and resolves .enabled under DEBUG")
    func chatAvailabilityContract() {
        #expect(ChatAvailability.current == .enabled)
        #expect(ChatAvailability.disabled(reason: .comingSoon) == .disabled(reason: .comingSoon))
    }

    @Test("SupabaseConfig rejects masked and asterisk-only anon keys")
    func isConfiguredRejectsMaskedFallback() {
        #expect(SupabaseConfig.isMaskedPlaceholder(SupabaseConfig.maskedFallback))
        #expect(SupabaseConfig.isMaskedPlaceholder("****"))
        #expect(!SupabaseConfig.isMaskedPlaceholder("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.realkey"))
    }
}
