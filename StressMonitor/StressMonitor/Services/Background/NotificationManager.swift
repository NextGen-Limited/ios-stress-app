import Foundation
import UIKit
import UserNotifications

@MainActor
final class NotificationManager {
  static let shared = NotificationManager()

  private let notificationCenter = UNUserNotificationCenter.current()

  private init() {}

  func requestAuthorization() async throws {
    let options: UNAuthorizationOptions = [.alert, .sound, .badge]
    try await notificationCenter.requestAuthorization(options: options)
  }

  func notifyHighStress(level: Double) async {
    let content = UNMutableNotificationContent()
    content.title = "High Stress Detected"
    content.body =
      "Your stress level is \(Int(level)). Consider taking a break and practicing deep breathing."
    content.sound = .default
    content.badge = 1

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

    let request = UNNotificationRequest(
      identifier: "high-stress-\(UUID().uuidString)",
      content: content,
      trigger: trigger
    )

    try? await notificationCenter.add(request)
  }

  func scheduleNotification(
    content: UNMutableNotificationContent,
    trigger: UNNotificationTrigger
  ) async {
    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: trigger
    )

    try? await notificationCenter.add(request)
  }
}
