# StressMonitor

A SwiftUI-based iOS app for real-time stress monitoring using Apple Watch sensor data.

## Dependencies

- **Axiom** (via MCP): Apple platform development skills for SwiftUI, HealthKit, CoreML patterns
- **HealthKit**: HRV and heart rate data from Apple Watch
- **CoreML**: On-device stress prediction model
- **CloudKit**: Cross-device data sync (via SwiftData + CloudKit integration)
- **Swift Charts**: HRV and stress score trend visualization

## Architecture Decisions

- **MVVM pattern** with `@ObservableObject` view models
- **`@MainActor`** on all view models for thread safety
- **Async/await** for all HealthKit operations
- **Service layer** abstracts HealthKit, CoreML, and CloudKit
- **Observer queries** for real-time HealthKit data updates (wakes app on new data)
- **Anchored queries** for incremental data fetching (avoids re-fetching all data)

## Feature: Real-time Stress Score with HRV Analysis (Welltory-inspired)

### Stress Scoring Pipeline

```
Apple Watch → HealthKit Observer Query → HealthKitManager → StressPredictor → DashboardView
                                              ↓
                                        HRVAnalyzer
                                    ┌─────────┴─────────┐
                                Time Domain         Frequency Domain
                              (RMSSD, SDNN,          (LF/HF ratio,
                               pNN50, meanRR)         power bands)
                                    └─────────┬─────────┘
                                        Composite Score
                                    (0.0 = relaxed, 1.0 = high stress)
```

### HRV Metrics Computed

| Metric | What it measures | Stress indicator |
|--------|-----------------|------------------|
| RMSSD | Parasympathetic tone (successive beat differences) | Lower = more stressed |
| SDNN | Overall HRV variability | Lower = more stressed |
| pNN50 | % of beats with >50ms difference | Lower = more stressed |
| LF/HF Ratio | Sympathovagal balance | Higher = more stressed |
| Coherence | Rhythm regularity | Lower = more stressed |

### Stress Categories (Welltory-style)

| Score Range | Category | Color |
|-------------|----------|-------|
| 0.0 - 0.2 | Resting | Green |
| 0.2 - 0.4 | Low | Blue |
| 0.4 - 0.6 | Moderate | Yellow |
| 0.6 - 0.8 | High | Orange |
| 0.8 - 1.0 | Very High | Red |

## Data Layer

### Models
- `StressReading` — Lightweight Codable struct for UI display
- `StressMeasurement` — SwiftData `@Model` for CloudKit-synced persistence

### CloudKit Sync (CloudKitManager)
Optimized merge strategy to avoid O(n) scans:

| Optimization | Technique |
|---|---|
| O(1) lookup | Compound predicate on (timestamp ± 60s, deviceID) with `fetchLimit = 1` |
| Memory safety | Batch processing via `chunked(into: 100)` with intermediate saves |
| Pagination | `CKQueryOperation` cursor-based pagination for large datasets |
| Baseline cache | TTL-based cache (5 min) for computed stress baselines |

### Schema
- SwiftData `ModelContainer` configured with CloudKit private database
- Fallback to local-only storage when CloudKit unavailable

## Project Structure

```
StressMonitor/
├── Models/
│   ├── StressReading.swift      # Legacy Codable struct
│   └── StressMeasurement.swift  # SwiftData @Model (CloudKit-synced)
├── Services/
│   ├── HealthKitManager.swift   # Real-time HealthKit monitoring (observer + anchored queries)
│   ├── HRVAnalyzer.swift        # HRV analysis engine (time/freq domain, stress scoring)
│   ├── StressPredictor.swift    # Stress scoring with baseline tracking + trend analysis
│   ├── CloudKitManager.swift    # CloudKit sync + merge optimization
│   └── MergeBenchmark.swift     # Performance benchmark utility
├── Views/
│   ├── ContentView.swift        # Tab-based navigation
│   ├── DashboardView.swift      # Main dashboard with stress gauge + charts
│   ├── StressScoreView.swift    # Welltory-inspired circular stress gauge
│   ├── HRVTrendChartView.swift  # Swift Charts HRV trend + stress score charts
│   └── PlaceholderViews.swift   # Placeholder views (History, Settings)
├── StressMonitorApp.swift       # App entry point
└── StressMonitorSchema.swift    # SwiftData + CloudKit config
```

## Setup Requirements

1. **HealthKit capability** must be enabled in Xcode project settings
2. **Info.plist** must include:
   - `NSHealthShareUsageDescription` — for reading HRV/HR data
   - `NSHealthUpdateUsageDescription` — for writing data (if needed)
3. **CloudKit capability** for cross-device sync
4. **Apple Watch** paired for real-time HRV data (iPhone-only uses historical data)
