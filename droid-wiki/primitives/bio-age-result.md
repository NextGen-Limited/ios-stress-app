# Bio age result

The output of `BioAgeCalculator`. Represents a biological age estimate derived from HRV, resting heart rate, and recovery signals compared against age-expected baselines.

## Type

```swift
struct BioAgeResult: Codable, Sendable {
    let bioAge: Int            // estimated biological age
    let chronologicalAge: Int  // from HealthKit date of birth
    let delta: Int             // bioAge - chronologicalAge (negative = "younger")
    let confidence: Double     // 0-1
    let hrvContribution: Double
    let hrContribution: Double
    let recoveryContribution: Double
    let inputWindowDays: Int
    let timestamp: Date
}
```

File: `StressMonitor/StressMonitor/Models/BioAgeResult.swift`.

A negative delta means the user's biometrics look younger than their chronological age; a positive delta means older. The confidence reflects how much input data was available and how recent it is.

## Producers and consumers

`BioAgeCalculator` (at `StressMonitor/StressMonitor/Services/Algorithm/BioAgeCalculator.swift`) is the only producer. It runs inside `StressViewModel` and exposes the result through `viewModel.bioAgeResult`, `viewModel.userAge`, and `viewModel.hasSufficientBioAgeData`.

Consumers:

- `BioAgeCardView` on the dashboard (premium-gated).
- `BioAgeDetailView` reachable from the Trends tab (premium-gated via `paywall.present(reason: .bioAgeDetail)`).

## Tests

`StressMonitor/StressMonitorTests/BioAgeCalculatorTests.swift` pins expected outputs for known inputs, including edge cases like insufficient data and extreme HRV values.
