import Testing
@testable import StressMonitor

/// Regression gate for the CI provisioning path. `GoogleService-Info.plist` is
/// gitignored, so a build that never recreates it ships with Firebase silently
/// unconfigured — anonymous auth, AI Chat, credits, the IAP grant, and Google
/// Sign-In all dead with no build-time signal. Pinning
/// `FirebaseBootstrap.state` in the test host turns that class of failure into
/// a red test instead of a dead TestFlight build.
@Suite("Firebase Bootstrap")
struct FirebaseBootstrapTests {

    @Test("the test host bundle carries GoogleService-Info.plist, so bootstrap reports .configured")
    func testHostIsConfigured() {
        #expect(
            FirebaseBootstrap.state == .configured,
            "GoogleService-Info.plist is missing from the test host bundle. Restore it locally or run ci_scripts/provision_firebase_config.sh."
        )
    }

    @Test("bootstrap() returns .configured when the plist is present")
    func bootstrapReturnsConfigured() {
        #expect(
            FirebaseBootstrap.bootstrap() == .configured,
            "GoogleService-Info.plist is missing from the test host bundle. Restore it locally or run ci_scripts/provision_firebase_config.sh."
        )
    }

    @Test("a repeat bootstrap() is a no-op that returns the already-recorded state")
    func repeatBootstrapIsIdempotent() {
        let first = FirebaseBootstrap.bootstrap()
        let second = FirebaseBootstrap.bootstrap()

        #expect(first == second)
        #expect(FirebaseBootstrap.state == second)
    }
}
