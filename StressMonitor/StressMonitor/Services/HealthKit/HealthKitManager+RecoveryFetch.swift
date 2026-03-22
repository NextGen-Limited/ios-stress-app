import Foundation
import HealthKit

// MARK: - HealthKitManager Recovery Fetching

extension HealthKitManager {

    func fetchRecoveryData(for date: Date) async throws -> RecoveryData? {
        async let rr = fetchLatestQuantitySample(type: respiratoryRateType, unit: .count().unitDivided(by: .minute()))
        async let spo2 = fetchLatestQuantitySample(type: oxygenSaturationType, unit: .percent())
        async let trend = fetchRestingHRTrend(for: date)

        let (rrVal, spo2Val, trendVal) = try await (rr, spo2, trend)

        guard rrVal != nil || spo2Val != nil || trendVal != nil else { return nil }

        return RecoveryData(
            respiratoryRate: rrVal,
            // HealthKit stores SpO2 as fraction (0.0–1.0); convert to percentage
            bloodOxygen: spo2Val.map { $0 * 100.0 },
            restingHeartRate: nil,
            restingHRTrend: trendVal,
            analysisDate: date
        )
    }

    func fetchLatestQuantitySample(type: HKQuantityType, unit: HKUnit) async throws -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            var hasReturned = false
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard !hasReturned else { return }
                hasReturned = true
                if let error { continuation.resume(throwing: error); return }
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            self.healthStore.execute(query)
        }
    }

    private func fetchRestingHRTrend(for date: Date) async throws -> Double? {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: date)!
        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: date)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let unit = HKUnit.count().unitDivided(by: .minute())

        return try await withCheckedThrowingContinuation { continuation in
            var hasReturned = false
            let query = HKSampleQuery(
                sampleType: restingHeartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard !hasReturned else { return }
                hasReturned = true
                if let error { continuation.resume(throwing: error); return }

                guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let values = samples.map { $0.quantity.doubleValue(for: unit) }
                let avg = values.reduce(0, +) / Double(values.count)
                continuation.resume(returning: values[0] - avg)  // positive = rising = worse recovery
            }
            self.healthStore.execute(query)
        }
    }
}
