import Foundation
import Observation

@Observable
final class WatchStressViewModel {
  var currentStress: StressResult?
  var isLoading = false
  var errorMessage: String?

  private let healthKit: WatchHealthKitManager
  private let algorithm: StressAlgorithmServiceProtocol
  private let connectivity: WatchConnectivityManager

  init(
    healthKit: WatchHealthKitManager = WatchHealthKitManager(),
    algorithm: StressAlgorithmServiceProtocol = StressCalculator(),
    connectivity: WatchConnectivityManager = .shared
  ) {
    self.healthKit = healthKit
    self.algorithm = algorithm
    self.connectivity = connectivity
  }

  func requestAuthorization() async {
    do {
      try await healthKit.requestAuthorization()
    } catch {
      errorMessage = "Authorization failed: \(error.localizedDescription)"
    }
  }

  func measureStress() async {
    isLoading = true
    errorMessage = nil

    do {
      async let hrv = healthKit.fetchLatestHRV()
      async let hr = healthKit.fetchHeartRate(samples: 10)

      let (hrvData, hrData) = try await (hrv, hr)

      guard let hrvValue = hrvData?.value,
        let heartRate = hrData.first?.value
      else {
        errorMessage = "No health data available"
        isLoading = false
        return
      }

      let result = try await algorithm.calculateStress(
        hrv: hrvValue,
        heartRate: heartRate
      )

      currentStress = result
      syncToPhone(result: result)
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func loadLatestStress() async {
    isLoading = true

    let data = await connectivity.requestData("fetchLatest")

    if let level = data["stressLevel"] as? Double,
      let categoryRaw = data["category"] as? String,
      let category = StressCategory(rawValue: categoryRaw),
      let confidence = data["confidence"] as? Double,
      let hrv = data["hrv"] as? Double,
      let heartRate = data["heartRate"] as? Double,
      let timestamp = data["timestamp"] as? Date
    {
      currentStress = StressResult(
        level: level,
        category: category,
        confidence: confidence,
        hrv: hrv,
        heartRate: heartRate,
        timestamp: timestamp
      )
    }

    isLoading = false
  }

  private func syncToPhone(result: StressResult) {
    let data: [String: Any] = [
      "stressLevel": result.level,
      "category": result.category.rawValue,
      "confidence": result.confidence,
      "hrv": result.hrv,
      "heartRate": result.heartRate,
      "timestamp": result.timestamp,
    ]

    connectivity.syncData(data)
  }
}
