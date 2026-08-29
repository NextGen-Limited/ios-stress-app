import Foundation
import Testing
@testable import StressMonitor

/// Auth failures used to be thrown as `LLMServiceError.unavailable`, whose
/// description is prefixed "AI is not available:" — so a Google Sign-In
/// configuration problem rendered in the Settings "Sign-In Failed" alert as an
/// AI outage. These assertions pin the auth-shaped replacement.
@Suite("Auth Service Error")
struct AuthServiceErrorTests {

    @Test("notConfigured reads as a sign-in problem, never as an AI outage")
    func notConfiguredReadsAsSignInProblem() throws {
        let text = try #require(AuthServiceError.notConfigured.errorDescription).lowercased()

        #expect(text.contains("sign-in") || text.contains("sign in"))
        #expect(!text.contains("ai is not available"))
        #expect(!text.contains("chat"))
    }

    @Test("notSignedIn asks the user to sign in, without mentioning AI")
    func notSignedInAsksUserToSignIn() throws {
        let text = try #require(AuthServiceError.notSignedIn.errorDescription).lowercased()

        #expect(text.contains("sign in"))
        #expect(!text.contains("ai is not available"))
        #expect(!text.contains("chat"))
    }

    @Test("googleSignInFailed surfaces the underlying error's description when one is supplied")
    func googleSignInFailedSurfacesUnderlyingDescription() throws {
        let underlying = NSError(
            domain: "com.google.GIDSignIn",
            code: -5,
            userInfo: [NSLocalizedDescriptionKey: "The user canceled the sign-in flow."]
        )

        let text = try #require(AuthServiceError.googleSignInFailed(underlying: underlying).errorDescription)

        #expect(text == underlying.localizedDescription)
    }

    @Test("googleSignInFailed falls back to a generic Google Sign-In message when underlying is nil")
    func googleSignInFailedFallsBackToGenericMessage() throws {
        let text = try #require(AuthServiceError.googleSignInFailed(underlying: nil).errorDescription)

        #expect(!text.isEmpty)
        #expect(text.lowercased().contains("google"))
    }
}
