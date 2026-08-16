import Testing
import UIKit
@testable import StressMonitor

@MainActor
struct AccountViewModelTests {

    @Test("signInWithGoogle presents progress and calls the auth service once")
    func signInWithGooglePresentsProgressAndCallsAuthService() async throws {
        let mock = MockAuthService(googleSignInError: nil, email: "linked@ripple.app")
        let viewModel = AccountViewModel(authService: mock)
        let viewController = UIViewController()

        let signInTask = Task {
            try await viewModel.signInWithGoogle(presenting: viewController)
        }
        await Task.yield()
        #expect(viewModel.isSigningIn)
        try await signInTask.value

        #expect(!viewModel.isSigningIn)
        #expect(mock.googleSignInCallCount == 1)
        #expect(mock.lastPresentingViewController === viewController)
    }

    @Test("successful Google sign-in stores the linked email")
    func successfulGoogleSignInStoresLinkedEmail() async throws {
        let mock = MockAuthService(googleSignInError: nil, email: "linked@ripple.app")
        let viewModel = AccountViewModel(authService: mock)

        try await viewModel.signInWithGoogle(presenting: UIViewController())

        #expect(viewModel.linkedEmail == "linked@ripple.app")
        #expect(viewModel.errorMessage == nil)
    }

    @Test("failed Google sign-in surfaces an error and resets progress")
    func failedGoogleSignInSurfacesErrorAndResetsProgress() async throws {
        let mock = MockAuthService(
            googleSignInError: LLMServiceError.unavailable(reason: "Google Sign-In failed.")
        )
        let viewModel = AccountViewModel(authService: mock)

        do {
            try await viewModel.signInWithGoogle(presenting: UIViewController())
            Issue.record("Expected sign-in to throw")
        } catch {
            #expect(error is LLMServiceError)
        }

        #expect(viewModel.linkedEmail == nil)
        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isSigningIn)
    }

    @Test("refreshAccountState reads the current account email")
    func refreshAccountStateReadsCurrentAccountEmail() {
        let mock = MockAuthService()
        let viewModel = AccountViewModel(authService: mock)

        viewModel.refreshAccountState()
        #expect(viewModel.linkedEmail == nil)

        mock.email = "linked@ripple.app"
        viewModel.refreshAccountState()
        #expect(viewModel.linkedEmail == "linked@ripple.app")
    }
}
