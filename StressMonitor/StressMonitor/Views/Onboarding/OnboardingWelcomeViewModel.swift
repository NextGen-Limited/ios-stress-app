import Foundation

@MainActor
@Observable
final class OnboardingWelcomeViewModel {
    var isAnimating = true
    var navigateToHealthKit = false
    var navigateToSignIn = false

    func handleGetStarted() {
        navigateToHealthKit = true
    }

    func handleSignIn() {
        navigateToSignIn = true
    }
}
