import Foundation
import HealthKit
import WatchKit

final class WatchHealthKitManager: HealthKitServiceProtocol {
  private let healthStore = HKHealthStore()

  private let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
  private let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!

  func requestAuthorization() async throws {
    guard HKHealthStore.isHealthDataAvailable() else {
      throw HealthKitError.notAvailable
    }

    let typesToRead: Set<HKSampleType> = [hrvType, heartRateType]

    try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
  }

  func fetchLatestHRV() async throws -> HRVMeasurement? {
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
    let query = HKSampleQuery(
      sampleType: hrvType,
      predicate: nil,
      limit: 1,
      sortDescriptors: [sortDescriptor]
    ) { [weak self] _, samples, _ in
      guard let self = self,
        let sample = samples?.first as? HKQuantitySample
      else {
        return
      }

      let value = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
      self.hrvResult = HRVMeasurement(value: value, timestamp: sample.endDate)
    }

    healthStore.execute(query)

    return await withCheckedContinuation { continuation in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        continuation.resume(returning: self.hrvResult)
      }
    }
  }

  func fetchHeartRate(samples: Int) async throws -> [HeartRateSample] {
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
    let query = HKSampleQuery(
      sampleType: heartRateType,
      predicate: nil,
      limit: samples,
      sortDescriptors: [sortDescriptor]
    ) { [weak self] _, samples, _ in
      guard let self = self,
        let samples = samples as? [HKQuantitySample]
      else {
        return
      }

      let results = samples.map { sample in
        let value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        return HeartRateSample(value: value, timestamp: sample.endDate)
      }

      self.heartRateResults = results
    }

    healthStore.execute(query)

    return await withCheckedContinuation { continuation in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        continuation.resume(returning: self.heartRateResults ?? [])
      }
    }
  }

  private var hrvResult: HRVMeasurement?
  private var heartRateResults: [HeartRateSample]?

  func fetchHRVHistory(since: Date) async throws -> [HRVMeasurement] {
    let predicate = HKQuery.predicateForSamples(withStart: since, end: nil, options: .strictStartDate)
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
    let query = HKSampleQuery(
      sampleType: hrvType,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: [sortDescriptor]
    ) { [weak self] _, samples, _ in
      guard let self = self,
        let samples = samples as? [HKQuantitySample]
      else {
        return
      }

      let results = samples.map { sample in
        let value = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
        return HRVMeasurement(value: value, timestamp: sample.endDate)
      }

      self.hrvHistoryResults = results
    }

    healthStore.execute(query)

    return await withCheckedContinuation { continuation in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        continuation.resume(returning: self.hrvHistoryResults ?? [])
      }
    }
  }

  func observeHeartRateUpdates() -> AsyncStream<HeartRateSample?> {
    AsyncStream { continuation in
      let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { _, _, _ in
        continuation.yield(nil)
      }
      self.healthStore.execute(query)
    }
  }

  private var hrvHistoryResults: [HRVMeasurement]?
}

enum HealthKitError: Error {
  case notAvailable
  case authorizationDenied
  case noData
}
