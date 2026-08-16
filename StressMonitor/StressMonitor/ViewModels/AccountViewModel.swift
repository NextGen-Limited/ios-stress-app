import UIKit

@MainActor
@Observable
final class AccountViewModel {

    var linkedEmail: String?
    var isSigningIn = false
    var errorMessage: String?

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = FirebaseAuthService()) {
        self.authService = authService
    }

    func refreshAccountState() {
        linkedEmail = authService.currentAccountEmail
    }

    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        guard !isSigningIn else { return }
        isSigningIn = true
        errorMessage = nil
        defer { isSigningIn = false }

        do {
            try await authService.signInWithGoogle(presenting: viewController)
            refreshAccountState()
        } catch {
            errorMessage = GoogleSignInCancellation.isUserCancellation(error)
                ? nil
                : error.localizedDescription
            throw error
        }
    }
}

enum GoogleSignInCancellation {
    static func isUserCancellation(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == "com.google.GIDSignIn" && nsError.code == -5
    }
}
