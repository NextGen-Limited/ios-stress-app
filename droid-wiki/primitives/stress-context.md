# Stress context

The core algorithmic primitives. These types define what goes into the stress calculator and what comes out.

## Types

| Type | File | Description |
| --- | --- | --- |
| `StressContext` | `StressMonitor/StressMonitor/Models/StressContext.swift` | Input bundle: baseline + optional raw biometrics |
| `StressResult` | `StressMonitor/StressMonitor/Models/StressResult.swift` | Output: level (0-100), category, confidence, raw values, breakdown |
| `StressCategory` | `StressMonitor/StressMonitor/Models/StressCategory.swift` | Five-tier enum with color, icon, pattern |
| `FactorBreakdown` | `StressMonitor/StressMonitor/Models/FactorBreakdown.swift` | Per-factor 0-1 component values + data completeness |
| `FactorWeights` | `StressMonitor/StressMonitor/Models/FactorWeights.swift` | Per-factor weight overrides carried by `PersonalBaseline` |
| `PersonalBaseline` | `StressMonitor/StressMonitor/Models/PersonalBaseline.swift` | Rolling HRV baseline, hourly baseline, resting HR |
| `StressSource` | `StressMonitor/StressMonitor/Models/StressCategory.swift` | Named source + percentage + color for the UI |

## StressContext

```swift
struct StressContext: Sendable {
    let baseline: PersonalBaseline
    let timestamp: Date
    let hrv: Double?
    let heartRate: Double?
    let sleepData: SleepData?
    let activityData: ActivityData?
    let recoveryData: RecoveryData?
    let lastReadingDate: Date?
}
```

Every input except `baseline` and `timestamp` is optional. When a factor's input is `nil`, the factor returns `nil` from `calculate(context:)` and the calculator redistributes its weight across the available factors. This is how the algorithm degrades gracefully on devices or users missing certain HealthKit data types.

## StressResult

```swift
struct StressResult: Identifiable, Codable, Sendable {
    let id: UUID
    let level: Double          // 0-100
    let category: StressCategory
    let confidence: Double     // 0-1
    let hrv: Double
    let heartRate: Double
    let timestamp: Date
    let factorBreakdown: FactorBreakdown?
}
```

`factorBreakdown` is `nil` for legacy two-factor measurements taken before the multi-factor migration. The dashboard uses the breakdown to render the "stress sources" card.

`StressResult.category(for:)` is the canonical binning function used everywhere, including in `StressMeasurement.init` when persisting a new record. The thresholds:

- 0..<25: `.relaxed`
- 25..<50: `.mild`
- 50..<75: `.moderate`
- 75..<90: `.high`
- 90...: `.severe`

## StressCategory

`StressCategory` drives dual coding (color + icon + pattern). Its `accessibilityDescription`, `accessibilityHint`, and `accessibilityValue(level:)` produce VoiceOver text. The color mapping returns light/dark variants via `Color(light:dark:)`.

## FactorBreakdown

```swift
struct FactorBreakdown: Codable, Sendable {
    let hrvComponent: Double?
    let hrComponent: Double?
    let sleepComponent: Double?
    let activityComponent: Double?
    let recoveryComponent: Double?
    let dataCompleteness: Double
}
```

Each component is the factor's 0-1 contribution to the composite score (before weighting). `dataCompleteness` is the ratio of available factor weight to total possible weight. The dashboard's `StressSourcesCard` multiplies each component by its default weight to render the percentage bars.

## PersonalBaseline

`PersonalBaseline` is a `Codable` value type persisted to `UserDefaults` under `com.stressmonitor.personalBaseline`. Fields:

- `baselineHRV: Double` - rolling HRV average
- `hourlyHRVBaseline: [Int: Double]` - per-hour baseline for circadian adjustment
- `restingHeartRate: Double`
- `factorWeights: FactorWeights?` - optional per-user weight overrides

`FactorWeights` has five `Double` fields, one per factor, used by `MultiFactorStressCalculator.effectiveWeight(for:)` when present. When `nil`, the calculator falls back to each factor's hardcoded `weight` constant.
