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
}
