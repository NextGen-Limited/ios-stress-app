# Phase 4: iPhone UI

**Goal:** Build a clean, minimal iPhone app with real-time stress display, historical data, and manual trigger.

## Prerequisites
- ✅ Phase 3 completed
- Algorithm produces stress results
- Repository stores data

---

## 1. Main Tab Structure

### App Tab View
File: `StressMonitor/Views/MainTabView.swift`

```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Now", systemImage: "heart.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
```

---

## 2. Dashboard View

### Main Stress Display
File: `StressMonitor/Views/DashboardView.swift`

```swift
import SwiftUI

struct DashboardView: View {
    @State private var viewModel = StressViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Stress Level Ring
                    StressRingView(level: viewModel.currentStress?.level ?? 0)
                        .frame(height: 300)

                    // Status Text
                    VStack(spacing: 8) {
                        Text(viewModel.currentStress?.category.rawValue ?? "Unknown")
                            .font(.title)
                            .fontWeight(.semibold)

                        Text("Confidence: \(Int((viewModel.currentStress?.confidence ?? 0) * 100))%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Manual Trigger Button
                    Button(action: {
                        Task {
                            await viewModel.fetchAndCalculate()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Measure Now")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(viewModel.isLoading)
                }
                .padding()
            }
            .navigationTitle("Stress Monitor")
        }
        .task {
            await viewModel.fetchAndCalculate()
        }
    }
}
```

### Stress Ring Component
File: `StressMonitor/Views/Components/StressRingView.swift`

```swift
import SwiftUI

struct StressRingView: View {
    let level: Double

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 30)

            // Progress ring
            Circle()
                .trim(from: 0, to: level / 100)
                .stroke(
                    colorForLevel(level),
                    style: StrokeStyle(lineWidth: 30, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: level)

            // Center text
            VStack {
                Text("\(Int(level))")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(colorForLevel(level))

                Text("STRESS")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
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

## 3. History View

### Historical Data List
File: `StressMonitor/Views/HistoryView.swift`

```swift
import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StressMeasurement.timestamp, order: .reverse) private var measurements: [StressMeasurement]

    var body: some View {
        NavigationView {
            List {
                if measurements.isEmpty {
                    ContentUnavailableView {
                        Label("No Measurements", systemImage: "chart.bar")
                    } description: {
                        Text("Take a measurement to see your history")
                    }
                } else {
                    ForEach(measurements) { measurement in
                        HistoryRowView(measurement: measurement)
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

struct HistoryRowView: View {
    let measurement: StressMeasurement

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(measurement.timestamp, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(measurement.timestamp, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(measurement.stressLevel))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(colorForLevel(measurement.stressLevel))

                Text("HRV: \(Int(measurement.hrv))ms")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
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

## 4. Settings View

### App Configuration
File: `StressMonitor/Views/SettingsView.swift`

```swift
import SwiftUI

struct SettingsView: View {
    @AppStorage("baselineHRV") private var baselineHRV: Double = 50.0
    @AppStorage("restingHeartRate") private var restingHeartRate: Double = 60.0
    @AppStorage("autoMeasureEnabled") private var autoMeasureEnabled: Bool = true

    var body: some View {
        NavigationView {
            Form {
                Section("Health Baseline") {
                    HStack {
                        Text("Baseline HRV")
                        Spacer()
                        Text("\(Int(baselineHRV)) ms")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Resting HR")
                        Spacer()
                        Text("\(Int(restingHeartRate)) bpm")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Measurement") {
                    Toggle("Auto-measure", isOn: $autoMeasureEnabled)

                    if autoMeasureEnabled {
                        HStack {
                            Text("Frequency")
                            Spacer()
                            Text("Every 15 min")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Data") {
                    Button("Export History") {
                        // Export functionality
                    }

                    Button("Reset Baseline", role: .destructive) {
                        // Reset functionality
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

---

## 5. ViewModels Integration

### Enhanced Stress ViewModel
File: `StressMonitor/ViewModels/StressViewModel.swift`

```swift
import Foundation
import Observation
import HealthKit

@Observable
class StressViewModel {
    private let healthKit: HealthKitManager
    private let algorithm: StressAlgorithmServiceProtocol
    private let repository: StressRepositoryProtocol

    var currentStress: StressResult?
    var isLoading = false
    var errorMessage: String?

    init(healthKit: HealthKitManager = .init(),
         algorithm: StressAlgorithmServiceProtocol = StressCalculator(),
         repository: StressRepositoryProtocol) {
        self.healthKit = healthKit
        self.algorithm = algorithm
        self.repository = repository
    }

    func fetchAndCalculate() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch health data
            async let hrv = healthKit.fetchLatestHRV()
            async let heartRate = healthKit.fetchHeartRate(samples: 10)

            let (hrvData, hrData) = try await (hrv, heartRate)

            guard let latestHRV = hrvData,
                  let latestHR = hrData.first else {
                throw HealthError.noData
            }

            // Calculate stress
            let result = try await algorithm.calculateStress(
                hrv: latestHRV.value,
                heartRate: latestHR.value
            )

            currentStress = result

            // Save measurement
            let measurement = StressMeasurement(
                stressLevel: result.level,
                hrv: result.inputs.hrv,
                restingHeartRate: result.inputs.restingHeartRate,
                confidences: [result.confidence]
            )

            try await repository.save(measurement)

        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

enum HealthError: Error {
    case noData
    case unauthorized
}
```

---

## 6. Preview Providers

### Dashboard Preview
File: `StressMonitor/Views/Previews/DashboardView_Previews.swift`

```swift
import SwiftUI

#Preview("Normal") {
    DashboardView()
}

#Preview("High Stress") {
    let viewModel = StressViewModel()
    viewModel.currentStress = StressResult(
        level: 75,
        category: .high,
        confidence: 0.85,
        timestamp: Date(),
        inputs: AlgorithmInputs(hrv: 25, heartRate: 95, restingHeartRate: 60, hrvBaseline: 50)
    )
    return DashboardView()
}
```

---

## Testing Checklist

### Dashboard
- [ ] Stress ring displays correctly
- [ ] Color changes based on level
- [ ] Manual trigger button works
- [ ] Loading state shows
- [ ] Error messages display

### History
- [ ] Measurements appear in list
- [ ] Most recent shows first
- [ ] Empty state displays
- [ ] Tapping rows works (if needed)

### Settings
- [ ] Baseline values display
- [ ] Toggle switches work
- [ ] Navigation works

### Integration
- [ ] Tab navigation smooth
- [ ] Data persists
- [ ] ViewModels update UI

---

## Estimated Time

**4-5 hours**

- Dashboard view: 2 hours
- Stress ring component: 1 hour
- History view: 1 hour
- Settings view: 30 min
- Integration: 30 min

---

## Next Steps

Once this phase is complete, proceed to **Phase 5: watchOS App** to build the Apple Watch companion app.
