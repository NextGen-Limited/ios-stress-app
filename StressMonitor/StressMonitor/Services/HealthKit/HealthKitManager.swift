import Foundation
import HealthKit

@MainActor
@Observable
final class HealthKitManager: HealthKitServiceProtocol {
    private let healthStore: HKHealthStore

    private let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

    init(healthStore: HKHealthStore = .init()) {
        self.healthStore = healthStore
    }

    func requestAuthorization() async throws {
        let types: Set<HKObjectType> = [hrvType, heartRateType]

        try await healthStore.requestAuthorization(toShare: [] as Set<HKSampleType>, read: types)
    }

    func fetchLatestHRV() async throws -> HRVMeasurement? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            var queryHasReturned = false

            let wrappedQuery = HKSampleQuery(
                sampleType: self.hrvType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard !queryHasReturned else { return }
                queryHasReturned = true

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let value = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                let measurement = HRVMeasurement(value: value, timestamp: sample.endDate)
                continuation.resume(returning: measurement)
            }

            self.healthStore.execute(wrappedQuery)
        }
    }

    func fetchHeartRate(samples: Int) async throws -> [HeartRateSample] {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            var queryHasReturned = false

            let query = HKSampleQuery(
                sampleType: self.heartRateType,
                predicate: nil,
                limit: samples,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard !queryHasReturned else { return }
                queryHasReturned = true

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let heartRates = samples.map { sample in
                    let value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    return HeartRateSample(value: value, timestamp: sample.endDate)
                }

                continuation.resume(returning: heartRates)
            }

            self.healthStore.execute(query)
        }
    }

    func fetchHRVHistory(since: Date) async throws -> [HRVMeasurement] {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let predicate = HKQuery.predicateForSamples(withStart: since, end: nil, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            var queryHasReturned = false

            let query = HKSampleQuery(
                sampleType: self.hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard !queryHasReturned else { return }
                queryHasReturned = true

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let measurements = samples.map { sample in
                    let value = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                    return HRVMeasurement(value: value, timestamp: sample.endDate)
                }

                continuation.resume(returning: measurements)
            }

            self.healthStore.execute(query)
        }
    }

    func observeHeartRateUpdates() -> AsyncStream<HeartRateSample?> {
        return AsyncStream { continuation in
            let query = HKObserverQuery(sampleType: self.heartRateType, predicate: nil) { _, _, error in
                if let error {
                    continuation.yield(nil)
                    return
                }

                Task {
                    do {
                        let samples = try await self.fetchHeartRate(samples: 1)
                        continuation.yield(samples.first)
                    } catch {
                        continuation.yield(nil)
                    }
                }
            }

            self.healthStore.execute(query)

            continuation.onTermination = { @Sendable _ in
                self.healthStore.stop(query)
            }
        }
    }
}
