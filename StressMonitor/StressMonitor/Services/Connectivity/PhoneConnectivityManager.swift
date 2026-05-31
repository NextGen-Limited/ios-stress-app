import Combine
import Foundation
import SwiftData
import WatchConnectivity

final class PhoneConnectivityManager: NSObject, ObservableObject {
  static let shared = PhoneConnectivityManager()

  @Published var isWatchPaired = false
  @Published var isWatchAppInstalled = false
  @Published var isReachable = false

  private var modelContext: ModelContext?

  private override init() {
    super.init()
    if WCSession.isSupported() {
      WCSession.default.delegate = self
      WCSession.default.activate()
    }
  }

  func setModelContext(_ context: ModelContext) {
    self.modelContext = context
  }

  private func handleWatchMeasurement(_ userInfo: [String: Any]) {
    guard
      let stressLevel = userInfo["stressLevel"] as? Double,
      let categoryRaw = userInfo["category"] as? String,
      let category = StressCategory(rawValue: categoryRaw),
      let confidence = userInfo["confidence"] as? Double,
      let hrv = userInfo["hrv"] as? Double,
      let heartRate = userInfo["heartRate"] as? Double,
      let timestamp = userInfo["timestamp"] as? Date
    else {
      return
    }

    let measurement = StressMeasurement(
      timestamp: timestamp,
      stressLevel: stressLevel,
      hrv: hrv,
      restingHeartRate: heartRate,
      confidences: [confidence]
    )

    guard let context = modelContext else {
      return
    }

    do {
      context.insert(measurement)
      try context.save()
    } catch {
      print("Failed to save watch measurement: \(error)")
    }
  }
}

extension PhoneConnectivityManager: WCSessionDelegate {
  func sessionDidBecomeInactive(_ session: WCSession) {}

  func sessionDidDeactivate(_ session: WCSession) {
    WCSession.default.activate()
  }

  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    isWatchPaired = session.isPaired
    isWatchAppInstalled = session.isWatchAppInstalled
    isReachable = session.isReachable
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    isReachable = session.isReachable
  }

  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    handleWatchMeasurement(userInfo)
  }

  func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
  ) {
    guard let action = message["action"] as? String, action == "fetchLatest" else {
      replyHandler([:])
      return
    }

    guard let context = modelContext else {
      replyHandler([:])
      return
    }

    var descriptor = FetchDescriptor<StressMeasurement>(
      sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
    )
    descriptor.fetchLimit = 1

    do {
      if let latest = try context.fetch(descriptor).first {
        let reply: [String: Any] = [
          "stressLevel": latest.stressLevel,
          "category": StressResult.category(for: latest.stressLevel).rawValue,
          "confidence": latest.confidences?.first ?? 0.0,
          "hrv": latest.hrv,
          "heartRate": latest.restingHeartRate,
          "timestamp": latest.timestamp,
        ]
        replyHandler(reply)
      } else {
        replyHandler([:])
      }
    } catch {
      replyHandler([:])
    }
  }
}
