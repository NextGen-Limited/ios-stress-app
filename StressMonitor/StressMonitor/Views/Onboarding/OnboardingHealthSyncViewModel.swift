import Foundation
import HealthKit

@MainActor
@Observable
final class OnboardingHealthSyncViewModel {
    // Toggle states — visual only, pre-selected defaults
    var heartRateEnabled = true
    var hrvEnabled = true
    var sleepEnabled = true
    var activityEnabled = false // Optional per design spec

    // Authorization state
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

    /// Request HealthKit authorization for all enabled permission types.
    /// Currently uses the shared requestAuthorization() which requests all types.
    /// In the future, this could be granular per toggle.
    func requestSelectedPermissions() async {
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

    /// At least one toggle must be enabled to proceed
    var hasAtLeastOnePermission: Bool {
        heartRateEnabled || hrvEnabled || sleepEnabled || activityEnabled
    }
}
