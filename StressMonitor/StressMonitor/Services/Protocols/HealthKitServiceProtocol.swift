import Foundation

@preconcurrency import HealthKit

protocol HealthKitServiceProtocol: Sendable {
    func requestAuthorization() async throws
    func fetchLatestHRV() async throws -> HRVMeasurement?
    func fetchHeartRate(samples: Int) async throws -> [HeartRateSample]
    func fetchHRVHistory(since: Date) async throws -> [HRVMeasurement]
    func observeHeartRateUpdates() -> AsyncStream<HeartRateSample?>
    func fetchSleepData(for date: Date) async throws -> SleepData?
    func fetchActivityData(for date: Date) async throws -> ActivityData?
    func fetchRecoveryData(for date: Date) async throws -> RecoveryData?
}

extension HealthKitServiceProtocol {
    func fetchSleepData(for date: Date) async throws -> SleepData? { nil }
    func fetchActivityData(for date: Date) async throws -> ActivityData? { nil }
    func fetchRecoveryData(for date: Date) async throws -> RecoveryData? { nil }
}
