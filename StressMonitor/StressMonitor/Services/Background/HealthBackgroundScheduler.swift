import Foundation
import BackgroundTasks

@MainActor
final class HealthBackgroundScheduler {

    private let healthKit: HealthKitServiceProtocol
    private let algorithm: StressAlgorithmServiceProtocol
    private let repository: StressRepositoryProtocol

    private let backgroundTaskIdentifier = "com.stressmonitor.background.refresh"

    init(
        healthKit: HealthKitServiceProtocol,
        algorithm: StressAlgorithmServiceProtocol,
        repository: StressRepositoryProtocol
    ) {
        self.healthKit = healthKit
        self.algorithm = algorithm
        self.repository = repository
    }

    func scheduleBackgroundRefresh() throws {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        try BGTaskScheduler.shared.submit(request)
    }

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let self else { return }
            Task {
                await self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
            }
        }
    }

    func handleBackgroundRefresh(task: BGAppRefreshTask) async {
        let operation = Task {
            try? await self.fetchAndCalculateStress()
        }

        task.expirationHandler = {
            operation.cancel()
            task.setTaskCompleted(success: false)
        }

        _ = await operation.value
        task.setTaskCompleted(success: !operation.isCancelled)
    }

    func cancelAllTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
    }

    private func fetchAndCalculateStress() async throws {
        async let hrv = healthKit.fetchLatestHRV()
        async let hr = healthKit.fetchHeartRate(samples: 1)

        let (hrvData, hrData) = try await (hrv, hr)

        guard let hrvValue = hrvData?.value else {
            return
        }

        let heartRateValue = hrData.first?.value ?? 70
        let result = try await algorithm.calculateStress(hrv: hrvValue, heartRate: heartRateValue)

        let measurement = StressMeasurement(
            timestamp: result.timestamp,
            stressLevel: result.level,
            hrv: result.hrv,
            heartRate: result.heartRate,
            category: result.category
        )

        try await repository.save(measurement)
    }
}
