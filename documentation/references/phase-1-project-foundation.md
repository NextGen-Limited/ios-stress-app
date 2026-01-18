# Phase 1: Project Foundation

**Goal:** Set up the Xcode project, configure dependencies, and establish the basic architecture.

## Prerequisites
- Xcode 15.0+
- macOS 14.0+
- Apple Developer Account (for testing)
- iOS 17.0+ and watchOS 10.0+ SDKs

---

## 1. Project Setup

### Create Xcode Project
```
File → New → Project
Template: iOS → App
Product Name: StressMonitor
Interface: SwiftUI
Language: Swift
```

### Add watchOS Target
```
File → New → Target
Template: watchOS → App
Product Name: StressMonitor Watch
```

### Project Structure
```
StressMonitor/
├── StressMonitor/
│   ├── App/
│   │   └── StressMonitorApp.swift
│   ├── Models/
│   ├── ViewModels/
│   ├── Views/
│   ├── Services/
│   └── Resources/
└── StressMonitorWatch/
    ├── App/
    ├── Models/
    ├── ViewModels/
    ├── Views/
    └── Services/
```

---

## 2. Shared Architecture Setup

### Create Observable Model Base
File: `StressMonitor/Models/Base/ObservableModel.swift`

```swift
import Foundation

@Observable
class BaseViewModel {
    var isLoading = false
    var errorMessage: String?

    func setError(_ message: String) {
        errorMessage = message
    }

    func clearError() {
        errorMessage = nil
    }
}
```

### Create Core Protocols
File: `StressMonitor/Services/Protocols/HealthKitServiceProtocol.swift`

```swift
import HealthKit

protocol HealthKitServiceProtocol {
    func requestAuthorization() async throws -> Void
    func fetchLatestHRV() async throws -> HRVMeasurement?
    func fetchHeartRate(samples: Int) async throws -> [HeartRateSample]
}
```

---

## 3. Basic Model Definitions

### HRV Measurement
File: `StressMonitor/Models/HRVMeasurement.swift`

```swift
import Foundation

struct HRVMeasurement: Identifiable, Codable {
    let id: UUID
    let value: Double
    let timestamp: Date
    let unit: String

    init(value: Double, timestamp: Date = Date()) {
        self.id = UUID()
        self.value = value
        self.timestamp = timestamp
        self.unit = "ms"
    }
}
```

### Heart Rate Sample
File: `StressMonitor/Models/HeartRateSample.swift`

```swift
import Foundation

struct HeartRateSample: Identifiable, Codable {
    let id: UUID
    let value: Double
    let timestamp: Date

    init(value: Double, timestamp: Date = Date()) {
        self.id = UUID()
        self.value = value
        self.timestamp = timestamp
    }
}
```

---

## 4. Info.plist Configuration

### iOS Info.plist
```xml
<key>NSHealthShareUsageDescription</key>
<string>We need access to your health data to monitor stress levels.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>We need to update your health data with stress measurements.</string>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
</array>
```

### watchOS Info.plist
```xml
<key>NSHealthShareUsageDescription</key>
<string>We need access to your health data to monitor stress levels.</string>
<key>WKBackgroundModes</key>
<array>
    <string>fetch</string>
</array>
```

---

## 5. SwiftUI App Entry Points

### iOS App
File: `StressMonitor/App/StressMonitorApp.swift`

```swift
import SwiftUI

@main
struct StressMonitorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### watchOS App
File: `StressMonitorWatch/App/StressMonitorWatchApp.swift`

```swift
import SwiftUI

@main
struct StressMonitorWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## 6. Basic Testing Setup

### Create iOS Test Target
```
File → New → Target
Template: Unit Testing Bundle
Target Name: StressMonitorTests
```

### Create watchOS Test Target
```
File → New → Target
Template: Unit Testing Bundle
Target Name: StressMonitorWatchTests
```

### Baseline Test
File: `StressMonitorTests/StressMonitorTests.swift`

```swift
import XCTest
@testable import StressMonitor

final class StressMonitorTests: XCTestCase {
    func testExample() throws {
        XCTAssert(true)
    }
}
```

---

## Testing Checklist

- [ ] Project builds without errors
- [ ] Both iOS and watchOS targets compile
- [ ] Can run iOS simulator
- [ ] Can run watchOS simulator
- [ ] Basic unit test runs successfully
- [ ] Info.plist configurations are correct
- [ ] Folder structure matches the plan

---

## Estimated Time

**2-3 hours**

- Project creation: 30 min
- Architecture setup: 45 min
- Model definitions: 30 min
- Configuration: 30 min
- Testing setup: 30 min

---

## Next Steps

Once this phase is complete, proceed to **Phase 2: Data Layer** to implement HealthKit integration and local persistence.
