import Foundation

@MainActor
@Observable
final class OnboardingSuccessViewModel {
    var personalBaseline: PersonalBaseline?

    // Preview metrics for onboarding dashboard preview
    let previewStressScore = 28
    let previewHRV = 62
    let previewHeartRate = 68

    private let repository: StressRepositoryProtocol

    init(repository: StressRepositoryProtocol) {
        self.repository = repository
        loadBaseline()
    }

    func loadBaseline() {
        Task {
            do {
                personalBaseline = try await repository.getBaseline()
            } catch {
                personalBaseline = nil
            }
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}
