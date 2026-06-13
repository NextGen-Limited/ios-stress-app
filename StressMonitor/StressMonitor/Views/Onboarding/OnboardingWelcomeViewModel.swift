import SwiftUI

@MainActor
@Observable
final class OnboardingWelcomeViewModel {
    var navigateToHealthKit = false
    var navigateToSignIn = false

    // Animation states
    var breathPhase = false
    var breathPhase2 = false
    var breathPhase3 = false
    var floatOffset = false

    private var animationTask: Task<Void, Never>?
    private var floatTask: Task<Void, Never>?

    init() {
        startAnimations()
    }

    func handleGetStarted() {
        navigateToHealthKit = true
    }

    func handleSignIn() {
        navigateToSignIn = true
    }

    func startAnimations() {
        animationTask?.cancel()
        animationTask = Task {
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 2.0)) { breathPhase = true }
                try? await Task.sleep(for: .seconds(0.6))
                withAnimation(.easeInOut(duration: 2.0)) { breathPhase2 = true }
                try? await Task.sleep(for: .seconds(0.6))
                withAnimation(.easeInOut(duration: 2.0)) { breathPhase3 = true }
                try? await Task.sleep(for: .seconds(2.0))
                withAnimation(.easeInOut(duration: 2.0)) {
                    breathPhase = false
                    breathPhase2 = false
                    breathPhase3 = false
                }
                try? await Task.sleep(for: .seconds(2.0))
            }
        }

        floatTask?.cancel()
        floatTask = Task {
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 2.0)) { floatOffset = true }
                try? await Task.sleep(for: .seconds(2.0))
                withAnimation(.easeInOut(duration: 2.0)) { floatOffset = false }
                try? await Task.sleep(for: .seconds(2.0))
            }
        }
    }

    func stopAnimations() {
        animationTask?.cancel()
        floatTask?.cancel()
    }
}
