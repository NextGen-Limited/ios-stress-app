import Foundation
import FirebaseAuth
import FirebaseCore

// MARK: - Auth Service Protocol

/// Abstraction over the Firebase authentication surface so the API client
/// and tests can substitute a non-Firebase double.
protocol AuthServiceProtocol: Sendable {
    func signInAnonymously() async throws
    func getIDToken() async throws -> String
    func signOut() throws
    func signInWithGoogle() async throws
}

// MARK: - Firebase Auth Service

/// Firebase Anonymous auth implementation. Anonymous sign-in is the default,
/// frictionless path (no UI); Google Sign-In is an upgrade stub filled in by
/// Plan 02. `init` is deliberately lazy — it does not touch `Auth.auth()` so
/// the test host can construct this type without a configured Firebase app.
@MainActor
final class FirebaseAuthService: AuthServiceProtocol, @unchecked Sendable {

    private let tokenRefreshMargin: TimeInterval = 60

    init() {}

    // MARK: - AuthServiceProtocol

    func signInAnonymously() async throws {
        if Auth.auth().currentUser != nil { return }
        let result = try await Auth.auth().signInAnonymously()
        _ = result.user
    }

    /// Returns a valid Firebase ID token, forcing a refresh when the cached
    /// token is within `tokenRefreshMargin` of expiry. Mirrors the 60-second
    /// margin `SupabaseLLMService.ensureValidSession` used for its JWT.
    func getIDToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw LLMServiceError.unavailable(reason: "Please sign in to use AI Chat.")
        }

        let result = try await user.getIDTokenResult(forcingRefresh: false)
        if result.expirationDate > Date().addingTimeInterval(tokenRefreshMargin) {
            return result.token
        }
        return try await user.getIDToken(forcingRefresh: true)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func signInWithGoogle() async throws {
        // Plan 02 Task 1 implements the Google Sign-In upgrade path that
        // links the anonymous account (T-01-04 elevation-of-privilege mitigation).
        throw LLMServiceError.unavailable(reason: "Google Sign-In is not yet available.")
    }

    // MARK: - Credential Clearing

    /// Signs out the current Firebase user. Called by data-deletion flows
    /// (factory reset, full account wipe) so a wipe actually clears the
    /// anonymous session rather than leaving it live.
    static func clearStoredCredentials() {
        try? Auth.auth().signOut()
    }
}
