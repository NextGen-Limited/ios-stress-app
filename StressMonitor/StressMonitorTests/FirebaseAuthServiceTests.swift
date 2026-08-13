import Foundation
import Testing
import UIKit
@testable import StressMonitor

/// Pins the `AuthServiceProtocol` seam so `FirebaseAuthService` can be
/// substituted by a non-Firebase double in `StressAPIClient`. The Firebase
/// Auth singleton (`Auth.auth()`) cannot be mocked without Firebase SDK test
/// utilities, so these tests assert the injectability contract and the
/// nil-safety of credential clearing rather than live Firebase behavior.
///
/// `FirebaseAuthService.init` is deliberately lazy (it does not touch
/// `Auth.auth()`), verified here so a future change cannot regress it.
@MainActor
struct FirebaseAuthServiceTests {

    // MARK: - Protocol conformance (compile-time)

    @Test("FirebaseAuthService conforms to AuthServiceProtocol")
    func firebaseAuthServiceConformsToAuthServiceProtocol() {
        let service: AuthServiceProtocol = FirebaseAuthService()
        #expect(service is FirebaseAuthService)
    }

    // MARK: - Injectability seam (MockAuthService substitutes without Firebase)

    @Test("StressAPIClient accepts MockAuthService without triggering a Firebase call at construction")
    func stressAPIClientAcceptsMockAuthService() async throws {
        let mock = MockAuthService(token: "constructed-without-firebase")
        let client = StressAPIClient(
            authService: mock,
            baseURL: URL(string: "https://api.test")!
        )
        let request = try await client.authorizedRequest(path: "chat", method: "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer constructed-without-firebase")
        #expect(mock.tokenCallCount == 1)
    }

    @Test("MockAuthService records sign-out calls for downstream state assertions")
    func mockAuthServiceRecordsSignOut() throws {
        let mock = MockAuthService()
        try mock.signOut()
        try mock.signOut()
        #expect(mock.signOutCallCount == 2)
    }

    // MARK: - Protocol contract stability

    @Test("AuthServiceProtocol declares signInAnonymously, getIDToken, signInWithGoogle, signOut")
    func authServiceProtocolContractShape() async throws {
        let mock: AuthServiceProtocol = MockAuthService()
        try await mock.signInAnonymously()
        _ = try await mock.getIDToken()
        try mock.signOut()
        if let concrete = mock as? MockAuthService {
            #expect(concrete.anonymousSignInCallCount == 1)
            #expect(concrete.tokenCallCount == 1)
            #expect(concrete.signOutCallCount == 1)
        } else {
            Issue.record("expected MockAuthService concrete type")
        }
    }

    // MARK: - clearStoredCredentials nil-safety

    @Test("clearStoredCredentials is callable and does not crash when no user is signed in")
    func clearStoredCredentialsIsCallable() {
        FirebaseAuthService.clearStoredCredentials()
        #expect(Bool(true))
    }

    // MARK: - init laziness (regression guard for Plan 01-01's lazy-init decision)

    @Test("FirebaseAuthService.init does not require a configured Firebase app")
    func initIsLazyAndDoesNotTouchAuth() {
        let service = FirebaseAuthService()
        let asProtocol: AuthServiceProtocol = service
        #expect(type(of: asProtocol) == FirebaseAuthService.self)
    }
}
