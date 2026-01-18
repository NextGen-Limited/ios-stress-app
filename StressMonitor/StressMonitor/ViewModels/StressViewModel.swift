import Foundation
import Observation

@Observable
@MainActor
final class StressViewModel {

    var currentStress: StressResult?
    var historicalData: [StressMeasurement] = []
    var baseline: PersonalBaseline?
    var liveHeartRate: Double?
    var isLoading = false
    var errorMessage: String?
    var lastRefresh: Date?

    private let healthKit: HealthKitServiceProtocol
    private let algorithm: StressAlgorithmServiceProtocol
    private let repository: StressRepositoryProtocol

    init(
        healthKit: HealthKitServiceProtocol,
        algorithm: StressAlgorithmServiceProtocol,
        repository: StressRepositoryProtocol
    ) {
        self.healthKit = healthKit
        self.algorithm = algorithm
        self.repository = repository
    }

    func loadCurrentStress() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let hrv = healthKit.fetchLatestHRV()
            async let hr = healthKit.fetchHeartRate(samples: 1)

            let (hrvData, hrData) = try await (hrv, hr)

            guard let hrvValue = hrvData?.value else {
                errorMessage = "No HRV data available"
                return
            }

            let heartRateValue = hrData.first?.value ?? 70

            let result = try await algorithm.calculateStress(hrv: hrvValue, heartRate: heartRateValue)
            currentStress = result
            lastRefresh = Date()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadHistoricalData(days: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            historicalData = try await repository.fetchRecent(limit: days * 24)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadBaseline() async {
        isLoading = true
        defer { isLoading = false }

        do {
            baseline = try await repository.getBaseline()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshHealthData() async {
        await loadCurrentStress()
    }

    func observeHeartRate() {
        Task {
            for await sample in healthKit.observeHeartRateUpdates() {
                liveHeartRate = sample?.value
            }
        }
    }

    func calculateAndSaveStress() async throws {
        async let hrv = healthKit.fetchLatestHRV()
        async let hr = healthKit.fetchHeartRate(samples: 1)

        let (hrvData, hrData) = try await (hrv, hr)

        guard let hrvValue = hrvData?.value else {
            throw StressError.noData
        }

        let heartRateValue = hrData.first?.value ?? 70
        let result = try await algorithm.calculateStress(hrv: hrvValue, heartRate: heartRateValue)

        let measurement = StressMeasurement(
            timestamp: result.timestamp,
            stressLevel: result.level,
            hrv: result.hrv,
            restingHeartRate: result.heartRate,
            confidences: [result.confidence]
        )

        try await repository.save(measurement)
        currentStress = result
        lastRefresh = Date()
    }

    func clearError() {
        errorMessage = nil
    }
}

enum StressError: Error {
    case noData
}
