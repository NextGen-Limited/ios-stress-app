import Foundation
import HealthKit

@MainActor
@Observable
final class OnboardingHealthSyncViewModel {
    var isLoading = false
    var healthKitAuthorized = false
    var authorizationError: String?

    private let healthKitService: HealthKitServiceProtocol

    init(healthKitService: HealthKitServiceProtocol) {
        self.healthKitService = healthKitService
    }

    convenience init() {
        self.init(healthKitService: HealthKitManager())
    }

    func requestHealthKitAuthorization() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await healthKitService.requestAuthorization()
            healthKitAuthorized = true
            authorizationError = nil
        } catch {
            healthKitAuthorized = false
            authorizationError = error.localizedDescription
        }
    }

    var canProceed: Bool {
        healthKitAuthorized
    }
}
