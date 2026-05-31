import SwiftUI

@main
struct StressMonitorWatch_Watch_AppApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }

  init() {
    _ = WatchConnectivityManager.shared
  }
}
