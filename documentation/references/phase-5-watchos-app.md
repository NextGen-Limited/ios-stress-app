# Phase 5: watchOS App

**Goal:** Build a minimal watchOS app with real-time stress display, trigger button, and complications.

## Prerequisites
- ✅ Phase 4 completed
- iPhone UI working
- WatchConnectivity ready

---

## 1. watchOS App Structure

### Main Watch View
File: `StressMonitorWatch/Views/ContentView.swift`

```swift
import SwiftUI

struct ContentView: View {
    @State private var viewModel = WatchStressViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Compact Stress Display
                CompactStressView(level: viewModel.currentStress?.level ?? 0)
                    .frame(height: 150)

                // Status
                Text(viewModel.currentStress?.category.rawValue ?? "--")
                    .font(.headline)

                // Measure Button
                Button(action: {
                    Task {
                        await viewModel.measureStress()
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Measure")
                            .font(.headline)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
            }
            .padding()
        }
        .navigationTitle("Stress")
        .task {
            await viewModel.loadLatestStress()
        }
    }
}
```

### Compact Stress Display
File: `StressMonitorWatch/Views/Components/CompactStressView.swift`

```swift
import SwiftUI

struct CompactStressView: View {
    let level: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 15)

            Circle()
                .trim(from: 0, to: level / 100)
                .stroke(colorForLevel(level), lineWidth: 15)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: level)

            VStack(spacing: 2) {
                Text("\(Int(level))")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(colorForLevel(level))
            }
        }
    }

    private func colorForLevel(_ level: Double) -> Color {
        switch level {
        case 0..<25: return .green
        case 25..<50: return .yellow
        case 50..<75: return .orange
        default: return .red
        }
    }
}
```

---

## 2. Watch ViewModel

### Stress ViewModel for Watch
File: `StressMonitorWatch/ViewModels/WatchStressViewModel.swift`

```swift
import Foundation
import Observation
import WatchConnectivity

@Observable
class WatchStressViewModel {
    private let connectivity = WatchConnectivityManager.shared
    private let healthKit: WatchHealthKitManager

    var currentStress: StressResult?
    var isLoading = false
    var errorMessage: String?

    init() {
        self.healthKit = WatchHealthKitManager()
    }

    func measureStress() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch health data on watch
            async let hrv = healthKit.fetchLatestHRV()
            async let heartRate = healthKit.fetchHeartRate(samples: 10)

            let (hrvData, hrData) = try await (hrv, heartRate)

            guard let latestHRV = hrvData,
                  let latestHR = hrData.first else {
                throw HealthError.noData
            }

            // Calculate stress locally
            let algorithm = StressCalculator()
            let result = try await algorithm.calculateStress(
                hrv: latestHRV.value,
                heartRate: latestHR.value
            )

            currentStress = result

            // Sync to iPhone
            syncToPhone(result: result)

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadLatestStress() async {
        // Request latest from phone
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["action": "fetchLatest"], replyHandler: { response in
                // Handle response
            })
        }
    }

    private func syncToPhone(result: StressResult) {
        let data: [String: Any] = [
            "action": "saveMeasurement",
            "stressLevel": result.level,
            "hrv": result.inputs.hrv,
            "heartRate": result.inputs.heartRate,
            "timestamp": result.timestamp.timeIntervalSince1970
        ]

        connectivity.syncData(data)
    }
}
```

---

## 3. Watch-Specific HealthKit

### HealthKit for Watch
File: `StressMonitorWatch/Services/WatchHealthKitManager.swift`

```swift
import HealthKit
import Foundation

@Observable
class WatchHealthKitManager {
    private let healthStore = HKHealthStore()

    private let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!

    func requestAuthorization() async throws {
        let typesToRead: Set = [hrvType, heartRateType]
        try await healthStore.requestAuthorization(toShare: nil, read: typesToRead)
    }

    func fetchLatestHRV() async throws -> HRVMeasurement? {
        await withCheckedContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(returning: nil)
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

            healthStore.execute(query)
        }
    }

    func fetchHeartRate(samples: Int) async throws -> [HeartRateSample] {
        // Similar implementation
        return []
    }
}
```

---

## 4. WidgetKit Complications

### Complication Timeline
File: `StressMonitorWatch/Complications/StressComplication.swift`

```swift
import WidgetKit
import SwiftUI

struct StressComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StressComplication", provider: StressProvider()) { entry in
            StressComplicationView(entry: entry)
        }
        .configurationDisplayName("Stress Level")
        .description("Shows your current stress level")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

struct StressEntry: TimelineEntry {
    let date: Date
    let stressLevel: Double
    let category: StressCategory
}

struct StressProvider: TimelineProvider {
    func placeholder(in context: Context) -> StressEntry {
        StressEntry(date: Date(), stressLevel: 42, category: .mild)
    }

    func getSnapshot(in context: Context, completion: @escaping (StressEntry) -> Void) {
        let entry = StressEntry(date: Date(), stressLevel: 42, category: .mild)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StressEntry>) -> Void) {
        // Fetch latest stress measurement
        let entry = StressEntry(date: Date(), stressLevel: 42, category: .mild)

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }
}

struct StressComplicationView: View {
    var entry: StressProvider.Entry

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Int(entry.stressLevel))")
                .font(.system(size: 20, weight: .bold))

            Text(entry.category.rawValue)
                .font(.caption2)
        }
    }
}
```

---

## 5. Watch App Entry Point

### Watch App Configuration
File: `StressMonitorWatch/StressMonitorWatchApp.swift`

```swift
import SwiftUI

@main
struct StressMonitorWatchApp: App {
    @State private var healthKit = WatchHealthKitManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Request HealthKit authorization
                    try? await healthKit.requestAuthorization()
                }
        }
    }
}
```

---

## 6. Phone-Watch Communication

### iPhone Session Delegate
File: `StressMonitor/Services/Connectivity/PhoneConnectivityManager.swift`

```swift
import WatchConnectivity
import Foundation

@Observable
class PhoneConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = PhoneConnectivityManager()
    private let repository: StressRepositoryProtocol

    var isWatchConnected = false

    override private init() {
        // Initialize repository
        self.repository = StressRepository(modelContext: /* get context */)
        super.init()

        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        isWatchConnected = state == .activated
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        isWatchConnected = false
    }

    func sessionDidDeactivate(_ session: WCSession) {
        isWatchConnected = false
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let action = userInfo["action"] as? String else { return }

        switch action {
        case "saveMeasurement":
            handleWatchMeasurement(userInfo)
        default:
            break
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let action = message["action"] as? String else { return }

        switch action {
        case "fetchLatest":
            // Reply with latest measurement
            replyHandler(["stressLevel": 42])
        default:
            break
        }
    }

    private func handleWatchMeasurement(_ userInfo: [String: Any]) {
        guard let stressLevel = userInfo["stressLevel"] as? Double,
              let hrv = userInfo["hrv"] as? Double,
              let heartRate = userInfo["heartRate"] as? Double,
              let timestampInterval = userInfo["timestamp"] as? TimeInterval else {
            return
        }

        let timestamp = Date(timeIntervalSince1970: timestampInterval)
        let measurement = StressMeasurement(
            stressLevel: stressLevel,
            hrv: hrv,
            restingHeartRate: heartRate,
            confidences: [0.8]
        )

        Task {
            try? await repository.save(measurement)
        }
    }
}
```

---

## Testing Checklist

### Watch App
- [ ] App launches on watch
- [ ] Stress display shows
- [ ] Measure button works
- [ ] HealthKit authorization prompts
- [ ] Data syncs to iPhone

### Complications
- [ ] Circular complication works
- [ ] Rectangular complication works
- [ ] Updates correctly
- [ ] Shows proper data

### Communication
- [ ] Watch can send data to phone
- [ ] Phone receives watch data
- [ ] Phone can respond to requests
- [ ] Handles disconnection

### UX
- [ ] Interface is readable
- [ ] Colors work on watch
- [ ] Performance is good
- [ ] Battery usage acceptable

---

## Estimated Time

**3-4 hours**

- Watch app UI: 1.5 hours
- Watch HealthKit: 30 min
- ViewModel integration: 30 min
- Complications: 1 hour
- Communication testing: 30 min

---

## Next Steps

Once this phase is complete, proceed to **Phase 6: Background Notifications** to enable background updates.
