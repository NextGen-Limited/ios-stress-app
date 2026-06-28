# HealthKit integration

Reads biometric data from Apple Health. All access is read-only (the app never writes samples to HealthKit). `HealthKitManager` wraps callback-based `HKSampleQuery` APIs in async methods and exposes them through `HealthKitServiceProtocol`.

## Key abstractions

| Type | File | Description |
| --- | --- | --- |
| `HealthKitServiceProtocol` | `StressMonitor/StressMonitor/Services/Protocols/HealthKitServiceProtocol.swift` | Async interface for authorization and fetches. |
| `HealthKitManager` | `StressMonitor/StressMonitor/Services/HealthKit/HealthKitManager.swift` | Production implementation. Owns `HKHealthStore`. |
| `SimulatorHealthKitService` | `StressMonitor/StressMonitor/Services/HealthKit/SimulatorHealthKitService.swift` | DEBUG-only mock for demo mode. |
| `MockServices` | `StressMonitor/StressMonitor/Services/MockServices.swift` | Preview and test mocks for the service protocol. |

## What gets read

| Sample type | HK type identifier | Wrapper method |
| --- | --- | --- |
| HRV (SDNN) | `.heartRateVariabilitySDNN` | `fetchLatestHRV()`, `fetchHRVHistory(since:)` |
| Heart rate | `.heartRate` | `fetchHeartRate(samples:)`, `observeHeartRateUpdates()` |
| Resting heart rate | `.restingHeartRate` | fetched in `HealthKitManager+RecoveryFetch.swift` |
| Sleep analysis | `.sleepAnalysis` | `fetchSleepData(for:)` in `HealthKitManager+SleepFetch.swift` |
| Step count | `.stepCount` | `fetchActivityData(for:)` in `HealthKitManager+ActivityFetch.swift` |
| Active energy | `.activeEnergyBurned` | `fetchActivityData(for:)` |
| Apple stand time | `.appleStandTime` | `fetchActivityData(for:)` |
| Respiratory rate | `.respiratoryRate` | fetched in `HealthKitManager+RecoveryFetch.swift` |
| Oxygen saturation | `.oxygenSaturation` | fetched in `HealthKitManager+RecoveryFetch.swift` |
| Workouts | `.workoutType()` | fetched in recovery/activity extensions |

## Authorization

`requestAuthorization()` requests read access for all the above types. No share/write types are requested (the app passes `[] as Set<HKSampleType>` for `toShare`). The first call triggers the system Health permission sheet; subsequent calls are no-ops from the user's perspective but should still be made to ensure the store is ready.

`HealthKitManager` is `@MainActor` because it owns `HKHealthStore` and is observed by `@Observable` ViewModels. The async wrappers use `withCheckedThrowingContinuation` around the callback-based `HKSampleQuery`, and guard against double-resume with a `queryHasReturned` flag.

## Observer query for live heart rate

`observeHeartRateUpdates()` returns an `AsyncStream<HeartRateSample?>` backed by an `HKObserverQuery`. The stream terminates when the caller cancels the task, which stops the query. This powers the live heart-rate display on the dashboard.

## Demo mode

When `-demo-mode` is active in DEBUG builds, `StressViewModel` substitutes `SimulatorHealthKitService` for `HealthKitManager`. The simulator cycles through five stress scenarios (relaxed, mild, moderate, high, edge) every 30 seconds, emits live HR every 3-5 seconds, and generates 7-14 days of historical data with circadian variation. It deliberately omits sleep/activity/recovery in the edge scenario to test weight redistribution.

## Date of birth

`dateOfBirthComponents` reads the user's date of birth from HealthKit to compute chronological age for the bio age estimate. Returns `nil` on the simulator or when the user has not granted access.

## Entry points for modification

- **Add a new HealthKit sample type**: declare the `HKQuantityType`/`HKCategoryType` in `HealthKitManager`, add it to the `readTypes` set in `requestAuthorization()`, and write an async wrapper (either inline or in a new `HealthKitManager+*Fetch.swift` extension).
- **Substitute a mock service in tests or previews**: pass a `HealthKitServiceProtocol`-conforming mock to the `StressViewModel` initializer.
