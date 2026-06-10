import SwiftUI

@main
struct StressMonitorWatchApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }

  init() {
    _ = WatchConnectivityManager.shared
  }
}
