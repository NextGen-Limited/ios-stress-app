import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

// MARK: - Auth Service Protocol

/// Abstraction over the Firebase authentication surface so the API client
/// and tests can substitute a non-Firebase double.
protocol AuthServiceProtocol: Sendable {
    func signInAnonymously() async throws
    func getIDToken() async throws -> String
    func signOut() throws
    func signInWithGoogle(presenting viewController: UIViewController) async throws
}

// MARK: - Firebase Auth Service

/// Firebase Anonymous auth implementation. Anonymous sign-in is the default,
/// frictionless path (no UI); Google Sign-In is an upgrade path that links the
/// anonymous account to a persistent Google identity. `init` is deliberately
/// lazy — it does not touch `Auth.auth()` so the test host can construct this
/// type without a configured Firebase app.
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
    /// token is within `tokenRefreshMargin` of expiry.
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

    /// Google Sign-In upgrade path. Runs the Google OAuth flow, then links the
    /// returned credential to the current anonymous user so its credit balance
    /// and chat history are preserved across the upgrade. If the Google
    /// credential is already linked to another account (the user signed in on a
    /// different device), falls back to a plain `signIn(with:)` instead of
    /// discarding the existing anonymous data.
    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw LLMServiceError.unavailable(reason: "Firebase client ID is not configured.")
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        let result: GIDSignInResult = try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: LLMServiceError.unavailable(reason: "Google Sign-In returned no result."))
                }
            }
        }

        guard let idToken = result.user.idToken?.tokenString else {
            throw LLMServiceError.unavailable(reason: "Google Sign-In did not return an ID token.")
        }
        let accessToken = result.user.accessToken.tokenString
        let credential = OAuthProvider.credential(
            withProviderID: "google.com",
            idToken: idToken,
            accessToken: accessToken
        )

        if let currentUser = Auth.auth().currentUser {
            do {
                _ = try await currentUser.link(with: credential)
                return
            } catch {
                guard (error as NSError).code == AuthErrorCode.credentialAlreadyInUse.rawValue else { throw error }
                _ = try await Auth.auth().signIn(with: credential)
                return
            }
        }
        _ = try await Auth.auth().signIn(with: credential)
    }

    // MARK: - Credential Clearing

    /// Signs out the current Firebase user and wipes the legacy Keychain
    /// accounts + UserDefaults keys left by the previous LLM stack so a
    /// returning user does not carry dead tokens across the migration. Called
    /// by data-deletion flows (factory reset, full account wipe).
    static func clearStoredCredentials() {
        try? Auth.auth().signOut()
        let service = "com.stressmonitor.app"
        for account in ["supabaseAccessToken", "supabaseRefreshToken"] {
            try? KeychainService.delete(service: service, account: account)
        }
        for key in ["supabaseSessionExpiresAt", "supabaseChatSessionId"] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
