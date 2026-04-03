# Planner Agent Memory

## Project: StressMonitor (iOS/watchOS)

### Architecture
- MVVM + Protocol-Oriented Design, SwiftUI, SwiftData, @Observable
- iOS 17+ / watchOS 10+ only
- No external deps except AnimatedTabBar (exyte/SPM)
- PascalCase for Swift files, kebab-case for non-Swift
- Files must stay under 200 LOC

### Key File Locations
- iPhone services: `StressMonitor/StressMonitor/Services/`
- Watch services: `StressMonitor/StressMonitorWatch Watch App/Services/`
- Models: `StressMonitor/StressMonitor/Models/`
- Protocols: `StressMonitor/StressMonitor/Services/Protocols/`
- Tests: `StressMonitor/StressMonitorTests/`
- Mocks: `StressMonitor/StressMonitor/Services/MockServices.swift`

### Code Duplication Pattern
- iPhone and watchOS have SEPARATE copies of: StressCalculator, HealthKitServiceProtocol, StressAlgorithmServiceProtocol, PersonalBaseline, StressResult, HRVMeasurement, HeartRateSample
- watchOS uses `WatchStressMeasurement` (@Observable) instead of `StressMeasurement` (@Model/SwiftData)
- watchOS `WatchHealthKitManager` uses different async pattern (DispatchQueue.main.asyncAfter hack)
- Any algorithm change must be mirrored to BOTH targets

### HealthKit
- Currently reads: `.heartRateVariabilitySDNN`, `.heartRate`
- Apple provides SDNN (not RMSSD) -- this is a known limitation
- HealthKitManager is @MainActor @Observable
- Uses HKSampleQuery with withCheckedThrowingContinuation pattern (iPhone)
- Watch uses less clean async pattern with stored results + delay

### Active Plans
- Multi-Factor Stress Scoring: `plans/0321-2251-multi-factor-stress-scoring/`
  - 5 phases, 24h total effort
  - Factor-based architecture (StressFactor protocol)
  - Sigmoid transforms replace arbitrary pow/atan

### Conventions
- Author name: Phuong Doan
- No AI attribution in commits
- Conventional commit format
- Run compile check after code changes
- Test coverage >80% for core logic
