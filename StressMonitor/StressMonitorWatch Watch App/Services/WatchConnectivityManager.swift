import Combine
import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject, ObservableObject {
  static let shared = WatchConnectivityManager()

  @Published var isReachable = false

  private override init() {
    super.init()
    if WCSession.isSupported() {
      WCSession.default.delegate = self
      WCSession.default.activate()
    }
  }

  func syncData(_ data: [String: Any]) {
    guard WCSession.default.isReachable else {
      return
    }

    WCSession.default.transferUserInfo(data)
  }

  func requestData(_ action: String) async -> [String: Any] {
    guard WCSession.default.isReachable else {
      return [:]
    }

    return await withCheckedContinuation { continuation in
      WCSession.default.sendMessage(
        ["action": action],
        replyHandler: { reply in
          continuation.resume(returning: reply)
        },
        errorHandler: { _ in
          continuation.resume(returning: [:])
        }
      )
    }
  }
}

extension WatchConnectivityManager: WCSessionDelegate {
  // MARK: - Required WCSessionDelegate methods for watchOS
  
  func session(
    _ session: WCSession, 
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    DispatchQueue.main.async {
      self.isReachable = session.isReachable
    }
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    DispatchQueue.main.async {
      self.isReachable = session.isReachable
    }
  }

  // MARK: - Message handling

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    // Handle incoming messages from iPhone
    // Can be extended to process specific message types
  }
}
