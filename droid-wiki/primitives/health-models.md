# Health models

Plain value types representing raw HealthKit samples. These are the inputs that flow into `StressContext` and out of `HealthKitManager` async fetch methods.

## Types

| Type | File | Description |
| --- | --- | --- |
| `HRVMeasurement` | `StressMonitor/StressMonitor/Models/HRVMeasurement.swift` | `value` (ms, SDNN) + `timestamp` |
| `HeartRateSample` | `StressMonitor/StressMonitor/Models/HeartRateSample.swift` | `value` (bpm) + `timestamp` |
| `SleepData` | `StressMonitor/StressMonitor/Models/SleepData.swift` | Duration, quality, stages summary |
| `ActivityData` | `StressMonitor/StressMonitor/Models/ActivityData.swift` | Steps, active energy, stand time |
| `RecoveryData` | `StressMonitor/StressMonitor/Models/RecoveryData.swift` | Resting HR, HRV trend, respiratory rate |
| `PersonalBaseline` | `StressMonitor/StressMonitor/Models/PersonalBaseline.swift` | Rolling baseline (covered in [Stress context](stress-context.md)) |

All are small `Codable` `Sendable` structs. The `HealthKitManager` extension files convert raw `HKQuantitySample` / `HKCategorySample` instances into these value types before returning them from async methods.

Each type is intentionally minimal: a value, a timestamp, and a small number of derived fields. They are not persisted directly; instead, their values are folded into `StressMeasurement` fields when a measurement is saved.

The watch app mirrors these types in `StressMonitor/StressMonitorWatch Watch App/Models/` so it can run the algorithm without importing the iOS target.
